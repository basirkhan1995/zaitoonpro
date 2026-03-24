import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import '../../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../../../../../Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../model/ord_by_id_model.dart';

part 'order_by_id_event.dart';
part 'order_by_id_state.dart';

class OrderByIdBloc extends Bloc<OrderByIdEvent, OrderByIdState> {
  final Repositories repo;

  OrderByIdBloc(this.repo) : super(OrderByIdInitial()) {
    on<LoadOrderByIdEvent>(_onLoadOrderById);
    on<UpdateOrderItemEvent>(_onUpdateItem);
    on<AddOrderItemEvent>(_onAddItem);
    on<RemoveOrderItemEvent>(_onRemoveItem);
    on<SaveOrderChangesEvent>(_onSaveChanges);
    on<ToggleEditModeEvent>(_onToggleEditMode);
    on<DeleteOrderEvent>(_onDeleteOrder);
    on<SelectOrderSupplierEvent>(_onSelectSupplier);
    on<SelectOrderAccountEvent>(_onSelectAccount);
    on<ClearOrderAccountEvent>(_onClearAccount);
    on<UpdateOrderPaymentEvent>(_onUpdatePayment);
    on<UpdateSaleOrderItemEvent>(_onUpdateSaleItem);

  }

  void _onUpdateSaleItem(UpdateSaleOrderItemEvent event, Emitter<OrderByIdState> emit,) {
    if (state is! OrderByIdLoaded) return;

    final current = state as OrderByIdLoaded;
    if (!current.isEditing) return;

    final currentRecords = current.order.records ?? [];

    if (event.index < 0 || event.index >= currentRecords.length) {
      return;
    }

    final records = List<OrderRecords>.from(currentRecords);
    final record = records[event.index];

    // Handle quantity
    String? quantityString = record.stkQuantity;
    if (event.quantity != null) {
      quantityString = event.quantity!.toStringAsFixed(3);
    }

    final updatedRecord = record.copyWith(
      stkProduct: event.productId,
      stkQuantity: quantityString,
      stkPurPrice: event.purchasePrice.toStringAsFixed(4),
      stkSalePrice: event.salePrice.toStringAsFixed(4),
      stkStorage: event.storageId ?? record.stkStorage,
    );

    records[event.index] = updatedRecord;

    // Update product names
    Map<int, String> updatedProductNames = Map.from(current.productNames);
    updatedProductNames[event.productId] = event.productName;

    final updatedOrder = current.order.copyWith(records: records);

    emit(current.copyWith(
      order: updatedOrder,
      productNames: updatedProductNames,
    ));
  }



