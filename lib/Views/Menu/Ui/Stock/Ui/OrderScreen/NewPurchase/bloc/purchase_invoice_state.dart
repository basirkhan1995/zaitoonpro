part of 'purchase_invoice_bloc.dart';

enum PaymentMode { cash, credit, mixed }

abstract class PurchaseInvoiceState extends Equatable {
  const PurchaseInvoiceState();
}

class PurchaseInvoiceInitial extends PurchaseInvoiceState {
  @override
  List<Object> get props => [];
}

class PurchaseInvoiceError extends PurchaseInvoiceState {
  final String message;
  const PurchaseInvoiceError(this.message);
  @override
  List<Object> get props => [message];
}

class PurchaseInvoiceLoaded extends PurchaseInvoiceState {
  final List<PurchaseInvoiceItem> items;
  final List<PurchasePaymentRecord> payments;
  final AccountsModel? supplierAccount;
  final IndividualsModel? supplier;
  final PaymentMode paymentMode;
  final List<StorageModel>? storages;
  final double? exchangeRate;
  final String? fromCurrency;
  final String? toCurrency;
  final double cashPayment;
  final String? cashCurrency;
  final double cashExchangeRate;
  final String? xRef;
  final String? remark;
  final int? orderId;

  const PurchaseInvoiceLoaded({
    required this.items,
    required this.payments,
    this.supplier,
    this.supplierAccount,
    this.paymentMode = PaymentMode.cash,
    this.storages,
    this.exchangeRate = 1.0,
    this.fromCurrency,
    this.toCurrency,
    this.cashPayment = 0.0,
    this.cashCurrency,
    this.cashExchangeRate = 1.0,
    this.xRef,
    this.remark,
    this.orderId
  });

  List<PurchasePaymentRecord> get expenses =>
      payments.where((p) => p.isExpense).toList();

