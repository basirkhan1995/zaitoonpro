
class SaleInvoiceItem {
  final String rowId;
  String productId;
  String productName;
  int qty;
  int? batch;
  double? discount;
  double? purPrice;
  double? salePrice;
  double? localAmount;
  int storageId;
  String storageName;
  double? exchangeRate;

  SaleInvoiceItem({
    String? itemId,
    required this.productId,
    required this.productName,
    required this.qty,
    this.batch,
    this.discount,
    this.purPrice,
    this.salePrice,
    this.localAmount,
    required this.storageName,
    required this.storageId,
    this.exchangeRate,
  }) : rowId = itemId ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalPurchase => qty * (purPrice ?? 0);
  double get totalSale => qty * (salePrice ?? 0);

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

}
class SaleInvoiceRecord {
  final int proID;
  final int stgID;
  final double quantity;
  final double? batch;
  final double? discount;
  final double? pPrice;
  final double? sPrice;

  SaleInvoiceRecord({
    required this.proID,
    required this.stgID,
    required this.quantity,
    this.batch,
    this.discount,
    this.pPrice,
    this.sPrice,
  });

  Map<String, dynamic> toJson() => {
    'stkProduct': proID,
    'stkStorage': stgID,
    'stkQuantity': quantity,
    'pcs':batch,
    'discount':discount,
    'stkPurPrice': pPrice,
    'stkSalePrice': sPrice,
  };
}