  Future<void> _onLoadOrderById(LoadOrderByIdEvent event, Emitter<OrderByIdState> emit,) async {
    emit(OrderByIdLoading());

    try {
      final orders = await repo.getOrderById(orderId: event.orderId);

      if (orders.isEmpty) {
        emit(OrderByIdError('Order not found'));
        return;
      }

      final order = orders.first;

      // Determine order type
      final isPurchase = order.ordName?.toLowerCase().contains('purchase') ?? true;

      // Load storages
      final storages = await repo.getStorage();

      // Load ALL products initially
      final allProducts = await repo.getProduct();
      final productNames = <int, String>{};
      for (var product in allProducts) {
        if (product.proId != null && product.proName != null) {
          productNames[product.proId!] = product.proName!;
        }
      }

      final storageNames = <int, String>{};
      final records = order.records ?? [];

      // For sale orders, load product stock to get purchase prices
      if (!isPurchase) {
        try {
          // Load product stock data to get purchase prices
          final productsStock = await repo.getProductStock(); // You need to add this method to your repository

          // Create a map of productId -> purchase price
          final productPurchasePrices = <int, double>{};
          for (var stock in productsStock) {
            if (stock.proId != null && stock.averagePrice != null) {
              // Remove thousand separators and parse
              final cleanPrice = stock.averagePrice!.replaceAll(',', '');
              final price = double.tryParse(cleanPrice) ?? 0.0;
              if (price > 0) {
                productPurchasePrices[stock.proId!] = price;
              }
            }
          }

          // Update records with purchase prices if missing
          for (var i = 0; i < records.length; i++) {
            final record = records[i];
            if (record.stkProduct != null && record.stkProduct! > 0) {
              final purchasePrice = productPurchasePrices[record.stkProduct!];

              // Check if purchase price is missing or zero
              final currentPurPrice = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
              if ((currentPurPrice == 0 || record.stkPurPrice == null || record.stkPurPrice!.isEmpty)
                  && purchasePrice != null && purchasePrice > 0) {
                // Update the record with purchase price
                final updatedRecord = record.copyWith(
                  stkPurPrice: purchasePrice.toStringAsFixed(4),
                );
                records[i] = updatedRecord;
              }
            }
          }
        } catch (e) {
          // Continue without purchase prices - they may be loaded later when editing
        }
      }

      for (final record in records) {
        // Update product name from pre-loaded list
        if (record.stkProduct != null) {
          if (!productNames.containsKey(record.stkProduct)) {
            // If not in pre-loaded list, try to load it
            try {
              final products = await repo.getProduct(proId: record.stkProduct!);
              if (products.isNotEmpty) {
                productNames[record.stkProduct!] = products.first.proName ?? 'Unknown';
              } else {
                productNames[record.stkProduct!] = 'Unknown';
              }
            } catch (_) {
              productNames[record.stkProduct!] = 'Unknown';
            }
          }

          // Load storage name
          if (record.stkStorage != null && !storageNames.containsKey(record.stkStorage)) {
            final storage = storages.firstWhere(
                  (s) => s.stgId == record.stkStorage,
              orElse: () => StorageModel(stgId: 0, stgName: 'Unknown'),
            );
            storageNames[record.stkStorage!] = storage.stgName ?? 'Unknown';
          }
        }
      }

      // Calculate grand total from items
      double grandTotal = 0.0;

      for (final record in records) {
        final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
        double price;

        if (isPurchase) {
          price = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        } else {
          price = double.tryParse(record.stkSalePrice ?? "0") ?? 0;
        }

        grandTotal += qty * price;
      }

      // Get credit amount from API
      final creditAmount = double.tryParse(order.amount ?? "0.0") ?? 0.0;
      final hasAccount = order.acc != null && order.acc! > 0;

      // Calculate cash payment
      double cashPayment = grandTotal - creditAmount;

      // Validate: credit amount should not exceed grand total
      if (creditAmount > grandTotal) {
        cashPayment = 0.0;
        // Or you can adjust creditAmount = grandTotal;
      }

      // Determine initial supplier
      IndividualsModel? selectedSupplier;
      if (order.perId != null && order.personal != null) {
        selectedSupplier = IndividualsModel(
          perId: order.perId,
          perName: order.personal,
        );
      }

      emit(OrderByIdLoaded(
        order: order.copyWith(records: records), // Use updated records
        storages: storages,
        productNames: productNames,
        storageNames: storageNames,
        isEditing: false,
        selectedSupplier: selectedSupplier,
        selectedAccount: hasAccount && creditAmount > 0
            ? AccountsModel(accNumber: order.acc)
            : null,
        cashPayment: cashPayment,
        creditAmount: creditAmount,
      ));
    } catch (e) {
      emit(OrderByIdError(e.toString()));
    }
  }
  void _onToggleEditMode(ToggleEditModeEvent event, Emitter<OrderByIdState> emit) {
    if (state is OrderByIdLoaded) {
      final current = state as OrderByIdLoaded;
      emit(current.copyWith(isEditing: !current.isEditing));
    }
  }

  void _onSelectSupplier(SelectOrderSupplierEvent event, Emitter<OrderByIdState> emit,) {
    if (state is OrderByIdLoaded) {
      final current = state as OrderByIdLoaded;
      emit(current.copyWith(selectedSupplier: event.supplier));
    }
  }

  void _onSelectAccount(SelectOrderAccountEvent event, Emitter<OrderByIdState> emit) {
    if (state is OrderByIdLoaded) {
      final current = state as OrderByIdLoaded;
      emit(current.copyWith(selectedAccount: event.account));
    }
  }

  void _onClearAccount(ClearOrderAccountEvent event, Emitter<OrderByIdState> emit,) {
    if (state is OrderByIdLoaded) {
      final current = state as OrderByIdLoaded;
      emit(current.copyWith(
        selectedAccount: null,
        cashPayment: current.grandTotal,
        creditAmount: 0.0,
      ));
    }
  }

