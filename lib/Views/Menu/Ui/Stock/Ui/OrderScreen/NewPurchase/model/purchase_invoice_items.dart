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
  }) : rowId = itemId ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalQty => qty.toDouble() * stkBatch;

  double get totalPurchase => totalQty * (purPrice ?? 0);

  double get totalLocalAmount {
    final rate = exchangeRate ?? 1.0;
    return totalPurchase * rate;
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
    'stkSalePrice': "0.0000",
    'stkDiscount': "0.0000"
  };
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