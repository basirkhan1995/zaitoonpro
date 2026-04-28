import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../../Services/repositories.dart';
import '../../../../../Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import '../../../../../Settings/Ui/Company/Storage/model/storage_model.dart';
import '../../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../../Parser/parser.dart';
import '../model/purchase_invoice_items.dart';

part 'purchase_invoice_event.dart';
part 'purchase_invoice_state.dart';

class PurchaseInvoiceBloc extends Bloc<PurchaseInvoiceEvent, PurchaseInvoiceState> {
  final Repositories repo;
  ExchangeRateBloc? _exchangeRateBloc;
  StreamSubscription? _exchangeRateSubscription;

  PurchaseInvoiceBloc(this.repo) : super(PurchaseInvoiceInitial()) {
    on<InitializePurchaseInvoiceEvent>(_onInitialize);
    on<SelectSupplierEvent>(_onSelectSupplier);
    on<SelectSupplierAccountEvent>(_onSelectSupplierAccount);
    on<ClearSupplierEvent>(_onClearSupplier);
    on<AddNewPurchaseItemEvent>(_onAddNewItem);
    on<RemovePurchaseItemEvent>(_onRemoveItem);
    on<UpdatePurchaseItemEvent>(_onUpdateItem);
    on<UpdateCashPaymentEvent>(_onUpdateCashPayment);
    on<ResetPurchaseInvoiceEvent>(_onReset);
    on<SavePurchaseInvoiceEvent>(_onSaveInvoice);
    on<LoadPurchaseStoragesEvent>(_onLoadStorages);
    on<ClearSupplierAccountEvent>(_onClearSupplierAccount);

    // Payment handlers (unified)
    on<AddPaymentEvent>(_onAddPayment);
    on<RemovePaymentEvent>(_onRemovePayment);
    on<UpdatePaymentEvent>(_onUpdatePayment);
    on<UpdateAllLandedPricesEvent>(_onUpdateAllLandedPrices);

    // Exchange rate handlers
    on<UpdateExchangeRateForInvoiceEvent>(_onUpdateExchangeRate);
    on<UpdateExchangeRateManuallyEvent>(_onUpdateExchangeRateManually);

    on<UpdateCashCurrencyEvent>(_onUpdateCashCurrency);


    on<LoadPurchaseInvoiceForEditEvent>(_onLoadPurchaseInvoiceForEdit);
  }

