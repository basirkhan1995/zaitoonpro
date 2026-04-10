import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../../Services/repositories.dart';
import '../../../../../Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import '../../../../../Settings/Ui/Company/Storage/model/storage_model.dart';
import '../../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../model/purchase_invoice_items.dart';

part 'purchase_invoice_event.dart';
part 'purchase_invoice_state.dart';

class PurchaseInvoiceBloc extends Bloc<PurchaseInvoiceEvent, PurchaseInvoiceState> {
  final Repositories repo;
  late final ExchangeRateBloc _exchangeRateBloc;
  StreamSubscription? _exchangeRateSubscription;

  PurchaseInvoiceBloc(this.repo) : super(PurchaseInvoiceInitial()) {
    on<InitializePurchaseInvoiceEvent>(_onInitialize);
    on<SelectSupplierEvent>(_onSelectSupplier);
    on<SelectSupplierAccountEvent>(_onSelectSupplierAccount);
    on<ClearSupplierEvent>(_onClearSupplier);
    on<AddNewPurchaseItemEvent>(_onAddNewItem);
    on<RemovePurchaseItemEvent>(_onRemoveItem);
    on<UpdatePurchaseItemEvent>(_onUpdateItem);
    on<UpdatePurchasePaymentEvent>(_onUpdatePayment);
    on<ResetPurchaseInvoiceEvent>(_onReset);
    on<SavePurchaseInvoiceEvent>(_onSaveInvoice);
    on<LoadPurchaseStoragesEvent>(_onLoadStorages);
    on<ClearSupplierAccountEvent>(_onClearSupplierAccount);

    // New expense handlers
    on<AddExpenseEvent>(_onAddExpense);
    on<RemoveExpenseEvent>(_onRemoveExpense);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<UpdateAllLandedPricesEvent>(_onUpdateAllLandedPrices);

    on<UpdateExchangeRateForInvoiceEvent>(_onUpdateExchangeRate);
    on<UpdateItemLocalAmountEvent>(_onUpdateItemLocalAmount);
    on<UpdateAllLocalAmountsEvent>(_onUpdateAllLocalAmounts);
    on<UpdateExchangeRateManuallyEvent>(_onUpdateExchangeRateManually);
  }
  void _onUpdateExchangeRateManually(
      UpdateExchangeRateManuallyEvent event,
      Emitter<PurchaseInvoiceState> emit,
      ) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      emit(current.copyWith(
        exchangeRate: event.rate,
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
      ));