  PurchasePaymentRecord? get supplierPayment =>
      payments.where((p) => !p.isExpense).isEmpty
          ? null
          : payments.where((p) => !p.isExpense).first;

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPurchase);
  }
  double get grandTotalLocal {
    if (!needsExchangeRate) return subtotal;
    return subtotal * safeExchangeRate;
  }


  double get supplierAccountPayment {
    if (supplierAccount == null) return 0.0;

    // Calculate amount to be paid to supplier account
    if (paymentMode == PaymentMode.credit) {
      return subtotal; // Full amount to supplier
    } else if (paymentMode == PaymentMode.mixed) {
      return subtotal - cashPayment; // Remaining after cash payment
    } else if (paymentMode == PaymentMode.cash) {
      return 0.0; // No supplier account payment in cash mode
    }
    return 0.0;
  }

  double get totalExpenses {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get totalWithExpenses {
    return subtotal + totalExpenses;
  }
  bool get isExchangeRateLoading => exchangeRate != null && exchangeRate! < 0;

  double get creditAmount {
    if (paymentMode == PaymentMode.credit) {
      return totalInvoice;
    } else if (paymentMode == PaymentMode.mixed) {
      return totalInvoice - cashPayment;
    }
    return 0.0;
  }

  double get creditAmountLocal {
    if (exchangeRate == null || exchangeRate == 0) return creditAmount;
    return creditAmount * exchangeRate!;
  }

  double get cashPaymentLocal {
    if (exchangeRate == null || exchangeRate == 0) return cashPayment;
    return cashPayment * exchangeRate!;
  }

  // NEW: Get cash amount in selected cash currency
  double get cashPaymentInCashCurrency {
    if (needsCashConversion && cashExchangeRate > 0) {
      return cashPayment * cashExchangeRate;
    }
    return cashPayment;
  }

  double get totalLocalAmount {
    if (exchangeRate == null || exchangeRate == 1.0) return totalWithExpenses;
    return totalWithExpenses * exchangeRate!;
  }

  double get currentBalance {
    if (supplierAccount != null) {
      return double.tryParse(supplierAccount!.accAvailBalance ?? "0.0") ?? 0.0;
    }
    return 0.0;
  }

  double get newBalance {
    return currentBalance + creditAmountLocal;
  }

  double get safeExchangeRate {
    if (exchangeRate == null || exchangeRate! <= 0) return 1.0;
    return exchangeRate!;
  }

  bool get isFormValid {
    if (supplier == null) return false;
    if (paymentMode != PaymentMode.cash && supplierAccount == null) return false;
    if (items.isEmpty) return false;

    for (var item in items) {
      if (item.productId.isEmpty ||
          item.productName.isEmpty ||
          item.storageId == 0 ||
          item.storageName.isEmpty ||
          item.purPrice == null ||
          item.purPrice! <= 0 ||
          item.qty <= 0) {
        return false;
      }
    }

    if (paymentMode == PaymentMode.mixed) {
      if (cashPayment <= 0 || cashPayment >= totalWithExpenses) return false;
    }

    return true;
  }

  bool get needsExchangeRate {
    if (supplierAccount == null) return false;
    final accountCurrency = supplierAccount!.actCurrency ?? '';
    final baseCurrency = fromCurrency ?? '';
    return accountCurrency.isNotEmpty &&
        baseCurrency.isNotEmpty &&
        accountCurrency != baseCurrency;
  }

  // NEW: Check if cash currency is different from base currency
  bool get needsCashConversion {
    if (cashCurrency == null || cashCurrency!.isEmpty) return false;
    final baseCurr = fromCurrency ?? '';
    return baseCurr.isNotEmpty && cashCurrency != baseCurr;
  }

// Total invoice including expenses
  double get totalInvoice {
    return subtotal + totalExpenses;
  }




  PurchaseInvoiceLoaded copyWith({
    List<PurchaseInvoiceItem>? items,
    List<PurchasePaymentRecord>? payments,
    AccountsModel? supplierAccount,
    IndividualsModel? supplier,
    PaymentMode? paymentMode,
    List<StorageModel>? storages,
    double? exchangeRate,
    String? fromCurrency,
    String? toCurrency,
    double? cashPayment,
    String? cashCurrency,
    double? cashExchangeRate,
    String? xRef,
    String? remark,
    int? orderId,
  }) {
    return PurchaseInvoiceLoaded(
      items: items ?? this.items,
      payments: payments ?? this.payments,
      supplier: supplier ?? this.supplier,
      supplierAccount: supplierAccount ?? this.supplierAccount,
      paymentMode: paymentMode ?? this.paymentMode,
      storages: storages ?? this.storages,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      cashPayment: cashPayment ?? this.cashPayment,
      cashCurrency: cashCurrency ?? this.cashCurrency,
      cashExchangeRate: cashExchangeRate ?? this.cashExchangeRate,
      xRef: xRef ?? this.xRef,
      remark: remark ?? this.remark,
      orderId: orderId ?? this.orderId

    );
  }

  @override
  List<Object?> get props => [
    items,
    payments,
    supplier,
    supplierAccount,
    paymentMode,
    storages,
    exchangeRate,
    fromCurrency,
    toCurrency,
    cashPayment,
    cashCurrency,
    cashExchangeRate,
    xRef,
    remark,
    orderId,
  ];
}

class PurchaseInvoiceSaving extends PurchaseInvoiceLoaded {
  const PurchaseInvoiceSaving({
    required super.items,
    required super.payments,
    super.supplier,
    super.supplierAccount,
    required super.cashPayment,
    super.paymentMode,
    super.storages,
  });
}

class PurchaseInvoiceSaved extends PurchaseInvoiceState {
  final bool success;
  final String? invoiceNumber;
  final PurchaseInvoiceLoaded? invoiceData;
  const PurchaseInvoiceSaved(this.success, {this.invoiceNumber, this.invoiceData});
  @override
  List<Object?> get props => [success, invoiceNumber, invoiceData];
}

class PurchaseInvoiceLoading extends PurchaseInvoiceState {
  @override
  List<Object> get props => [];
}