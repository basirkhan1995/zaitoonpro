import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/model/sale_invoice_items.dart';
import '../../../../../../../../Services/localization_services.dart';
import '../../../../../../../../Services/repositories.dart';
import '../../../../../Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import '../../../../../Settings/Ui/Company/Storage/model/storage_model.dart';
import '../../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';

part 'sale_invoice_event.dart';
part 'sale_invoice_state.dart';

class SaleInvoiceBloc extends Bloc<SaleInvoiceEvent, SaleInvoiceState> {
  final Repositories repo;
  ExchangeRateBloc? _exchangeRateBloc;
  StreamSubscription? _exchangeRateSubscription;

  SaleInvoiceBloc(this.repo) : super(SaleInvoiceInitial()) {
    on<InitializeSaleInvoiceEvent>(_onInitialize);
    on<SelectCustomerEvent>(_onSelectCustomer);
    on<SelectCustomerAccountEvent>(_onSelectCustomerAccount);
    on<ClearCustomerEvent>(_onClearCustomer);
    on<AddNewSaleItemEvent>(_onAddNewItem);
    on<RemoveSaleItemEvent>(_onRemoveItem);
    on<UpdateSaleItemEvent>(_onUpdateItem);
    on<UpdateSaleReceivePaymentEvent>(_onUpdateReceivePayment);
    on<ResetSaleInvoiceEvent>(_onReset);
    on<SaveSaleInvoiceEvent>(_onSaveInvoice);
    on<ClearCustomerAccountEvent>(_onClearSupplierAccount);
    on<UpdateItemDiscountTypeEvent>(_onUpdateItemDiscountType);
    on<UpdateItemDiscountValueEvent>(_onUpdateItemDiscountValue);
    on<UpdateGeneralDiscountEvent>(_onUpdateGeneralDiscount);
    on<UpdateItemUnitEvent>(_onUpdateItemUnit);
    on<UpdateExchangeRateEvent>(_onUpdateExchangeRate);
    on<UpdateExtraChargesEvent>(_onUpdateExtraCharges);
    on<UpdateExchangeRateManuallyEvent>(_onUpdateExchangeRateManually);
  }

  void setExchangeRateBloc(ExchangeRateBloc exchangeRateBloc) {
    _exchangeRateBloc = exchangeRateBloc;
    _exchangeRateSubscription = _exchangeRateBloc!.stream.listen((state) {
      if (state is ExchangeRateLoadedState && this.state is SaleInvoiceLoaded) {
        add(UpdateAllLocalAmountsEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _exchangeRateSubscription?.cancel();
    return super.close();
  }

  void _onUpdateExchangeRateManually(UpdateExchangeRateManuallyEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(
        exchangeRate: event.rate,
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
      ));
    }
  }
  void _onUpdateExtraCharges(UpdateExtraChargesEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(extraCharges: event.charges));
    }
  }
  void _onUpdateExchangeRate(UpdateExchangeRateEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is! SaleInvoiceLoaded) return;
    final current = state as SaleInvoiceLoaded;

    // Handle loading state (negative rate)
    if (event.rate < 0) {
      emit(current.copyWith(
        exchangeRate: event.rate,
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
      ));
      return;
    }

    // Update all items with new exchange rate
    final updatedItems = current.items.map((item) {
      return item.copyWith(
        exchangeRate: event.rate,
        localAmount: item.totalSale * event.rate, // Use totalSale (after discount)
      );
    }).toList();

