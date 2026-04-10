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
  final List<PurExpenseRecord> expenses;
  final AccountsModel? supplierAccount;
  final IndividualsModel? supplier;
  final double payment;
  final PaymentMode paymentMode;
  final List<StorageModel>? storages;

  // New fields for exchange rate handling
  final double? exchangeRate;
  final String? fromCurrency;
  final String? toCurrency;

  const PurchaseInvoiceLoaded({
    required this.items,
    required this.expenses,
    this.supplier,
    this.supplierAccount,
    required this.payment,
    this.paymentMode = PaymentMode.cash,
    this.storages,
    this.exchangeRate,
    this.fromCurrency,
    this.toCurrency,
  });

  double get grandTotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPurchase);
  }

  // Total local amount (in account currency)
  double get totalLocalAmount {
    if (exchangeRate == null || exchangeRate == 0) return grandTotal;
    return items.fold(0.0, (sum, item) => sum + (item.localAmount ?? 0));
  }

  double get cashPayment {
    if (paymentMode == PaymentMode.cash) {
      return grandTotal;
    } else if (paymentMode == PaymentMode.mixed) {
      return payment;
    }
    return 0.0;
  }

  double get cashPaymentLocal {
    if (exchangeRate == null || exchangeRate == 0) return cashPayment;
    return cashPayment * exchangeRate!;
  }

  double get creditAmount {
    if (paymentMode == PaymentMode.credit) {
      return grandTotal;
    } else if (paymentMode == PaymentMode.mixed) {
      return grandTotal - payment;
    }
    return 0.0;
  }

  double get creditAmountLocal {
    if (exchangeRate == null || exchangeRate == 0) return creditAmount;
    return creditAmount * exchangeRate!;
  }

  double get currentBalance {
    if (supplierAccount != null) {
      return double.tryParse(supplierAccount!.accAvailBalance ?? "0.0") ?? 0.0;
    }
    return 0.0;
  }

  double get newBalance {
    return currentBalance + creditAmountLocal; // Use local amount for balance
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
      if (payment <= 0 || payment >= grandTotal) return false;
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
    List<PurExpenseRecord>? expenses,
    AccountsModel? supplierAccount,
    IndividualsModel? supplier,
    double? payment,
    PaymentMode? paymentMode,
    List<StorageModel>? storages,
    double? exchangeRate,
    String? fromCurrency,
    String? toCurrency,
  }) {
    return PurchaseInvoiceLoaded(
      items: items ?? this.items,
      expenses: expenses ?? this.expenses,
      supplier: supplier ?? this.supplier,
      supplierAccount: supplierAccount ?? this.supplierAccount,
      payment: payment ?? this.payment,
      paymentMode: paymentMode ?? this.paymentMode,
      storages: storages ?? this.storages,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
    );
  }

  @override
  List<Object?> get props => [
    items,
    expenses,
    supplier,
    supplierAccount,
    payment,
    paymentMode,
    storages,
    exchangeRate,
    fromCurrency,
    toCurrency,
  ];
}

class PurchaseInvoiceSaving extends PurchaseInvoiceLoaded {
  const PurchaseInvoiceSaving({
    required super.items,
    required super.expenses,
    super.supplier,
    super.supplierAccount,
    required super.payment,
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
  List<Object?> get props => [success, invoiceNumber, invoiceData ?? const []];
}