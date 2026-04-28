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
import '../../Parser/parser.dart';

part 'sale_invoice_event.dart';
part 'sale_invoice_state.dart';

class SaleInvoiceBloc extends Bloc<SaleInvoiceEvent, SaleInvoiceState> {
  final Repositories repo;
  ExchangeRateBloc? _exchangeRateBloc;
  StreamSubscription? _exchangeRateSubscription;
  String? _baseCurrency;

  SaleInvoiceBloc(this.repo) : super(SaleInvoiceInitial()) {
    on<InitializeSaleInvoiceEvent>(_onInitialize);
    on<SelectCustomerEvent>(_onSelectCustomer);
    on<SelectCustomerAccountEvent>(_onSelectCustomerAccount);
    on<ClearCustomerEvent>(_onClearCustomer);
    on<AddNewSaleItemEvent>(_onAddNewItem);
    on<RemoveSaleItemEvent>(_onRemoveItem);
    on<UpdateSaleItemEvent>(_onUpdateItem);
    on<UpdateCashPaymentEvent>(_onUpdateCashPayment);
    on<ResetSaleInvoiceEvent>(_onReset);
    on<SaveSaleInvoiceEvent>(_onSaveInvoice);
    on<ClearCustomerAccountEvent>(_onClearCustomerAccount);
    on<UpdateItemDiscountTypeEvent>(_onUpdateItemDiscountType);
    on<UpdateItemDiscountValueEvent>(_onUpdateItemDiscountValue);
    on<UpdateGeneralDiscountEvent>(_onUpdateGeneralDiscount);
    on<UpdateItemUnitEvent>(_onUpdateItemUnit);
    on<UpdateExchangeRateEvent>(_onUpdateExchangeRate);
    on<UpdateExtraChargesEvent>(_onUpdateExtraCharges);
    on<UpdateExchangeRateManuallyEvent>(_onUpdateExchangeRateManually);
    on<UpdateCashCurrencyEvent>(_onUpdateCashCurrency);
    on<LoadSaleInvoiceForEditEvent>(_onLoadSaleInvoiceForEdit);
    on<UpdateRemarkEvent>(_onUpdateRemark);
  }

