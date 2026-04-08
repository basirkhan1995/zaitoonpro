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
  double allocatedExpense; // New field for per-item expense allocation

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
    this.allocatedExpense = 0.0, // Default to 0
  }) : rowId = itemId ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalPurchase => qty * (purPrice ?? 0);
  double get totalLandedCost => qty * (landedPrice ?? 0);
  double get totalQty => qty.toDouble() * stkBatch;

  // Calculate landed price per unit
  void calculateLandedPrice(double totalExpenses, double grandTotal) {
    if (grandTotal > 0 && totalExpenses > 0) {
      // Allocate expense proportionally based on purchase value
      final allocationRatio = totalPurchase / grandTotal;
      allocatedExpense = totalExpenses * allocationRatio;
      landedPrice = (purPrice ?? 0) + (allocatedExpense / qty);
    } else {
      landedPrice = purPrice;
    }
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
  final String narration;
  final int account;
  final double amount;

  PurExpenseRecord({
    required this.narration,
    required this.account,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'narration': narration,
    'account': account,
    'amount': amount,
  };
}