  void _onUpdatePayment(UpdateOrderPaymentEvent event, Emitter<OrderByIdState> emit,) {
    if (state is OrderByIdLoaded) {
      final current = state as OrderByIdLoaded;

      double cashPayment = event.cashPayment;
      double creditAmount = event.creditAmount;

      // Validate that payments match grand total
      final total = cashPayment + creditAmount;
      if ((total - current.grandTotal).abs() > 0.01) {
        emit(OrderByIdError('TotalDailyTxn payment must equal grand total'));
        return;
      }

      // Validate credit amount
      if (creditAmount > current.grandTotal) {
        emit(OrderByIdError('Credit amount cannot exceed grand total'));
        return;
      }

      // Validate cash amount
      if (cashPayment < 0) {
        emit(OrderByIdError('Cash payment cannot be negative'));
        return;
      }

      // Auto-adjust if needed
      if (cashPayment > current.grandTotal) {
        cashPayment = current.grandTotal;
        creditAmount = 0.0;
      } else if (creditAmount > current.grandTotal) {
        creditAmount = current.grandTotal;
        cashPayment = 0.0;
      }

      // Clear account if no credit
      AccountsModel? selectedAccount = current.selectedAccount;
      if (creditAmount <= 0) {
        selectedAccount = null;
      }

      emit(current.copyWith(
        cashPayment: cashPayment,
        creditAmount: creditAmount,
        selectedAccount: selectedAccount,
      ));
    }
  }

  void _onUpdateItem(UpdateOrderItemEvent event, Emitter<OrderByIdState> emit,) {
    if (state is! OrderByIdLoaded) return;

    final current = state as OrderByIdLoaded;
    if (!current.isEditing) return;

    final currentRecords = current.order.records ?? [];

    if (event.index < 0 || event.index >= currentRecords.length) {
      return;
    }

    final records = List<OrderRecords>.from(currentRecords);
    final record = records[event.index];

    // Determine order type
    final isPurchase = current.order.ordName?.toLowerCase().contains('purchase') ?? true;
    final isSale = current.order.ordName?.toLowerCase().contains('sale') ?? false;

    // Handle quantity with 3 decimal places
    String? quantityString;
    if (event.quantity != null) {
      quantityString = event.quantity!.toStringAsFixed(3);
    } else {
      quantityString = record.stkQuantity;
    }

    // Handle prices
    String? purPriceString = record.stkPurPrice;
    String? salePriceString = record.stkSalePrice;

    // Update product ID if provided
    int? productId = event.productId ?? record.stkProduct;

    // When a product is selected (productId > 0) but no price is provided
    if (event.productId != null && event.productId! > 0 && event.price == null) {
      // This is just a product selection, keep existing prices
      // or set default prices based on order type
      if (isPurchase) {
        // For purchase orders, keep existing purchase price or set to 0 if not set
        if (purPriceString == null || purPriceString.isEmpty || double.tryParse(purPriceString) == 0) {
          purPriceString = "0.0000";
        }
        salePriceString = "0.0000";
      } else if (isSale) {
        // For sale orders, keep existing sale price or set to 0 if not set
        if (salePriceString == null || salePriceString.isEmpty || double.tryParse(salePriceString) == 0) {
          salePriceString = "0.0000";
        }
        // Keep existing purchase price or set to 0
        if (purPriceString == null || purPriceString.isEmpty || double.tryParse(purPriceString) == 0) {
          purPriceString = "0.0000";
        }
      }
    }

    if (event.price != null) {
      if (isPurchase) {
        // For purchase orders, only update purchase price
        purPriceString = event.price!.toStringAsFixed(4);
        salePriceString = "0.0000";
      } else if (isSale) {
        // For sale orders, check which price to update
        if (event.isPurchasePrice) {
          // This is the purchase price update
          purPriceString = event.price!.toStringAsFixed(4);
        } else {
          // This is the sale price update (default behavior)
          salePriceString = event.price!.toStringAsFixed(4);
        }
      }
    }

    // Handle product name update
    Map<int, String> updatedProductNames = Map.from(current.productNames);
    if (event.productId != null && event.productId! > 0 && event.productName != null) {
      updatedProductNames[event.productId!] = event.productName!;
    }

    final updatedRecord = record.copyWith(
      stkProduct: productId,
      stkQuantity: quantityString,
      stkPurPrice: purPriceString,
      stkSalePrice: salePriceString,
      stkStorage: event.storageId ?? record.stkStorage,
    );

    records[event.index] = updatedRecord;

    final updatedOrder = current.order.copyWith(records: records);

    emit(current.copyWith(
      order: updatedOrder,
      productNames: updatedProductNames,
    ));
  }