  void _onUpdateRemark(UpdateRemarkEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(remark: event.remark));
    }
  }

  Future<void> _onLoadSaleInvoiceForEdit(LoadSaleInvoiceForEditEvent event, Emitter<SaleInvoiceState> emit) async {
    emit(SaleInvoiceLoading());

    try {
      final response = await repo.fetchOrderById(orderId: event.orderId);

      if (response.isEmpty) {
        emit(SaleInvoiceError('Order not found'));
        return;
      }

      final parsed = OrderParser.parseOrderResponse(response);
      final records = parsed['records'] as List<Map<String, dynamic>>;
      final payments = parsed['payments'] as List<Map<String, dynamic>>;

      // Get exchange rate for account conversion (from base to account currency)
      double accountExchangeRate = 1.0;
      for (var payment in payments) {
        final narration = payment['narration'] as String;
        final match = RegExp(r'@Rate:\s*([\d.]+)').firstMatch(narration);
        if (match != null) {
          accountExchangeRate = double.parse(match.group(1)!);
          break;
        }
      }

      // Build items with local amount calculation
      final List<SaleInvoiceItem> items = [];
      for (var record in records) {
        final salePrice = record['salePrice'] as double;
        final localAmount = salePrice * accountExchangeRate;
        final productName = record['productName'] as String;
        final unit = record['unit'] as String;
        final storageName = record['storageName'] as String;
        items.add(SaleInvoiceItem(
          itemId: '${record['stkID']}_${DateTime.now().millisecondsSinceEpoch}_${items.length}',
          productId: record['productId'].toString(),
          productName: productName,
          qty: record['quantity'].toInt(),
          batch: record['batch'].toInt(),
          purPrice: record['purchasePrice'],
          salePrice: salePrice,
          landedPrice: record['landedPrice'],
          discount: record['discount'],
          storageId: record['storageId'],
          storageName: storageName,
          unit: unit,
          exchangeRate: accountExchangeRate,
          localAmount: localAmount,
        ));
      }

      // Get cash payment details
      double cashPayment = 0;
      String cashCurrency = '';
      double cashExchangeRate = 1.0;

      for (var payment in payments) {
        if (payment['account'] == 10101010) {
          cashPayment = payment['amount'] as double;
          cashCurrency = payment['currency'] as String;

          final narration = payment['narration'] as String;
          final match = RegExp(r'@Rate:\s*([\d.]+)').firstMatch(narration);
          if (match != null) {
            cashExchangeRate = double.parse(match.group(1)!);
          }
          break;
        }
      }

      // Convert cash payment to base currency ONLY if cash currency is different from base currency
      double cashPaymentInBase = cashPayment;
      if (cashCurrency.isNotEmpty &&
          cashCurrency != event.baseCurrency &&
          cashExchangeRate > 0) {
        cashPaymentInBase = cashPayment / cashExchangeRate;
      }

      // Get customer account
      final excludedAccounts = [10101010, 10101011, 10101018, 30303031, 40404053];
      Map<String, dynamic>? customerAccountData;
      for (var payment in payments) {
        final account = payment['account'] as int;
        if (account >= 500000 && !excludedAccounts.contains(account)) {
          customerAccountData = payment;
          break;
        }
      }

      AccountsModel? customerAccount;
      String toCurrency = event.baseCurrency;
      if (customerAccountData != null) {
        customerAccount = AccountsModel(
          accNumber: customerAccountData['account'],
          accName: '',
          actCurrency: customerAccountData['currency'],
          accAvailBalance: '0',
        );
        toCurrency = customerAccountData['currency'] as String;
      }

      final customer = IndividualsModel(
        perId: parsed['partyId'],
        perName: parsed['partyName'],
      );

      // Get extra charges
      double extraCharges = 0;
      for (var payment in payments) {
        if (payment['account'] == 10101018) {
          extraCharges = payment['amount'] as double;
          break;
        }
      }

      // FIX: Get general discount with type
      double generalDiscountAmount = 0;
      double originalDiscountValue = 0;
      DiscountType generalDiscountType = DiscountType.percentage;

      for (var payment in payments) {
        if (payment['account'] == 40404053) {
          generalDiscountAmount = payment['amount'] as double;

          final narration = payment['narration'] as String;

          // Extract discount type from narration
          final typeMatch = RegExp(r'Type:\s*(\w+)').firstMatch(narration);
          if (typeMatch != null) {
            final typeStr = typeMatch.group(1);
            if (typeStr == "AMT") {
              generalDiscountType = DiscountType.amount;
            } else if (typeStr == "PCT") {
              generalDiscountType = DiscountType.percentage;
            }
          }

          // Extract original discount value (what user entered)
          final originalMatch = RegExp(r'Original:\s*([\d.]+)').firstMatch(narration);
          if (originalMatch != null) {
            originalDiscountValue = double.parse(originalMatch.group(1)!);
          }
          break;
        }
      }

      // Use original discount value if available (user-entered value), otherwise use the calculated amount
      final finalGeneralDiscount = originalDiscountValue > 0 ? originalDiscountValue : generalDiscountAmount;

      final grandTotal = items.fold(0.0, (sum, item) => sum + item.totalSale);

      PaymentMode paymentMode;
      if (cashPaymentInBase <= 0) {
        paymentMode = PaymentMode.credit;
      } else if (cashPaymentInBase >= grandTotal) {
        paymentMode = PaymentMode.cash;
      } else {
        paymentMode = PaymentMode.mixed;
      }

      emit(SaleInvoiceLoaded(
        items: items,
        payments: [],
        customer: customer,
        customerAccount: customerAccount,
        cashPayment: cashPaymentInBase,
        paymentMode: paymentMode,
        exchangeRate: accountExchangeRate,
        fromCurrency: event.baseCurrency,
        toCurrency: toCurrency,
        cashCurrency: cashCurrency != event.baseCurrency ? cashCurrency : null,
        cashExchangeRate: cashCurrency != event.baseCurrency ? cashExchangeRate : 1.0,
        extraCharges: extraCharges,
        generalDiscount: finalGeneralDiscount,
        generalDiscountType: generalDiscountType,
        xRef: parsed['reference'],
        remark: parsed['remarks'],
      ));

    } catch (e) {
      emit(SaleInvoiceError('Failed to load invoice: $e'));
    }
  }

  void setBaseCurrency(String currency) {
    _baseCurrency = currency;
  }
  void _onUpdateCashCurrency(UpdateCashCurrencyEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(
        cashCurrency: event.currency,
        cashExchangeRate: event.exchangeRate,
      ));
    }
  }

  void setExchangeRateBloc(ExchangeRateBloc exchangeRateBloc) {
    _exchangeRateSubscription?.cancel();
    _exchangeRateBloc = exchangeRateBloc;
    _exchangeRateSubscription = _exchangeRateBloc!.stream.listen((exchangeState) {
      if (exchangeState is ExchangeRateLoadedState && state is SaleInvoiceLoaded) {
        final current = state as SaleInvoiceLoaded;
        if (current.fromCurrency != null && current.toCurrency != null) {
          final rate = double.tryParse(exchangeState.rate ?? "1.0") ?? 1.0;
          add(UpdateExchangeRateEvent(
            rate: rate,
            fromCurrency: current.fromCurrency!,
            toCurrency: current.toCurrency!,
          ));
        }
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
      final updatedItems = current.items.map((item) {
        return item.copyWith(
          exchangeRate: event.rate,
          localAmount: item.totalSale * event.rate,
        );
      }).toList();

      emit(current.copyWith(
        items: updatedItems,
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

    if (event.rate < 0) {
      emit(current.copyWith(
        exchangeRate: event.rate,
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
      ));
      return;
    }

    final updatedItems = current.items.map((item) {
      return item.copyWith(
        exchangeRate: event.rate,
        localAmount: item.salePrice! * event.rate,
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

  void _onClearCustomerAccount(ClearCustomerAccountEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      emit(current.copyWith(
        customerAccount: null,
        cashPayment: current.grandTotal,
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
      payments: [],
      cashPayment: 0.0,
      paymentMode: PaymentMode.cash,
      extraCharges: 0.0,
      generalDiscount: 0.0,
      cashCurrency: '',
      cashExchangeRate: 1.0,
      fromCurrency: _baseCurrency, // Use stored base currency
      toCurrency: _baseCurrency,
    ));
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
      payments: [],
      cashPayment: 0.0,
      paymentMode: PaymentMode.cash,
      extraCharges: 0.0,
      generalDiscount: 0.0,
      cashCurrency: '',
      cashExchangeRate: 1.0,
      fromCurrency: _baseCurrency,
      toCurrency: _baseCurrency,
    ));
  }

  Future<void> fetchExchangeRate(String fromCurrency, String toCurrency) async {
    try {
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
      if (current.cashPayment <= 0) {
        newPaymentMode = PaymentMode.credit;
      } else if (current.cashPayment >= current.grandTotal) {
        newPaymentMode = PaymentMode.cash;
      } else {
        newPaymentMode = PaymentMode.mixed;
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
        cashPayment: current.grandTotal,
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
          salePrice: 0,
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
            discountType: event.discountType ?? item.discountType,
            localAmount: event.localeAmount,
            landedPrice: event.landedPrice ?? item.landedPrice,
            exchangeRate: event.exchangeRate ?? current.exchangeRate,
            purPrice: event.purPrice ?? item.purPrice,
            salePrice: event.salePrice ?? item.salePrice,
            storageName: event.storageName ?? item.storageName,
            storageId: event.storageId ?? item.storageId,
            unit: event.unit ?? item.unit,
          );
        }
        return item;
      }).toList();

      emit(current.copyWith(items: updatedItems));
    }
  }

  void _onUpdateCashPayment(UpdateCashPaymentEvent event, Emitter<SaleInvoiceState> emit) {
    if (state is SaleInvoiceLoaded) {
      final current = state as SaleInvoiceLoaded;
      double newCashPayment = event.cashPayment;
      PaymentMode newMode;

      if (newCashPayment <= 0) {
        newMode = PaymentMode.credit;
        newCashPayment = 0;
      } else if (newCashPayment >= current.grandTotal) {
        newMode = PaymentMode.cash;
        newCashPayment = current.grandTotal;
      } else {
        // Only use mixed mode if an account is selected
        // If no account is selected, default to cash mode with full payment
        if (current.customerAccount != null) {
          newMode = PaymentMode.mixed;
        } else {
          // No account selected, so this must be a cash sale
          // Force cash payment to equal grand total
          newMode = PaymentMode.cash;
          newCashPayment = current.grandTotal;
        }
      }

      emit(current.copyWith(
        cashPayment: newCashPayment,
        paymentMode: newMode,
      ));
    }
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
      emit(SaleInvoiceError(tr.selectCustomer));
      emit(savedState);
      event.completer.complete('');
      return;
    }

    if (current.paymentMode == PaymentMode.cash) {
      if(current.cashPayment != current.grandTotal || current.cashPaymentLocal != current.grandTotalLocal){
        emit(SaleInvoiceError(tr.invalidCashAmount));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    if (current.paymentMode == PaymentMode.mixed && current.customerAccount == null) {
      emit(SaleInvoiceError(tr.selectCreditAccountMsg));
      emit(savedState);
      event.completer.complete('');
      return;
    }

    if (current.paymentMode == PaymentMode.credit && current.customerAccount == null) {
      emit(SaleInvoiceError(tr.selectCreditAccountMsg));
      emit(savedState);
      event.completer.complete('');
      return;
    }

    if (current.items.isEmpty) {
      emit(SaleInvoiceError(tr.addItemMsg));
      emit(savedState);
      event.completer.complete('');
      return;
    }

    for (var item in current.items) {
      if (item.productId.isEmpty || item.productName.isEmpty) {
        emit(SaleInvoiceError(tr.addProductMsg));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.storageId == 0 || item.storageName.isEmpty) {
        emit(SaleInvoiceError("Please Select Storage"));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.salePrice == null || item.salePrice! <= 0) {
        emit(SaleInvoiceError(tr.addValidPrice));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (item.qty <= 0) {
        emit(SaleInvoiceError(tr.addValidQty));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    emit(SaleInvoiceSaving(
      items: current.items,
      payments: current.payments,
      customer: current.customer,
      customerAccount: current.customerAccount,
      cashPayment: current.cashPayment,
      paymentMode: current.paymentMode,
      storages: current.storages,
      generalDiscount: current.generalDiscount,
      generalDiscountType: current.generalDiscountType,
      exchangeRate: current.exchangeRate,
      fromCurrency: current.fromCurrency,
      toCurrency: current.toCurrency,
      extraCharges: current.extraCharges,
      cashCurrency: current.cashCurrency,
      cashExchangeRate: current.cashExchangeRate,
    ));

    try {
      final records = current.items.map((item) {
        double discountAmount = 0.0;
        if (item.discount != null && item.discount! > 0) {
          if (item.discountType == DiscountType.percentage) {
            final subtotal = item.qty * (item.salePrice ?? 0);
            discountAmount = subtotal * (item.discount! / 100);
          } else {
            discountAmount = item.discount!;
          }
        }

        return SaleInvoiceRecord(
          proID: int.tryParse(item.productId) ?? 0,
          stgID: item.storageId,
          quantity: item.qty.toDouble(),
          batch: item.batch?.toDouble() ?? 0.0,
          discount: discountAmount,
          purchaseAveragePrice: item.purPrice ?? 0.0,
          landedPrice: item.landedPrice,
          purchasePrice: item.purPrice,
          salePrice: item.salePrice ?? 0.0,
        );
      }).toList();

      final xRef = event.xRef ?? '';

      // FIX: Ensure baseCurrency is not empty - get from auth state if needed
      final baseCurrency = current.fromCurrency ?? '';
      if (baseCurrency.isEmpty) {
        emit(SaleInvoiceError("Base currency not configured. Please contact administrator."));
        emit(savedState);
        event.completer.complete('');
        return;
      }

      final accountCurrency = current.customerAccount?.actCurrency ?? '';
      final needsConversion = accountCurrency.isNotEmpty &&
          baseCurrency.isNotEmpty &&
          accountCurrency != baseCurrency;

      final List<SalePaymentRecord> apiPayments = [];

      // Extra charges - use baseCurrency which is now guaranteed non-empty
      if (current.extraCharges > 0) {
        apiPayments.add(SalePaymentRecord(
          accountNumber: 10101018,
          amount: current.extraCharges,
          currency: baseCurrency,
          exRate: 1.0,
          narration: "Extra charges",
        ));
      }

      // Add general discount - use baseCurrency
      if (current.generalDiscountAmount > 0) {
        final discountTypeStr = current.generalDiscountType == DiscountType.percentage ? "PCT" : "AMT";
        apiPayments.add(SalePaymentRecord(
          accountNumber: 40404053,
          amount: current.generalDiscountAmount,
          currency: baseCurrency,
          exRate: 1.0,
          narration: "Discount on sales - Type: $discountTypeStr, Original: ${current.generalDiscount}",
        ));
      }

      // Add credit payment
      if (current.paymentMode != PaymentMode.cash && current.customerAccount != null) {
        final creditAmount = current.creditAmount;
        if (creditAmount > 0) {
          final convertedAmount = needsConversion
              ? creditAmount * current.safeExchangeRate
              : creditAmount;

          // Ensure accountCurrency is valid
          final validAccountCurrency = accountCurrency.isNotEmpty ? accountCurrency : baseCurrency;

          apiPayments.add(SalePaymentRecord(
            accountNumber: current.customerAccount!.accNumber!,
            amount: convertedAmount,
            currency: validAccountCurrency,
            exRate: needsConversion ? current.safeExchangeRate : 1.0,
            narration: "Customer account payment",
          ));
        }
      }

      // Add cash payment with selected currency
      if (current.cashPayment > 0) {
        // FIX: Ensure cashCurrency is valid - fallback to baseCurrency
        String cashCurrency = current.cashCurrency ?? '';
        if (cashCurrency.isEmpty) {
          cashCurrency = baseCurrency;
        }

        final cashExRate = (cashCurrency != baseCurrency)
            ? current.cashExchangeRate
            : 1.0;

        final amountInCashCurrency = current.cashPayment * cashExRate;

        apiPayments.add(SalePaymentRecord(
          accountNumber: 10101010,
          amount: amountInCashCurrency,
          currency: cashCurrency,
          exRate: cashExRate,
          narration: "Cash payment",
        ));
      }

      final response = await repo.addSaleInvoice(
        usrName: event.usrName,
        perID: event.ordPersonal,
        xRef: xRef,
        orderName: event.orderName,
        remark: event.remark,
        payment: apiPayments,
        records: records,
      );

      final message = response['msg']?.toString() ?? 'No response message';
      final sp = response['specific']?.toString() ?? '';

      if (message.toLowerCase().contains('success') || message.toLowerCase().contains('authorized')) {
        final invoiceNumber = response['ordID']?.toString() ?? 'No Order Id';
        final invoiceData = current.copyWith();
        emit(SaleInvoiceSaved(true, invoiceNumber: invoiceNumber, invoiceData: invoiceData));
        event.completer.complete(invoiceNumber);
        Future.microtask(() {
          if (!emit.isDone) add(ResetSaleInvoiceEvent());
        });
      } else if (message.toLowerCase().contains('not enough')) {
        String errorMessage = '${tr.notEnoughMsg} $sp';
        emit(SaleInvoiceError(errorMessage));
        emit(savedState);
        event.completer.complete('');
      } else {
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
      emit(SaleInvoiceError(errorMessage));
      emit(savedState);
      event.completer.complete('');
    }
  }

}