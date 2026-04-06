class PurchaseInvoiceItem {
  final String rowId;
  String productId;
  String productName;
  int qty;
  int stkBatch;
  double? purPrice;
  int storageId;
  String storageName;

  PurchaseInvoiceItem({
    String? itemId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.stkBatch,
    this.purPrice,
    required this.storageName,
    required this.storageId,
  }) : rowId = itemId ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalPurchase => qty * (purPrice ?? 0);
}

class PurchaseInvoiceRecord {
  final int proID;
  final int stgID;
  final double quantity;
  final int stkQtyPerUnit;
  final double? pPrice;

  PurchaseInvoiceRecord({
    required this.proID,
    required this.stgID,
    required this.stkQtyPerUnit,
    required this.quantity,
    this.pPrice,
  });

  Map<String, dynamic> toJson() => {
    'stkProduct': proID,
    'stkStorage': stgID,
    'stkQuantity': quantity.toString(),
    'stkQtyPerUnit': stkQtyPerUnit,
    'stkPurPrice': (pPrice ?? 0.0).toString(),
    'stkSalePrice': "0.0000",
  };
}