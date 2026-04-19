part of 'sale_invoice_bloc.dart';

enum PaymentMode { cash, credit, mixed }

abstract class SaleInvoiceState extends Equatable {
  const SaleInvoiceState();
}

class SaleInvoiceInitial extends SaleInvoiceState {
  @override
  List<Object> get props => [];
}

class SaleInvoiceError extends SaleInvoiceState {
  final String message;
  const SaleInvoiceError(this.message);
  @override
  List<Object> get props => [message];
}

class SaleInvoiceLoaded extends SaleInvoiceState {
  final List<SaleInvoiceItem> items;
  final List<SalePaymentRecord> payments;
  final AccountsModel? customerAccount;
  final IndividualsModel? customer;
  final PaymentMode paymentMode;
  final List<StorageModel>? storages;
  final double generalDiscount;
  final double? exchangeRate;
  final DiscountType generalDiscountType;
  final String? fromCurrency;
  final String? toCurrency;
  final double extraCharges;
  final double cashPayment;
  final String? cashCurrency;
  final double cashExchangeRate;

  const SaleInvoiceLoaded({
    required this.items,
    required this.payments,
    this.customer,
    this.customerAccount,
    this.paymentMode = PaymentMode.cash,
    this.storages,
    this.generalDiscount = 0.0,
    this.exchangeRate,
    this.extraCharges = 0.0,
    this.generalDiscountType = DiscountType.percentage,
    this.fromCurrency,
    this.toCurrency,
    this.cashPayment = 0.0,
    this.cashCurrency,
    this.cashExchangeRate = 1.0,
  });

  bool get needsExchangeRate {
    if (customerAccount == null) return false;
    final accountCurrency = customerAccount!.actCurrency ?? '';
    final baseCurr = fromCurrency ?? '';
    return accountCurrency.isNotEmpty &&
        baseCurr.isNotEmpty &&
        accountCurrency != baseCurr;
  }

  bool get isExchangeRateLoading => exchangeRate != null && exchangeRate! < 0;

  double get safeExchangeRate {
    if (exchangeRate == null || exchangeRate! <= 0) return 1.0;
    return exchangeRate!;
  }

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + (item.effectiveQty * (item.salePrice ?? 0)));
  }
  double get totalItemDiscount {
    return items.fold(0.0, (sum, item) => sum + item.discountAmount);
  }

  double get totalAfterItemDiscount {
    return items.fold(0.0, (sum, item) => sum + item.totalSale);
  }

  double get totalPurchaseCost {
    return items.fold(0.0, (sum, item) => sum + (item.effectiveQty * (item.purPrice ?? 0)));
  }

  double get generalDiscountAmount {
    if (generalDiscount <= 0) return 0;
    if (generalDiscountType == DiscountType.percentage) {
      return totalAfterItemDiscount * (generalDiscount / 100);
    } else {
      return generalDiscount;
    }
  }

  double get grandTotal => totalAfterItemDiscount - generalDiscountAmount + extraCharges;

  double get grandTotalLocal {
    if (!needsExchangeRate) return grandTotal;
    return grandTotal * safeExchangeRate;
  }

  double get totalLocalAmount {
    if (!needsExchangeRate) return grandTotal;
    return grandTotal * safeExchangeRate;
  }

  double get cashPaymentLocal {
    if (!needsExchangeRate) return cashPayment;
    return cashPayment * safeExchangeRate;
  }

  double get creditAmountLocal {
    if (!needsExchangeRate) return creditAmount;
    return creditAmount * safeExchangeRate;
  }

  double get totalProfit {
    return grandTotal - totalPurchaseCost;
  }

  double get profitPercentage {
    if (totalPurchaseCost > 0) {
      return (totalProfit / totalPurchaseCost) * 100;
    }
    return 0.0;
  }

  double get creditAmount {
    if (paymentMode == PaymentMode.credit) {
      return grandTotal;
    } else if (paymentMode == PaymentMode.mixed) {
      return grandTotal - cashPayment;
    }
    return 0.0;
  }

  double get currentBalance {
    if (customerAccount != null) {
      return double.tryParse(customerAccount!.accAvailBalance ?? "0.0") ?? 0.0;
    }
    return 0.0;
  }

  double get newBalance {
    return currentBalance - creditAmountLocal;
  }

  bool get isFormValid {
    if (customer == null) return false;
    if (paymentMode != PaymentMode.cash && customerAccount == null) return false;
    if (items.isEmpty) return false;

    for (var item in items) {
      if (item.productId.isEmpty ||
          item.productName.isEmpty ||
          item.storageId == 0 ||
          item.storageName.isEmpty ||
          item.salePrice == null ||
          item.salePrice! <= 0 ||
          item.qty <= 0) {
        return false;
      }
    }

    if (paymentMode == PaymentMode.mixed) {
      if (cashPayment <= 0 || cashPayment >= grandTotal) return false;
    }

    if (generalDiscountType == DiscountType.amount && generalDiscount > grandTotal + generalDiscountAmount) {
      return false;
    }

    return true;
  }

  SaleInvoiceLoaded copyWith({
    List<SaleInvoiceItem>? items,
    List<SalePaymentRecord>? payments,
    AccountsModel? customerAccount,
    IndividualsModel? customer,
    PaymentMode? paymentMode,
    List<StorageModel>? storages,
    double? generalDiscount,
    DiscountType? generalDiscountType,
    double? exchangeRate,
    String? fromCurrency,
    String? toCurrency,
    double? extraCharges,
    double? cashPayment,
    String? cashCurrency,
    double? cashExchangeRate,
  }) {
    return SaleInvoiceLoaded(
      items: items ?? this.items,
      payments: payments ?? this.payments,
      customer: customer ?? this.customer,
      customerAccount: customerAccount ?? this.customerAccount,
      paymentMode: paymentMode ?? this.paymentMode,
      storages: storages ?? this.storages,
      generalDiscount: generalDiscount ?? this.generalDiscount,
      generalDiscountType: generalDiscountType ?? this.generalDiscountType,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      extraCharges: extraCharges ?? this.extraCharges,
      cashPayment: cashPayment ?? this.cashPayment,
      cashCurrency: cashCurrency ?? this.cashCurrency,
      cashExchangeRate: cashExchangeRate ?? this.cashExchangeRate,
    );
  }

  @override
  List<Object?> get props => [
    items, payments, customer, customerAccount, paymentMode, storages,
    generalDiscount, generalDiscountType, exchangeRate, fromCurrency,
    toCurrency, extraCharges, cashPayment, cashCurrency, cashExchangeRate,
  ];
}

class SaleInvoiceSaving extends SaleInvoiceLoaded {
  const SaleInvoiceSaving({
    required super.items,
    required super.payments,
    super.customer,
    super.customerAccount,
    required super.cashPayment,
    super.paymentMode,
    super.storages,
  });
}

class SaleInvoiceSaved extends SaleInvoiceState {
  final bool success;
  final String? invoiceNumber;
  final SaleInvoiceLoaded? invoiceData;
  const SaleInvoiceSaved(this.success, {this.invoiceNumber, this.invoiceData});
  @override
  List<Object?> get props => [success, invoiceNumber, invoiceData];
}