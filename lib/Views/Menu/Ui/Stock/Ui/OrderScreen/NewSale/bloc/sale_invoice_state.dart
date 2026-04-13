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
  final AccountsModel? customerAccount;
  final IndividualsModel? customer;
  final double payment;
  final PaymentMode paymentMode;
  final List<StorageModel>? storages;
  final double generalDiscount;
  final double exchangeRate; // Exchange rate from base to account currency
  final DiscountType generalDiscountType;
  final String? fromCurrency; // Base currency
  final String? toCurrency; // Account currency
  final double extraCharges;
  const SaleInvoiceLoaded({
    required this.items,
    this.customer,
    this.customerAccount,
    required this.payment,
    this.paymentMode = PaymentMode.cash,
    this.storages,
    this.generalDiscount = 0.0,
    this.exchangeRate = 1.0,
    this.extraCharges = 0.0,
    this.generalDiscountType = DiscountType.percentage,
    this.fromCurrency,
    this.toCurrency,
  });


  // Helper to check if currency conversion is needed
  bool get needsExchangeRate {
    if (customerAccount == null) return false;
    final accountCurrency = customerAccount!.actCurrency ?? '';
    final baseCurr = fromCurrency ?? '';
    return accountCurrency.isNotEmpty &&
        baseCurr.isNotEmpty &&
        accountCurrency != baseCurr;
  }
  double get grandTotal => totalAfterItemDiscount - generalDiscountAmount + extraCharges;
  // Total local amount for all items (in account currency)
  double get totalLocalAmount {
    if (!needsExchangeRate) return grandTotal;
    return items.fold(0.0, (sum, item) => sum + item.totalLocalAmount) + (extraCharges * exchangeRate);
  }

  // Subtotal before any discounts (in base currency)
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + (item.qty * (item.salePrice ?? 0)));
  }

  // Total item discount amount (in base currency)
  double get totalItemDiscount {
    return items.fold(0.0, (sum, item) => sum + item.discountAmount);
  }

  // Total after item discounts (in base currency)
  double get totalAfterItemDiscount {
    return items.fold(0.0, (sum, item) => sum + item.totalSale);
  }

  // General discount amount (in base currency)
  double get generalDiscountAmount {
    if (generalDiscount <= 0) return 0;
    if (generalDiscountType == DiscountType.percentage) {
      return totalAfterItemDiscount * (generalDiscount / 100);
    } else {
      return generalDiscount;
    }
  }

  // Grand total in local currency (for display)
  double get grandTotalLocal {
    if (!needsExchangeRate) return grandTotal;
    return grandTotal * exchangeRate;
  }


  double get totalPurchaseCost {
    return items.fold(0.0, (sum, item) => sum + item.totalPurchase);
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

  double get cashPayment {
    if (paymentMode == PaymentMode.cash) {
      return grandTotal;
    } else if (paymentMode == PaymentMode.mixed) {
      return payment;
    }
    return 0.0;
  }

  double get creditAmount {
    if (paymentMode == PaymentMode.credit) {
      return grandTotal;
    } else if (paymentMode == PaymentMode.mixed) {
      return grandTotal - payment;
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
    return currentBalance + creditAmount;
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
      if (payment <= 0 || payment >= grandTotal) return false;
    }

    // Validate general discount
    if (generalDiscountType == DiscountType.amount && generalDiscount > grandTotal + generalDiscountAmount) {
      return false;
    }

    return true;
  }

  SaleInvoiceLoaded copyWith({
    List<SaleInvoiceItem>? items,
    AccountsModel? customerAccount,
    IndividualsModel? customer,
    double? payment,
    PaymentMode? paymentMode,
    List<StorageModel>? storages,
    double? generalDiscount,
    DiscountType? generalDiscountType,
    double? exchangeRate,
    String? fromCurrency,
    String? toCurrency,
    double? extraCharges,
  }) {
    return SaleInvoiceLoaded(
      items: items ?? this.items,
      customer: customer ?? this.customer,
      customerAccount: customerAccount ?? this.customerAccount,
      payment: payment ?? this.payment,
      paymentMode: paymentMode ?? this.paymentMode,
      storages: storages ?? this.storages,
      generalDiscount: generalDiscount ?? this.generalDiscount,
      generalDiscountType: generalDiscountType ?? this.generalDiscountType,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      extraCharges: extraCharges ?? this.extraCharges,
    );
  }

  @override
  List<Object?> get props => [
    items,
    customer,
    customerAccount,
    payment,
    paymentMode,
    storages,
    generalDiscount,
    generalDiscountType,
    fromCurrency,
    toCurrency,
    extraCharges,
  ];
}
class SaleInvoiceSaving extends SaleInvoiceLoaded {
  const SaleInvoiceSaving({
    required super.items,
    super.customer,
    super.customerAccount,
    required super.payment,
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
  List<Object?> get props => [success, invoiceNumber, invoiceData ?? const []];
}