      // Update all local amounts
      add(UpdateAllLocalAmountsEvent());
    }
  }

  void setExchangeRateBloc(ExchangeRateBloc exchangeRateBloc) {
    _exchangeRateBloc = exchangeRateBloc;
    _exchangeRateSubscription = _exchangeRateBloc.stream.listen((state) {
      if (state is ExchangeRateLoadedState && this.state is PurchaseInvoiceLoaded) {
        // Update local amounts when exchange rate changes
        add(UpdateAllLocalAmountsEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _exchangeRateSubscription?.cancel();
    return super.close();
  }

  // Add this to your PurchaseInvoiceBloc class

  void _onUpdateItem(UpdatePurchaseItemEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final updatedItems = current.items.map((item) {
        if (item.rowId == event.rowId) {
          final updatedItem = PurchaseInvoiceItem(
            itemId: item.rowId,
            stkBatch: event.batch?.toInt() ?? item.stkBatch,
            sellPriceAmount: event.sellPriceAmount ?? item.sellPriceAmount,
            productId: event.productId ?? item.productId,
            productName: event.productName ?? item.productName,
            qty: event.qty ?? item.qty,
            purPrice: event.purPrice ?? item.purPrice,
            storageName: event.storageName ?? item.storageName,
            storageId: event.storageId ?? item.storageId,
          );

          // Calculate local amount immediately if exchange rate exists
          if (current.exchangeRate != null && current.exchangeRate! > 0) {
            final localAmount = updatedItem.totalPurchase * current.exchangeRate!;
            return updatedItem.copyWith(localAmount: localAmount);
          }
          return updatedItem;
        }
        return item;
      }).toList();

      emit(current.copyWith(items: updatedItems));
    }
  }

  void _onUpdateAllLocalAmounts(
      UpdateAllLocalAmountsEvent event,
      Emitter<PurchaseInvoiceState> emit,
      ) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      // Only calculate if we have an exchange rate
      if (current.exchangeRate == null || current.exchangeRate == 0) {
        emit(current);
        return;
      }

      final updatedItems = current.items.map((item) {
        final localAmount = item.totalPurchase * current.exchangeRate!;
        return item.copyWith(localAmount: localAmount);
      }).toList();

      emit(current.copyWith(items: updatedItems));
    }
  }

  Future<void> _onUpdateExchangeRate(
      UpdateExchangeRateForInvoiceEvent event,
      Emitter<PurchaseInvoiceState> emit,
      ) async {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      try {
        // Fetch exchange rate from API
        final rate = await repo.getSingleRate(
          fromCcy: event.fromCurrency,
          toCcy: event.toCurrency,
        );

        emit(current.copyWith(
          exchangeRate: double.tryParse(rate??"0.00"),
          fromCurrency: event.fromCurrency,
          toCurrency: event.toCurrency,
        ));

        // Update all local amounts
        add(UpdateAllLocalAmountsEvent());
      } catch (e) {
        emit(PurchaseInvoiceError('Failed to fetch exchange rate: $e'));
        emit(current);
      }
    }
  }

  void _onUpdateItemLocalAmount(
      UpdateItemLocalAmountEvent event,
      Emitter<PurchaseInvoiceState> emit,
      ) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final updatedItems = current.items.map((item) {
        if (item.rowId == event.rowId) {
          // Calculate local amount using exchange rate
          final localAmount = (item.totalPurchase) * (current.exchangeRate ?? 1);
          return item.copyWith(localAmount: localAmount);
        }
        return item;
      }).toList();

      emit(current.copyWith(items: updatedItems));
    }
  }


  void _onAddExpense(AddExpenseEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final newExpense = PurExpenseRecord(
        narration: '',
        account: 0,
        amount: 0.0,
        accountName: '',
      );

      final updatedExpenses = List<PurExpenseRecord>.from(current.expenses)..add(newExpense);
      emit(current.copyWith(expenses: updatedExpenses));

      // ✅ This is already correct - it triggers recalculation
      add(UpdateAllLandedPricesEvent());
    }
  }

  void _onRemoveExpense(RemoveExpenseEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final updatedExpenses = current.expenses
          .where((expense) => expense.rowId != event.rowId)
          .toList();

      emit(current.copyWith(expenses: updatedExpenses));

      // ✅ This triggers recalculation after removal
      add(UpdateAllLandedPricesEvent());
    }
  }
  void _onUpdateExpense(UpdateExpenseEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final updatedExpenses = current.expenses.map((expense) {
        if (expense.rowId == event.rowId) {
          return expense.copyWith(
            narration: event.narration ?? expense.narration,
            account: event.account ?? expense.account,
            amount: event.amount ?? expense.amount,
            accountName: event.accountName ?? expense.accountName,
          );
        }
        return expense;
      }).toList();

      emit(current.copyWith(expenses: updatedExpenses));

      // ✅ THIS WAS MISSING - Now triggers recalculation
      add(UpdateAllLandedPricesEvent());
    }
  }
  void _onUpdateAllLandedPrices(UpdateAllLandedPricesEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      // Calculate total expenses
      final totalExpenses = current.expenses.fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate grand total purchase value (sum of all items' total purchase)
      final grandTotal = current.items.fold(0.0, (sum, item) => sum + item.totalPurchase);

      // Update each item's landed price for DISPLAY only
      final updatedItems = current.items.map((item) {
        double landedPriceForDisplay = item.purPrice ?? 0.0;

        if (grandTotal > 0 && totalExpenses > 0) {
          // Allocate expense proportionally based on purchase value
          final allocationRatio = item.totalPurchase / grandTotal;
          final allocatedExpense = totalExpenses * allocationRatio;
          landedPriceForDisplay = (item.purPrice ?? 0.0) + (allocatedExpense / item.qty);
        }

        return PurchaseInvoiceItem(
          itemId: item.rowId,
          productId: item.productId,
          productName: item.productName,
          qty: item.qty,
          stkBatch: item.stkBatch,
          purPrice: item.purPrice,  // Keep original price
          landedPrice: landedPriceForDisplay,  // Update display price
          sellPriceAmount: item.sellPriceAmount,
          storageName: item.storageName,
          storageId: item.storageId,
        );
      }).toList();

      emit(current.copyWith(items: updatedItems));
    }
  }

  void _onInitialize(InitializePurchaseInvoiceEvent event, Emitter<PurchaseInvoiceState> emit) {
    emit(PurchaseInvoiceLoaded(
      expenses: [],  // ← Start with empty list instead of one empty row
      items: [PurchaseInvoiceItem(
        productId: '',
        productName: '',
        qty: 1,
        stkBatch: 0,
        sellPriceAmount: 0,
        purPrice: 0,
        landedPrice: 0,
        storageName: '',
        storageId: 0,
      )],
      payment: 0.0,
      paymentMode: PaymentMode.cash,
    ));
  }

  void _onReset(ResetPurchaseInvoiceEvent event, Emitter<PurchaseInvoiceState> emit) {
    emit(PurchaseInvoiceLoaded(
      expenses: [],  // ← Start with empty list
      items: [PurchaseInvoiceItem(
        productId: '',
        productName: '',
        qty: 1,
        stkBatch: 0,
        purPrice: 0,
        landedPrice: 0,
        storageName: '',
        sellPriceAmount: 0,
        storageId: 0,
      )],
      payment: 0.0,
      paymentMode: PaymentMode.cash,
    ));
  }
  void _onClearSupplierAccount(ClearSupplierAccountEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      emit(current.copyWith(
        supplierAccount: null,
        payment: current.grandTotal,
        paymentMode: PaymentMode.cash,
      ));
    }
  }

  void _onSelectSupplierAccount(SelectSupplierAccountEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      PaymentMode newPaymentMode;

      if (current.payment == 0) {
        newPaymentMode = PaymentMode.credit;
      } else if (current.payment >= current.grandTotal) {
        newPaymentMode = PaymentMode.cash;
      } else if (current.payment > 0 && current.payment < current.grandTotal) {
        newPaymentMode = PaymentMode.mixed;
      } else {
        newPaymentMode = PaymentMode.credit;
      }

      emit(current.copyWith(
        supplierAccount: event.supplier,
        paymentMode: newPaymentMode,
      ));
    }
  }

  void _onSelectSupplier(SelectSupplierEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      emit(current.copyWith(supplier: event.supplier));
    }
  }

  void _onClearSupplier(ClearSupplierEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      emit(current.copyWith(
        supplier: null,
        supplierAccount: null,
        payment: current.grandTotal, // Reset payment to full amount
        paymentMode: PaymentMode.cash, // Reset to cash mode
      ));
    }
  }

  void _onAddNewItem(AddNewPurchaseItemEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is! PurchaseInvoiceLoaded) return;
    final current = state as PurchaseInvoiceLoaded;

    final newItem = PurchaseInvoiceItem(
      productId: '',
      productName: '',
      qty: 1,
      sellPriceAmount: 0,
      purPrice: 0,
      stkBatch: 0,
      storageName: '',
      storageId: 0,
    );

    final updatedItems = List<PurchaseInvoiceItem>.from(current.items)..add(newItem);
    emit(current.copyWith(items: updatedItems));
  }

  void _onRemoveItem(RemovePurchaseItemEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final updatedItems = current.items.where((item) => item.rowId != event.rowId).toList();

      if (updatedItems.isEmpty) {
        updatedItems.add(PurchaseInvoiceItem(
          productId: '',
          productName: '',
          stkBatch: 0,
          sellPriceAmount: 0,
          qty: 1,
          purPrice: 0,
          storageName: '',
          storageId: 0,
        ));
      }

      emit(current.copyWith(items: updatedItems));
    }
  }

  void _onUpdatePayment(UpdatePurchasePaymentEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      double cashPayment;
      double creditAmount;
      PaymentMode newPaymentMode;

      if (event.isCreditAmount) {
        // When setting credit amount (from mixed payment)
        creditAmount = event.payment;
        cashPayment = current.grandTotal - creditAmount;

        if (creditAmount <= 0) {
          newPaymentMode = PaymentMode.cash;
          cashPayment = current.grandTotal;
          creditAmount = 0;
        } else if (creditAmount >= current.grandTotal) {
          newPaymentMode = PaymentMode.credit;
          cashPayment = 0;
          creditAmount = current.grandTotal;
        } else {
          newPaymentMode = PaymentMode.mixed;
        }
      } else {
        // When setting cash payment
        cashPayment = event.payment;
        creditAmount = current.grandTotal - cashPayment;

        if (cashPayment == 0) {
          newPaymentMode = PaymentMode.credit;
          creditAmount = current.grandTotal;
          cashPayment = 0;
          // Don't clear account here - account is required for credit
        } else if (cashPayment >= current.grandTotal) {
          newPaymentMode = PaymentMode.cash;
          cashPayment = current.grandTotal;
          creditAmount = 0;
          // Clear account when switching to full cash
        } else {
          newPaymentMode = PaymentMode.mixed;
          // Account should still be selected for mixed
        }
      }

      emit(current.copyWith(
        payment: cashPayment,
        paymentMode: newPaymentMode,
        // Clear supplierAccount only when switching to full cash
        supplierAccount: newPaymentMode == PaymentMode.cash ? null : current.supplierAccount,
      ));
    }
  }


  Future<void> _onSaveInvoice(SavePurchaseInvoiceEvent event, Emitter<PurchaseInvoiceState> emit) async {
    if (state is! PurchaseInvoiceLoaded) {
      event.completer.complete('');
      return;
    }

    final current = state as PurchaseInvoiceLoaded;
    final savedState = current.copyWith();



    // Validation
    if (current.supplier == null) {
      emit(PurchaseInvoiceError('Please select a supplier'));
      emit(savedState);
      event.completer.complete('');
      return;
    }

    if (current.items.isEmpty) {
      emit(PurchaseInvoiceError('Please add at least one item'));
      emit(savedState);
      event.completer.complete('');
      return;
    }

    for (var i = 0; i < current.items.length; i++) {
      final item = current.items[i];
      if (item.productId.isEmpty) {
        emit(PurchaseInvoiceError('Please select a product for item ${i + 1}'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.storageId == 0) {
        emit(PurchaseInvoiceError('Please select a storage for item ${i + 1}'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.purPrice == null || item.purPrice! <= 0) {
        emit(PurchaseInvoiceError('Please enter a valid price for item ${i + 1}'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.qty <= 0) {
        emit(PurchaseInvoiceError('Please enter a valid quantity for item ${i + 1}'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    if (current.paymentMode == PaymentMode.credit || current.paymentMode == PaymentMode.mixed) {
      if (current.supplierAccount == null) {
        emit(PurchaseInvoiceError('Please select a supplier account for credit payment'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    if (current.paymentMode == PaymentMode.mixed) {
      if (current.payment <= 0) {
        emit(PurchaseInvoiceError('For mixed payment, cash payment must be greater than 0'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (current.payment >= current.grandTotal) {
        emit(PurchaseInvoiceError('For mixed payment, cash payment must be less than total amount'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    // Emit saving state
    emit(PurchaseInvoiceSaving(
      items: current.items,
      supplier: current.supplier,
      expenses: current.expenses,
      supplierAccount: current.supplierAccount,
      payment: current.payment,
      paymentMode: current.paymentMode,
      storages: current.storages,
    ));

    try {
      int? accountNumber;
      double amountToSend;

      switch (current.paymentMode) {
        case PaymentMode.cash:
          accountNumber = 0;
          amountToSend = 0.0; // No credit to account
          break;

        case PaymentMode.credit:
          accountNumber = current.supplierAccount!.accNumber;
          amountToSend = current.grandTotal; // All amount as credit
          break;

        case PaymentMode.mixed:
          accountNumber = current.supplierAccount!.accNumber;
          amountToSend = current.creditAmount; // Credit portion to account
          break;
      }
      final records = current.items.map((item) {
        return PurchaseInvoiceRecord(
          proID: int.tryParse(item.productId) ?? 0,
          stgID: item.storageId,
          quantity: item.qty.toDouble(),
          stkQtyInBatch: item.stkBatch,
          sellPercentage: item.sellPriceAmount,
          pPrice: item.purPrice,
        );
      }).toList();

      final expRecords = current.expenses.map((item){
        return PurExpenseRecord(
            narration: item.narration,
            account: item.account,
            amount: item.amount
        );
      }).toList();

      final xRef = event.xRef ?? 'PUR-${DateTime.now().millisecondsSinceEpoch}';

      final response = await repo.addPurchaseInvoice(
        orderName: "Purchase",
        usrName: event.usrName,
        perID: event.ordPersonal,
        remark: event.remark,
        currency: event.invoiceCcy,
        xRef: xRef,
        account: accountNumber,
        amount: amountToSend,
        records: records,
        expRecord: expRecords,
      );

      final message = response['msg']?.toString() ?? 'No response message';

      if (message.toLowerCase().contains('success') || message.toLowerCase().contains('authorized')) {
        String invoiceNumber = response['invoiceNo']?.toString() ??
            response['ordID']?.toString() ??
            'Generated';

        // FIX: Create a copy of the current state to preserve for printing
        final invoiceData = current.copyWith();

        // Emit saved state WITH the invoice data
        emit(PurchaseInvoiceSaved(
          true,
          invoiceNumber: invoiceNumber,
          invoiceData: invoiceData, // Pass the preserved data
        ));

        // Complete the completer with invoice number
        event.completer.complete(invoiceNumber);

        // Reset the form after a microtask delay to allow UI to handle printing
        // This ensures the saved state is processed first
        Future.microtask(() {
          if (!emit.isDone) {
            add(ResetPurchaseInvoiceEvent());
          }
        });
      }
      else {
        String errorMessage;
        final msgLower = message.toLowerCase();

        if (msgLower.contains('over limit')) {
          errorMessage = 'Account credit limit exceeded';
        } else if (msgLower.contains('block')) {
          errorMessage = 'Account is blocked';
        } else if (msgLower.contains('not found')) {
          errorMessage = 'Invalid product or storage ID';
        } else if (msgLower.contains('unavailable')) {
          errorMessage = message;
        } else if (msgLower.contains('large')) {
          errorMessage = 'Payment amount exceeds total bill amount';
        } else if (msgLower.contains('failed')) {
          errorMessage = 'Invoice creation failed. Please try again.';
        } else {
          errorMessage = message;
        }

        emit(PurchaseInvoiceError(errorMessage));
        emit(savedState);
        event.completer.complete('');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('DioException')) {
        errorMessage = 'Network error: Please check your connection';
      }

      emit(PurchaseInvoiceError(errorMessage));
      emit(savedState);
      event.completer.complete('');
    }
  }

  Future<void> _onLoadStorages(LoadPurchaseStoragesEvent event, Emitter<PurchaseInvoiceState> emit) async {
    try {
      if (state is PurchaseInvoiceLoaded) {
        final current = state as PurchaseInvoiceLoaded;
        emit(current.copyWith(storages: []));
      }
    } catch (e) {
      // Handle error silently
    }
  }
}