  Future<void> _onLoadPurchaseInvoiceForEdit(LoadPurchaseInvoiceForEditEvent event, Emitter<PurchaseInvoiceState> emit) async {
    emit(PurchaseInvoiceLoading());

    try {
      final response = await repo.fetchOrderById(orderId: event.orderId);

      if (response.isEmpty) {
        emit(PurchaseInvoiceError('Order not found'));
        return;
      }

      final parsed = OrderParser.parseOrderResponse(response);
      final records = parsed['records'] as List<Map<String, dynamic>>;
      final payments = parsed['payments'] as List<Map<String, dynamic>>;

      // Build items with UNIQUE IDs
      final List<PurchaseInvoiceItem> items = [];
      for (var record in records) {
        items.add(PurchaseInvoiceItem(
          productId: record['productId'].toString(),
          qty: (record['quantity'] as double).toInt(),
          stkBatch: (record['batch'] as double).toInt(),
          productName: record['productName'] as String,
          unit: record['unit'] as String,
          purPrice: record['purchasePrice'],
          landedPrice: record['landedPrice'],
          sellPriceAmount: 0,
          storageId: record['storageId'],
          storageName: record['storageName'] as String,
        ));
      }

      // Get exchange rate from narration
      final exchangeRate = OrderParser.getExchangeRate(payments);

      // Get cash payment for PURCHASE (Cr side)
      final cashPayment = OrderParser.getPurchaseCashPayment(payments);
      final cashCurrency = OrderParser.getPurchaseCashCurrency(payments);

      // Get supplier account (Cr side - we owe supplier)
      final supplierAccountData = OrderParser.getSupplierAccount(payments);

      AccountsModel? supplierAccount;
      String toCurrency = event.baseCurrency;

      if (supplierAccountData != null) {
        supplierAccount = AccountsModel(
          accNumber: supplierAccountData['account'],
          accName: '',
          actCurrency: supplierAccountData['currency'],
          accAvailBalance: '0',
        );
        toCurrency = supplierAccountData['currency'];
      }

      // IMPORTANT: Extract expenses ONLY (not supplier account, not cash)
      // Filter for expense accounts (40404040-40404999) with Dr side
      final expensesData = OrderParser.getExpenses(payments);

      List<PurchasePaymentRecord> expenses = [];

      for (var expense in expensesData) {
        expenses.add(
          PurchasePaymentRecord(
            accountNumber: expense['account'] as int,
            amount: expense['amount'] as double,
            currency: (expense['currency'] ?? event.baseCurrency).toString(),
            exRate: exchangeRate,
            narration: _extractExpenseNarration(expense['narration']?.toString() ?? ''),
            isExpense: true,
          ),
        );
      }

      // Get supplier
      final supplier = IndividualsModel(
        perId: parsed['partyId'],
        perName: parsed['partyName'],
      );

      // Calculate totals
      final itemsTotal = items.fold(0.0, (sum, item) => sum + (item.totalPurchase));
      final expensesTotal = OrderParser.getExpensesTotal(payments);
      final totalInvoice = itemsTotal + expensesTotal;

      // Convert cash payment to base currency if needed
      double cashPaymentInBase = cashPayment;
      if (cashCurrency.isNotEmpty &&
          cashCurrency != event.baseCurrency &&
          exchangeRate > 0) {
        cashPaymentInBase = cashPayment * exchangeRate; // Multiply to convert to base
      }

      // Determine payment mode based on cash payment and supplier account
      PaymentMode paymentMode;
      final hasCreditPayment = supplierAccountData != null &&
          (supplierAccountData['amount'] as double) > 0;

      if (cashPaymentInBase <= 0 && !hasCreditPayment) {
        paymentMode = PaymentMode.credit;
      } else if (cashPaymentInBase >= totalInvoice) {
        paymentMode = PaymentMode.cash;
      } else if (cashPaymentInBase > 0 && hasCreditPayment) {
        paymentMode = PaymentMode.mixed;
      } else if (cashPaymentInBase > 0) {
        paymentMode = PaymentMode.cash;
      } else {
        paymentMode = PaymentMode.credit;
      }

      emit(PurchaseInvoiceLoaded(
        items: items,
        payments: expenses, // Expenses only
        supplier: supplier,
        supplierAccount: supplierAccount,
        cashPayment: cashPaymentInBase,
        paymentMode: paymentMode,
        exchangeRate: exchangeRate,
        fromCurrency: event.baseCurrency,
        toCurrency: toCurrency,
        cashCurrency: cashCurrency != event.baseCurrency ? cashCurrency : null,
        cashExchangeRate: exchangeRate,
        xRef: parsed['reference'],
        remark: parsed['remarks'],
      ));

    } catch (e) {
      emit(PurchaseInvoiceError('Failed to load invoice: $e'));
    }
  }

// Helper to extract clean narration without rate info
  String _extractExpenseNarration(String narration) {
    // Remove @Rate: ... part if present
    final rateMatch = RegExp(r'\s*@Rate:\s*[\d.]+').firstMatch(narration);
    if (rateMatch != null) {
      return narration.substring(0, rateMatch.start).trim();
    }
    return narration.trim();
  }
  void _onUpdateCashCurrency(UpdateCashCurrencyEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      emit(current.copyWith(
        cashCurrency: event.currency,
        cashExchangeRate: event.exchangeRate,
      ));
    }
  }
  void _onUpdateExchangeRateManually(UpdateExchangeRateManuallyEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      emit(current.copyWith(
        exchangeRate: event.rate,
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
      ));
    }
  }
  void setExchangeRateBloc(ExchangeRateBloc exchangeRateBloc) {
    _exchangeRateSubscription?.cancel();
    _exchangeRateBloc = exchangeRateBloc;
    _exchangeRateSubscription = _exchangeRateBloc!.stream.listen((exchangeState) {
      if (exchangeState is ExchangeRateLoadedState && state is PurchaseInvoiceLoaded) {
        // Don't auto-update, let user control
      }
    });
  }

  @override
  Future<void> close() {
    _exchangeRateSubscription?.cancel();
    return super.close();
  }

  void _onUpdateItem(UpdatePurchaseItemEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final updatedItems = current.items.map((item) {
        if (item.rowId == event.rowId) {
          return PurchaseInvoiceItem(
            itemId: item.rowId,
            stkBatch: event.batch?.toInt() ?? item.stkBatch,
            sellPriceAmount: event.sellPriceAmount ?? item.sellPriceAmount,
            productId: event.productId ?? item.productId,
            productName: event.productName ?? item.productName,
            qty: event.qty ?? item.qty,
            purPrice: event.purPrice ?? item.purPrice,
            storageName: event.storageName ?? item.storageName,
            storageId: event.storageId ?? item.storageId,
            exchangeRate: current.exchangeRate ?? 1.0,
          );
        }
        return item;
      }).toList();

      emit(current.copyWith(items: updatedItems));
      // Recalculate landed prices after item update
      add(UpdateAllLandedPricesEvent());
    }
  }

  Future<void> _onUpdateExchangeRate(
      UpdateExchangeRateForInvoiceEvent event,
      Emitter<PurchaseInvoiceState> emit,
      ) async {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      try {
        final rate = await repo.getSingleRate(
          fromCcy: event.fromCurrency,
          toCcy: event.toCurrency,
        );

        final parsedRate = double.tryParse(rate ?? "1.0") ?? 1.0;

        emit(current.copyWith(
          exchangeRate: parsedRate,
          fromCurrency: event.fromCurrency,
          toCurrency: event.toCurrency,
        ));
      } catch (e) {
        emit(PurchaseInvoiceError('Failed to fetch exchange rate: $e'));
        emit(current);
      }
    }
  }

  void _onInitialize(InitializePurchaseInvoiceEvent event, Emitter<PurchaseInvoiceState> emit) {
    emit(PurchaseInvoiceLoaded(
      items: [PurchaseInvoiceItem(
        productId: '',
        productName: '',
        qty: 1,
        stkBatch: 1,
        sellPriceAmount: 0,
        purPrice: 0,
        landedPrice: 0,
        storageName: '',
        storageId: 0,
        exchangeRate: 1.0,
        localAmount: 0,
      )],
      payments: [], // Empty payments list for expenses
      paymentMode: PaymentMode.cash,
      cashPayment: 0.0,
      exchangeRate: 1.0,
      fromCurrency: '',
      toCurrency: '',
      supplier: null,
      supplierAccount: null,
      storages: [],
    ));
  }

  void _onReset(ResetPurchaseInvoiceEvent event, Emitter<PurchaseInvoiceState> emit) {
    emit(PurchaseInvoiceLoaded(
      items: [PurchaseInvoiceItem(
        productId: '',
        productName: '',
        qty: 1,
        stkBatch: 1,
        purPrice: 0,
        landedPrice: 0,
        storageName: '',
        sellPriceAmount: 0,
        storageId: 0,
        exchangeRate: 1.0,
        localAmount: 0,
      )],
      payments: [],
      paymentMode: PaymentMode.cash,
      cashPayment: 0.0,
      exchangeRate: 1.0,
      fromCurrency: '',
      toCurrency: '',
      supplier: null,
      supplierAccount: null,
      storages: [],
    ));
  }

  void _onClearSupplierAccount(ClearSupplierAccountEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      emit(current.copyWith(
        supplierAccount: null,
        cashPayment: current.subtotal,
        paymentMode: PaymentMode.cash,
      ));
    }
  }

  void _onSelectSupplierAccount(SelectSupplierAccountEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      // Determine payment mode based on cash payment
      PaymentMode newPaymentMode;
      if (current.cashPayment <= 0) {
        newPaymentMode = PaymentMode.credit;
      } else if (current.cashPayment >= current.subtotal) {
        newPaymentMode = PaymentMode.cash;
      } else {
        newPaymentMode = PaymentMode.mixed;
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
        cashPayment: current.subtotal,
        paymentMode: PaymentMode.cash,
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
      stkBatch: 1,
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
          stkBatch: 1,
          sellPriceAmount: 0,
          qty: 1,
          purPrice: 0,
          storageName: '',
          storageId: 0,
        ));
      }

      emit(current.copyWith(items: updatedItems));
      add(UpdateAllLandedPricesEvent());
    }
  }

  void _onUpdateCashPayment(UpdateCashPaymentEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      double newCashPayment = event.cashPayment;
      PaymentMode newMode;

      if (newCashPayment <= 0) {
        newMode = PaymentMode.credit;
        newCashPayment = 0;
      } else if (newCashPayment >= current.subtotal) {
        newMode = PaymentMode.cash;
        newCashPayment = current.subtotal;
      } else {
        newMode = PaymentMode.mixed;
      }

      emit(current.copyWith(
        cashPayment: newCashPayment,
        paymentMode: newMode,
      ));
    }
  }

  // ==================== PAYMENT HANDLERS (Unified) ====================

  void _onAddPayment(AddPaymentEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      final newPayment = PurchasePaymentRecord(
        accountNumber: 0,
        amount: 0.0,
        currency: current.supplierAccount?.actCurrency ?? current.fromCurrency ?? '',
        exRate: current.exchangeRate ?? 1.0,
        narration: '',
        isExpense: event.isExpense,
      );

      final updatedPayments = List<PurchasePaymentRecord>.from(current.payments)..add(newPayment);
      emit(current.copyWith(payments: updatedPayments));

      if (event.isExpense) {
        add(UpdateAllLandedPricesEvent());
      }
    }
  }

  void _onRemovePayment(RemovePaymentEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final updatedPayments = List<PurchasePaymentRecord>.from(current.payments)
        ..removeAt(event.index);

      emit(current.copyWith(payments: updatedPayments));

      // Check if removed payment was an expense
      if (event.wasExpense) {
        add(UpdateAllLandedPricesEvent());
      }
    }
  }

  void _onUpdatePayment(UpdatePaymentEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;
      final updatedPayments = List<PurchasePaymentRecord>.from(current.payments);

      if (event.index < updatedPayments.length) {
        final existing = updatedPayments[event.index];
        updatedPayments[event.index] = existing.copyWith(
          accountNumber: event.accountNumber ?? existing.accountNumber,
          amount: event.amount ?? existing.amount,
          currency: event.currency ?? existing.currency,
          exRate: event.exRate ?? existing.exRate,
          narration: event.narration,
          isExpense: event.isExpense ?? existing.isExpense,
        );

        emit(current.copyWith(payments: updatedPayments));

        if (event.isExpense == true || existing.isExpense) {
          add(UpdateAllLandedPricesEvent());
        }
      }
    }
  }

  Future<void> _onSaveInvoice(SavePurchaseInvoiceEvent event, Emitter<PurchaseInvoiceState> emit) async {
    if (state is! PurchaseInvoiceLoaded) {
      event.completer.complete('');
      return;
    }

    final current = state as PurchaseInvoiceLoaded;

    // Save current state for error recovery
    final savedState = current.copyWith();

    // Validations (keep existing validations)
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

    if(current.paymentMode == PaymentMode.cash){
      if(current.cashPayment != current.grandTotalLocal || current.cashPayment != current.totalInvoice){
        emit(PurchaseInvoiceError('Cash payment not equal to total invoice amount'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    if (current.paymentMode == PaymentMode.mixed) {
      if (current.cashPayment <= 0) {
        emit(PurchaseInvoiceError('For mixed payment, cash payment must be greater than 0'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
      if (current.cashPayment >= current.subtotal) {
        emit(PurchaseInvoiceError('For mixed payment, cash payment must be less than total amount'));
        emit(savedState);
        event.completer.complete('');
        return;
      }
    }

    // Emit saving state
    emit(PurchaseInvoiceSaving(
      items: current.items,
      payments: current.payments,
      supplier: current.supplier,
      supplierAccount: current.supplierAccount,
      cashPayment: current.cashPayment,
      paymentMode: current.paymentMode,
      storages: current.storages,
    ));

    try {
      // Build records for API
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

      // Build unified payments list for API
      final List<PurchasePaymentRecord> apiPayments = [];

      // Determine the base currency for calculations
      final baseCurrency = current.fromCurrency ?? '';
      final exchangeRate = current.exchangeRate ?? 1.0;

      // Get supplier account currency if available
      final supplierCurrency = current.supplierAccount?.actCurrency ?? baseCurrency;
      final needsConversion = supplierCurrency != baseCurrency;

      // ============ 1. HANDLE EXPENSES (DEBIT expense account) ============
      // Expenses are recorded as debit to expense account (cash is credited separately)
      for (final expense in current.expenses) {
        if (expense.amount > 0 && expense.accountNumber != 0) {
          // DEBIT the expense account (records the expense)
          apiPayments.add(PurchasePaymentRecord(
            accountNumber: expense.accountNumber,
            amount: expense.amount,
            currency: baseCurrency,
            exRate: 1.0,
            narration: expense.narration!.isNotEmpty ? expense.narration : 'Expense: ${expense.accountNumber}',
            isExpense: true,
          ));
        }
      }

      // ============ 2. HANDLE SUPPLIER PAYMENT (Credit/Debit to supplier account) ============
      final supplierPaymentAmount = current.subtotal;

      // Add supplier payment if applicable (credit or mixed payment)
      if (current.paymentMode != PaymentMode.cash && current.supplierAccount != null) {
        double amountToPay = supplierPaymentAmount;

        // If mixed payment, subtract cash payment from supplier amount
        if (current.paymentMode == PaymentMode.mixed) {
          amountToPay = supplierPaymentAmount - current.cashPayment;
        }

        if (amountToPay > 0) {
          // Convert to supplier's currency if needed
          double convertedAmount = amountToPay;
          String paymentCurrency = baseCurrency;
          double paymentExRate = 1.0;

          if (needsConversion && supplierCurrency.isNotEmpty) {
            convertedAmount = amountToPay * exchangeRate;
            paymentCurrency = supplierCurrency;
            paymentExRate = exchangeRate;
          }

          // DEBIT supplier account (records liability/payment)
          apiPayments.add(PurchasePaymentRecord(
            accountNumber: current.supplierAccount!.accNumber!,
            amount: convertedAmount,
            currency: paymentCurrency,
            exRate: paymentExRate,
            narration: 'Supplier payment for invoice',
            isExpense: false,
          ));
        }
      }

      // ============ 3. HANDLE CASH PAYMENT FOR INVOICE ============
      // This is the cash portion that goes to supplier
      if (current.cashPayment > 0) {
        double cashAmount = current.cashPayment;

        // If cash payment is full payment, it's the entire invoice
        if (current.paymentMode == PaymentMode.cash) {
          cashAmount = supplierPaymentAmount;
        }

        if (cashAmount > 0) {
          // Determine cash currency - use selected cash currency or base currency
          final cashCurrency = (current.cashCurrency != null && current.cashCurrency!.isNotEmpty)
              ? current.cashCurrency!
              : baseCurrency;

          // Determine exchange rate for cash payment
          double cashExRate;
          if (cashCurrency != baseCurrency && current.cashExchangeRate > 0) {
            // User selected a different currency for cash payment
            cashExRate = current.cashExchangeRate;
          } else {
            cashExRate = 1.0;
          }

          // Convert base amount to cash currency
          final amountInCashCurrency = cashAmount * cashExRate;

          // CREDIT cash account (positive amount = credit in their API)
          apiPayments.add(PurchasePaymentRecord(
            accountNumber: 10101010, // Cash account
            amount: amountInCashCurrency,
            currency: cashCurrency,
            exRate: cashExRate,
            narration: 'Cash payment to supplier',
            isExpense: false,
          ));
        }
      }

      final xRef = event.xRef ?? 'PUR-${DateTime.now().millisecondsSinceEpoch}';

      final response = await repo.addPurchaseInvoice(
        usrName: event.usrName,
        perID: event.ordPersonal,
        xRef: xRef,
        orderName: "Purchase",
        remark: event.remark,
        records: records,
        payment: apiPayments,
      );

      final message = response['msg']?.toString() ?? 'No response message';

      if (message.toLowerCase().contains('success') || message.toLowerCase().contains('authorized')) {
        String invoiceNumber = response['invoiceNo']?.toString() ??
            response['ordID']?.toString() ??
            'Generated';

        final invoiceData = current.copyWith();

        emit(PurchaseInvoiceSaved(
          true,
          invoiceNumber: invoiceNumber,
          invoiceData: invoiceData,
        ));

        event.completer.complete(invoiceNumber);

        Future.microtask(() {
          if (!emit.isDone) {
            add(ResetPurchaseInvoiceEvent());
          }
        });
      } else {
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
  void _onUpdateAllLandedPrices(UpdateAllLandedPricesEvent event, Emitter<PurchaseInvoiceState> emit) {
    if (state is PurchaseInvoiceLoaded) {
      final current = state as PurchaseInvoiceLoaded;

      // Calculate total expenses from payments where isExpense = true
      final totalExpenses = current.expenses.fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate grand total purchase value (invoice total excluding expenses)
      final grandTotal = current.items.fold(0.0, (sum, item) => sum + item.totalPurchase);

      // Update each item's landed price
      final updatedItems = current.items.map((item) {
        double landedPriceForDisplay = item.purPrice ?? 0.0;

        // Allocate expenses to items based on their proportion of total purchase value
        if (grandTotal > 0 && totalExpenses > 0 && item.totalPurchase > 0) {
          final allocationRatio = item.totalPurchase / grandTotal;
          final allocatedExpense = totalExpenses * allocationRatio;
          // Landed price = purchase price + (allocated expense / quantity)
          landedPriceForDisplay = (item.purPrice ?? 0.0) + (allocatedExpense / item.qty);
        }
        return item.copyWith(landedPrice: landedPriceForDisplay);
      }).toList();

      emit(current.copyWith(items: updatedItems));
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