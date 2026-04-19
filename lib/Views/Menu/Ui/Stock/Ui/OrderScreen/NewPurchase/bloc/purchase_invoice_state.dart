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

  const PurchaseInvoiceLoaded({
    required this.items,
    required this.payments,
    this.supplier,
    this.supplierAccount,
    this.paymentMode = PaymentMode.cash,
    this.storages,
    this.exchangeRate,
    this.fromCurrency,
    this.toCurrency,
    this.cashPayment = 0.0,
  });

  List<PurchasePaymentRecord> get expenses =>
      payments.where((p) => p.isExpense).toList();

  PurchasePaymentRecord? get supplierPayment =>
      payments.where((p) => !p.isExpense).isEmpty
          ? null
          : payments.where((p) => !p.isExpense).first;

  double get grandTotal {
    // This should be invoice total ONLY (product purchases, excluding expenses)
    return items.fold(0.0, (sum, item) => sum + item.totalPurchase);
  }

  double get totalExpenses {
    // This is for landed price calculation only
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get totalWithExpenses {
    // This is total cost including expenses (for reporting only)
    return grandTotal + totalExpenses;
  }

  double get creditAmount {
    // Credit should only be for the invoice amount (grandTotal), NOT including expenses
    if (paymentMode == PaymentMode.credit) {
      return grandTotal; // Changed: removed totalWithExpenses
    } else if (paymentMode == PaymentMode.mixed) {
      return grandTotal - cashPayment; // Changed: removed totalWithExpenses
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