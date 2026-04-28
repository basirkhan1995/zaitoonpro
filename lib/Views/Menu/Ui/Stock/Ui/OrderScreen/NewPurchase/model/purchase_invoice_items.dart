class PurchaseInvoiceItem {
  final String rowId;
  String productId;
  String productName;
  int qty;
  int stkBatch;
  double? purPrice;
  double? landedPrice;
  double sellPriceAmount;
  int storageId;
  String storageName;
  double? localAmount;
  double? exchangeRate;
  String? unit;

  PurchaseInvoiceItem({
    String? itemId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.stkBatch,
    this.purPrice,
    this.landedPrice,
    required this.sellPriceAmount,
    required this.storageName,
    required this.storageId,
    this.localAmount,
    this.exchangeRate,
    this.unit,
  }) : rowId = itemId ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalQty => qty.toDouble() * stkBatch;

  double get purchasePrice => (purPrice ?? 0);

  double get totalPurchase => totalQty * (purPrice ?? 0);

  // Single item local amount = purchase price * exchange rate
  double get singleLocalAmount {
    final rate = exchangeRate ?? 1.0;
    return (purPrice ?? 0) * rate;
  }

  // Method to update local amount based on current exchange rate
  void updateLocalAmount(double? exchangeRateValue) {
    exchangeRate = exchangeRateValue;
    if (purPrice != null && exchangeRate != null) {
      localAmount = purPrice! * exchangeRate!;
    } else {
      localAmount = null;
    }
  }

  PurchaseInvoiceItem copyWith({
    String? productId,
    String? productName,
    int? qty,
    int? stkBatch,
    double? purPrice,
    double? landedPrice,
    double? sellPriceAmount,
    int? storageId,
    String? storageName,
    double? localAmount,
    double? exchangeRate,
    String? unit,
  }) {
    return PurchaseInvoiceItem(
      itemId: rowId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      stkBatch: stkBatch ?? this.stkBatch,
      purPrice: purPrice ?? this.purPrice,
      landedPrice: landedPrice ?? this.landedPrice,
      sellPriceAmount: sellPriceAmount ?? this.sellPriceAmount,
      storageId: storageId ?? this.storageId,
      storageName: storageName ?? this.storageName,
      localAmount: localAmount ?? this.localAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      unit: unit ?? this.unit,
    );
  }
}

class PurchaseInvoiceRecord {
  final int proID;
  final int stgID;
  final double quantity;
  final double? sellPercentage;
  final int stkQtyInBatch;
  final double? pPrice;
  PurchaseInvoiceRecord({
    required this.proID,
    required this.stgID,
    required this.stkQtyInBatch,
    required this.quantity,
    this.sellPercentage,
    this.pPrice,
  });
  Map<String, dynamic> toJson() => {
    'stkProduct': proID,
    'stkStorage': stgID,
    'stkQuantity': quantity.toString(),
    'stkQtyInBatch': stkQtyInBatch,
    'stkSalePercentage': sellPercentage,
    'stkPurPrice': (pPrice ?? 0.0).toString(),
  };
}

class PurchasePaymentRecord {
  final int accountNumber;
  final double amount;
  final String currency;
  final double exRate;
  final String? narration;
  final bool isExpense;

  PurchasePaymentRecord({
    required this.accountNumber,
    required this.amount,
    required this.currency,
    required this.exRate,
    this.narration,
    this.isExpense = false,
  });

  Map<String, dynamic> toJson() => {
    "account": accountNumber,
    "amount": amount,
    "currency": currency,
    "exRate": exRate,
    "narration": narration,
  };

  PurchasePaymentRecord copyWith({
    int? accountNumber,
    double? amount,
    String? currency,
    double? exRate,
    String? narration,
    bool? isExpense,
  }) {
    return PurchasePaymentRecord(
      accountNumber: accountNumber ?? this.accountNumber,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exRate: exRate ?? this.exRate,
      narration: narration ?? this.narration,
      isExpense: isExpense ?? this.isExpense,
    );
  }
}

class PurExpenseRecord {
  final String rowId;
  final String narration;
  final int account;
  final double amount;
  final String accountName;

  PurExpenseRecord({
    String? rowId,
    required this.narration,
    required this.account,
    required this.amount,
    this.accountName = '',
  }) : rowId = rowId ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'narration': narration,
    'account': account,
    'amount': amount,
  };

  PurExpenseRecord copyWith({
    String? rowId,
    String? narration,
    int? account,
    double? amount,
    String? accountName,
  }) {
    return PurExpenseRecord(
      rowId: rowId ?? this.rowId,
      narration: narration ?? this.narration,
      account: account ?? this.account,
      amount: amount ?? this.amount,
      accountName: accountName ?? this.accountName,
    );
  }
}