  void _onAddItem(AddOrderItemEvent event, Emitter<OrderByIdState> emit) {
    if (state is! OrderByIdLoaded) return;

    final current = state as OrderByIdLoaded;
    if (!current.isEditing) return;

    // Determine if it's purchase or sale
    final isPurchase = current.order.ordName?.toLowerCase().contains('purchase') ?? true;
    final isSale = current.order.ordName?.toLowerCase().contains('sale') ?? false;

    // Get default storage ID
    int defaultStorageId = 0;
    if (current.storages.isNotEmpty) {
      defaultStorageId = current.storages.first.stgId ?? 0;
    }

    final newRecord = OrderRecords(
      stkId: 0, // New item
      stkOrder: current.order.ordId,
      stkProduct: 0, // Set to 0 initially
      stkEntryType: isPurchase ? "IN" : (isSale ? "OUT" : "IN"),
      stkStorage: defaultStorageId,
      stkQuantity: "1.000",
      // Set appropriate default prices based on order type
      stkPurPrice: isPurchase ? "0.0000" : "0.0000", // For sale, this might be fetched later
      stkSalePrice: isSale ? "0.0000" : "0.0000",
    );

    final currentRecords = current.order.records ?? [];
    final records = List<OrderRecords>.from(currentRecords)..add(newRecord);

    final updatedOrder = current.order.copyWith(records: records);

    emit(current.copyWith(order: updatedOrder));
  }

  void _onRemoveItem(RemoveOrderItemEvent event, Emitter<OrderByIdState> emit,) {
    if (state is! OrderByIdLoaded) return;

    final current = state as OrderByIdLoaded;
    if (!current.isEditing) return;

    final currentRecords = current.order.records ?? [];

    if (event.index < 0 || event.index >= currentRecords.length) {
      return;
    }

    final records = List<OrderRecords>.from(currentRecords);
    records.removeAt(event.index);

    // Ensure at least one item remains
    if (records.isEmpty) {
      // Determine if it's purchase or sale
      final isPurchase = current.order.ordName?.toLowerCase().contains('purchase') ?? true;
      final isSale = current.order.ordName?.toLowerCase().contains('sale') ?? false;

      // Get default storage ID
      int defaultStorageId = 0;
      if (current.storages.isNotEmpty) {
        defaultStorageId = current.storages.first.stgId ?? 0;
      }

      records.add(OrderRecords(
        stkId: 0,
        stkOrder: current.order.ordId,
        stkProduct: 0,
        stkEntryType: isPurchase ? "IN" : (isSale ? "OUT" : "IN"),
        stkStorage: defaultStorageId,
        stkQuantity: "1.000",
        stkPurPrice: "0.0000",
        stkSalePrice: "0.0000",
      ));
    }

    final updatedOrder = current.order.copyWith(records: records);

    emit(current.copyWith(order: updatedOrder));
  }

  Future<void> _onSaveChanges(SaveOrderChangesEvent event, Emitter<OrderByIdState> emit) async {
    if (state is! OrderByIdLoaded) {
      event.completer.complete(false);
      return;
    }

    final current = state as OrderByIdLoaded;
    final savedState = current.copyWith();
    final records = current.order.records ?? [];

    // Validate items
    if (records.isEmpty) {
      emit(OrderByIdError('Please add at least one item'));
      emit(savedState);
      event.completer.complete(false);
      return;
    }

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.stkProduct == 0) {
        emit(OrderByIdError('Please select a product for item ${i + 1}'));
        emit(savedState);
        event.completer.complete(false);
        return;
      }
      if (record.stkStorage == 0) {
        emit(OrderByIdError('Please select a storage for item ${i + 1}'));
        emit(savedState);
        event.completer.complete(false);
        return;
      }

      // Validate quantity
      final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
      if (qty <= 0) {
        emit(OrderByIdError('Please enter a valid quantity for item ${i + 1}'));
        emit(savedState);
        event.completer.complete(false);
        return;
      }

      // Validate price
      final isPurchase = current.order.ordName?.toLowerCase().contains('purchase') ?? true;
      final isSale = current.order.ordName?.toLowerCase().contains('sale') ?? false;