    emit(current.copyWith(
      items: updatedItems,
      exchangeRate: event.rate,
      fromCurrency: event.fromCurrency,
      toCurrency: event.toCurrency,
    ));
  }
  void _onUpdateItemDiscountType(UpdateItemDiscountTypeEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      final updatedItems = current.items.map((item) {
        if (item.rowId == event.rowId) {
          return item.copyWith(discountType: event.discountType);
        }
        return item;
      }).toList();
      emit(current.copyWith(items: updatedItems));
    }
  }
  void _onUpdateItemDiscountValue(UpdateItemDiscountValueEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      final updatedItems = current.items.map((item) {
        if (item.rowId == event.rowId) {
          return item.copyWith(discount: event.discountValue);
        }
        return item;
      }).toList();
      emit(current.copyWith(items: updatedItems));
    }
  }
  void _onUpdateGeneralDiscount(UpdateGeneralDiscountEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(
        generalDiscount: event.discountValue,
        generalDiscountType: event.discountType,
      ));
    }
  }
  void _onUpdateItemUnit(UpdateItemUnitEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      final updatedItems = current.items.map((item) {
        if (item.rowId == event.rowId) {
          return item.copyWith(unit: event.unit);
        }
        return item;
      }).toList();
      emit(current.copyWith(items: updatedItems));
    }
  }
  void _onClearSupplierAccount(ClearCustomerAccountEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(
        customerAccount: null,
        payment: current.grandTotal,
        paymentMode: PaymentMode.cash,
      ));
    }
  }
  void _onInitialize(InitializeSaleInvoiceEvent event, Emitter<SaleInvoiceState> emit) {
    emit(SaleInvoiceLoaded(
      items: [SaleInvoiceItem(
        productId: '',
        productName: '',
        qty: 1,
        batch: 0,
        discount: 0,
        purPrice: 0,
        salePrice: 0,
        storageName: '',
        storageId: 0,
      )],
      payment: 0.0,
      paymentMode: PaymentMode.cash,
    ));
  }


  Future<void> fetchExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      // Update state to loading
      add(UpdateExchangeRateEvent(
        rate: -1,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      ));

      final rateStr = await repo.getSingleRate(
        fromCcy: fromCurrency,
        toCcy: toCurrency,
      );

      final parsedRate = double.tryParse(rateStr ?? "1.0") ?? 1.0;

      add(UpdateExchangeRateEvent(
        rate: parsedRate,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      ));
    } catch (e) {
      add(UpdateExchangeRateEvent(
        rate: 1.0,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      ));
    }
  }

  void _onSelectCustomerAccount(SelectCustomerAccountEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;

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
        customerAccount: event.customer,
        paymentMode: newPaymentMode,
      ));
    }
  }

  void _onSelectCustomer(SelectCustomerEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(customer: event.supplier));
    }
  }

  void _onClearCustomer(ClearCustomerEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(
        customer: null,
        customerAccount: null,
        paymentMode: PaymentMode.cash,
      ));
    }
  }

  void _onAddNewItem(AddNewSaleItemEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is! SaleInvoiceLoaded) return;
    final current = state as SaleInvoiceLoaded;

    final newItem = SaleInvoiceItem(
      productId: '',
      productName: '',
      qty: 1,
      batch: 0,
      discount: 0,
      purPrice: 0,
      salePrice: 0,
      storageName: '',
      storageId: 0,
    );

    final updatedItems = List<SaleInvoiceItem>.from(current.items)..add(newItem);
    emit(current.copyWith(items: updatedItems));
  }
  void _onRemoveItem(RemoveSaleItemEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      final updatedItems = current.items.where((item) => item.rowId != event.rowId).toList();

      if (updatedItems.isEmpty) {
        updatedItems.add(SaleInvoiceItem(
          productId: '',
          productName: '',
          qty: 1,
          batch: 0,
          discount: 0,
          purPrice: 0,
          storageName: '',
          storageId: 0,
        ));
      }

      emit(current.copyWith(items: updatedItems));
    }
  }

  void _onUpdateItem(UpdateSaleItemEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      final updatedItems = current.items.map((item) {
        if (item.rowId == event.rowId) {
          return SaleInvoiceItem(
            itemId: item.rowId,
            productId: event.productId ?? item.productId,
            productName: event.productName ?? item.productName,
            qty: event.qty ?? item.qty,
            batch: event.batch ?? item.batch,
            discount: event.discount ?? item.discount,
            localAmount: event.localeAmount,
            exchangeRate: event.exchangeRate,
            purPrice: event.purPrice ?? item.purPrice,
            salePrice: event.salePrice ?? item.salePrice,
            storageName: event.storageName ?? item.storageName,
            storageId: event.storageId ?? item.storageId,
          );
        }
        return item;
      }).toList();

      emit(current.copyWith(items: updatedItems));
    }
  }

  void _onUpdateReceivePayment(UpdateSaleReceivePaymentEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;

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
        // Clear customerAccount only when switching to full cash
        customerAccount: newPaymentMode == PaymentMode.cash ? null : current.customerAccount,
      ));
    }
  }
  void _onReset(ResetSaleInvoiceEvent event, Emitter<SaleInvoiceState> emit) {
    emit(SaleInvoiceLoaded(
      items: [SaleInvoiceItem(
        productId: '',
        productName: '',
        qty: 1,
        batch: 0,
        discount: 0,
        purPrice: 0,
        salePrice: 0,
        storageName: '',
        storageId: 0,
      )],
      payment: 0.0,
      paymentMode: PaymentMode.cash,
    ));
  }

  Future<void> _onSaveInvoice(SaveSaleInvoiceEvent event, Emitter<SaleInvoiceState> emit) async {
    final tr = localizationService.loc;
    if (state is! SaleInvoiceLoaded) {
      event.completer.complete('');
      return;
    }

    final current = state as SaleInvoiceLoaded;
    final savedState = current.copyWith();

    // Validation
    if (current.customer == null) {
      emit(SaleInvoiceError('Please select a customer'));
      emit(savedState);
      event.completer.complete('');
      return;
    }

    if (current.items.isEmpty) {
      emit(SaleInvoiceError('Please add at least one item'));
      emit(savedState);
      event.completer.complete('');
      return;
    }

    for (var i = 0; i < current.items.length; i++) {
      final item = current.items[i];
      if (item.productId.isEmpty) {
        emit(SaleInvoiceError('Please select a product for item ${i + 1}'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.storageId == 0) {
        emit(SaleInvoiceError('Please select a storage for item ${i + 1}'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.salePrice == null || item.salePrice! <= 0) {
        emit(SaleInvoiceError('Please enter a valid sale price for item ${i + 1}'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.qty <= 0) {
        emit(SaleInvoiceError('Please enter a valid quantity for item ${i + 1}'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    if (current.paymentMode == PaymentMode.credit || current.paymentMode == PaymentMode.mixed) {
      if (current.customerAccount == null) {
        emit(SaleInvoiceError('Please select a customer account for credit payment'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    if (current.paymentMode == PaymentMode.mixed) {
      if (current.payment <= 0) {
        emit(SaleInvoiceError('For mixed payment, cash payment must be greater than 0'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (current.payment >= current.grandTotal) {
        emit(SaleInvoiceError('For mixed payment, cash payment must be less than total amount'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    emit(SaleInvoiceSaving(
      items: current.items,
      customer: current.customer,
      customerAccount: current.customerAccount,
      payment: current.payment,
      paymentMode: current.paymentMode,
      storages: current.storages,
    ));

    try {
      int? accountNumber;
      double amountToSend;
      String? cashCurrency;

      switch (current.paymentMode) {
        case PaymentMode.cash:
          accountNumber = 0;
          amountToSend = 0.0;
          cashCurrency = current.fromCurrency ?? "";
          break;
        case PaymentMode.credit:
          accountNumber = current.customerAccount!.accNumber;
          amountToSend = current.grandTotal;
          cashCurrency = current.customerAccount!.actCurrency;
          break;
        case PaymentMode.mixed:
          accountNumber = current.customerAccount!.accNumber;
          amountToSend = current.creditAmount;
          cashCurrency = current.fromCurrency ?? "";
          break;
      }

      final records = current.items.map((item) {
        // Calculate discount amount (convert percentage to amount if needed)
        double discountAmount = 0.0;
        if (item.discount != null && item.discount! > 0) {
          if (item.discountType == DiscountType.percentage) {
            // Calculate percentage discount as amount
            final subtotal = item.qty * (item.salePrice ?? 0);
            discountAmount = subtotal * (item.discount! / 100);
          } else {
            // Fixed amount discount
            discountAmount = item.discount!;
          }
        }

        return SaleInvoiceRecord(
          proID: int.tryParse(item.productId) ?? 0,
          stgID: item.storageId,
          quantity: item.qty.toDouble(),
          batch: item.batch?.toDouble() ?? 0.0,
          discount: discountAmount, // Send calculated discount amount
          pPrice: item.purPrice ?? 0.0, // Average price
          sPrice: item.salePrice ?? 0.0,
        );
      }).toList();

      final xRef = event.xRef ?? '';

      // Get general discount amount (convert percentage to amount if needed)
      double orderDiscountAmount = 0.0;
      if (current.generalDiscount > 0) {
        if (current.generalDiscountType == DiscountType.percentage) {
          orderDiscountAmount = current.totalAfterItemDiscount * (current.generalDiscount / 100);
        } else {
          orderDiscountAmount = current.generalDiscount;
        }
      }

      final response = await repo.addSaleInvoice(
        usrName: event.usrName,
        perID: event.ordPersonal,
        xRef: xRef,
        orderName: event.orderName,
        account: accountNumber,
        amount: amountToSend,
        remark: event.remark,
        extraCharges: current.extraCharges,
        currencyCash: cashCurrency,
        orderDiscount: orderDiscountAmount,
        records: records,
      );

      final message = response['msg']?.toString() ?? 'No response message';
      final sp = response['specific']?.toString() ?? 'No response message';

      if (message.toLowerCase().contains('success') || message.toLowerCase().contains('authorized')) {
        final invoiceNumber = response['ordID']?.toString() ?? 'No Order Id';
        final invoiceData = current.copyWith();
        emit(SaleInvoiceSaved(true, invoiceNumber: invoiceNumber, invoiceData: invoiceData));
        event.completer.complete(invoiceNumber);
        Future.microtask(() {
          if (!emit.isDone) add(ResetSaleInvoiceEvent());
        });
      }
      else if (message.toLowerCase().contains('not enough')) {
        String errorMessage = '${tr.notEnoughMsg} $sp';
        emit(SaleInvoiceError(errorMessage));
        emit(savedState);
        event.completer.complete('');
      }
      else {
        String errorMessage;
        final msgLower = message.toLowerCase();
        if (msgLower.contains('over limit')) {
          errorMessage = tr.overLimitMessage;
        } else if (msgLower.contains('block')) {
          errorMessage = tr.accountBlockedMessage;
        } else if (msgLower.contains('not found')) {
          errorMessage = 'Invalid product or storage ID';
        } else if (msgLower.contains('failed')) {
          errorMessage = 'Invoice creation failed. Please try again.';
        } else {
          errorMessage = message;
        }
        emit(SaleInvoiceError(errorMessage));
        emit(savedState);
        event.completer.complete('');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('DioException')) {
        errorMessage = 'Network error: Please check your connection';
      }
      emit(SaleInvoiceError(errorMessage));
      emit(savedState);
      event.completer.complete('');
    }
  }

}