      if (isPurchase) {
        final price = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        if (price <= 0) {
          emit(OrderByIdError('Please enter a valid price for item ${i + 1}'));
          emit(savedState);
          event.completer.complete(false);
          return;
        }
      } else if (isSale) {
        // For sale orders, we need both sale price (mandatory) and purchase price (for profit calculation)
        final salePrice = double.tryParse(record.stkSalePrice ?? "0") ?? 0;
        if (salePrice <= 0) {
          emit(OrderByIdError('Please enter a valid sale price for item ${i + 1}'));
          emit(savedState);
          event.completer.complete(false);
          return;
        }

        // For sale orders, we should also get the purchase price from product stock
        // This should already be populated from the product selection
        final purPrice = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        if (purPrice <= 0) {
          emit(OrderByIdError('Purchase price not found for item ${i + 1}. Please reselect the product.'));
          emit(savedState);
          event.completer.complete(false);
          return;
        }
      }
    }

    // Validate payment
    if (!current.isPaymentValid) {
      emit(OrderByIdError('TotalDailyTxn payment must equal grand total. Please adjust payment.'));
      emit(savedState);
      event.completer.complete(false);
      return;
    }

    // Validate account for credit/mixed payment
    if (current.creditAmount > 0 && current.selectedAccount == null) {
      emit(OrderByIdError('Please select an account for credit payment'));
      emit(savedState);
      event.completer.complete(false);
      return;
    }

    emit(OrderByIdSaving(current.order));

    try {
      // Determine order type
      final isPurchase = current.order.ordName?.toLowerCase().contains('purchase') ?? true;

      // Convert records to update format
      final updateRecords = records.map((record) {
        final quantity = double.tryParse(record.stkQuantity ?? "0") ?? 0;
        final purPrice = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        final salePrice = double.tryParse(record.stkSalePrice ?? "0") ?? 0;

        return {
          "stkID": record.stkId ?? 0, // 0 for new items
          "stkOrder": record.stkOrder ?? current.order.ordId,
          "stkProduct": record.stkProduct,
          "stkEntryType": record.stkEntryType ?? (isPurchase ? "IN" : "OUT"),
          "stkStorage": record.stkStorage,
          "stkQuantity": quantity.toStringAsFixed(3),
          "stkPurPrice": purPrice.toStringAsFixed(4),
          "stkSalePrice": salePrice.toStringAsFixed(4),
        };
      }).toList();

      // Prepare account info - API expects:
      // - For cash: account = 0, amount = 0.0
      // - For credit: account = accountNumber, amount = creditAmount (full amount)
      // - For mixed: account = accountNumber, amount = creditAmount (partial)
      int? accountNumber = 0; // Default to cash
      double amountToSend = 0.0;

      if (current.creditAmount > 0) {
        // Credit or mixed payment
        accountNumber = current.selectedAccount!.accNumber;
        amountToSend = current.creditAmount;
      }

      // Prepare the update payload according to API
      final payload = {
        "usrName": event.usrName,
        "ordID": current.order.ordId,
        "ordName": current.order.ordName,
        "ordPersonal": current.selectedSupplier?.perId ?? current.order.perId,
        "ordPersonalName": current.selectedSupplier?.perName ?? current.order.personal,
        "ordxRef": current.order.ordxRef,
        "ordTrnRef": current.order.ordTrnRef,
        "account": accountNumber,
        "amount": amountToSend.toStringAsFixed(4), // Only credit amount goes here
        "trnStateText": current.order.trnStateText,
        "ordEntryDate": current.order.ordEntryDate?.toIso8601String(),
        "records": updateRecords,
      };

      final success = await repo.updatePurchaseOrder(
        orderId: current.order.ordId!,
        usrName: event.usrName,
        records: updateRecords,
        orderData: payload,
      );

      if (success) {
        emit(OrderByIdSaved(true, message: 'Order updated successfully'));
        // Turn off edit mode and reload
        emit(current.copyWith(isEditing: false));
        add(LoadOrderByIdEvent(current.order.ordId!));
      } else {
        emit(OrderByIdError('Failed to update order'));
        emit(savedState);
      }

      event.completer.complete(success);
    } catch (e) {
      emit(OrderByIdError(e.toString()));
      emit(savedState);
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteOrder(DeleteOrderEvent event, Emitter<OrderByIdState> emit) async {
    try {
      if (state is! OrderByIdLoaded) return;

      final current = state as OrderByIdLoaded;
      final savedState = current.copyWith();

      emit(OrderByIdDeleting(current.order));

      final success = await repo.deleteOrder(
        orderId: event.orderId,
        usrName: event.usrName,
        ref: event.ref,
        ordName: event.orderName,
      );

      if (success) {
        emit(OrderByIdDeleted(true, message: 'Order deleted successfully'));
      } else {
        emit(OrderByIdError('Failed to delete order. The order transaction may be verified.'));
        emit(savedState);
      }
    } catch (e) {
      if (e.toString().contains('Authorized')) {
        emit(OrderByIdError('Cannot delete order: The transaction is verified and cannot be deleted.'));
      } else {
        emit(OrderByIdError(e.toString()));
      }

      if (state is OrderByIdLoaded) {
        final current = state as OrderByIdLoaded;
        emit(current);
      }
    }
  }
}