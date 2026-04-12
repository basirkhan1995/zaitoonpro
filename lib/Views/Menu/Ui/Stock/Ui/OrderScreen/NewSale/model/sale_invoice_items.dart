
// Update SaleInvoiceItem class

enum DiscountType { percentage, amount }

class SaleInvoiceItem {
  final String rowId;
  String productId;
  String productName;
  int qty;
  int? batch;
  double? discount;
  DiscountType discountType; // New field
  double? purPrice;
  double? salePrice;
  double? localAmount;
  int storageId;
  String storageName;
  double? exchangeRate;
  String? unit; // New field for unit

  SaleInvoiceItem({
    String? itemId,
    required this.productId,
    required this.productName,
    required this.qty,
    this.batch,
    this.discount,
    this.discountType = DiscountType.percentage, // Default to percentage
    this.purPrice,
    this.salePrice,
    this.localAmount,
    required this.storageName,
    required this.storageId,
    this.exchangeRate,
    this.unit,
  }) : rowId = itemId ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalPurchase => qty * (purPrice ?? 0);

  double get totalSale {
    double subtotal = qty * (salePrice ?? 0);

    if (discount != null && discount! > 0) {
      if (discountType == DiscountType.percentage) {
        // Percentage discount
        subtotal = subtotal * (1 - discount! / 100);
      } else {
        // Amount discount
        subtotal = subtotal - discount!;
      }
    }

    return subtotal > 0 ? subtotal : 0;
  }

  // Get discount amount for display
  double get discountAmount {
    double subtotal = qty * (salePrice ?? 0);

    if (discount != null && discount! > 0) {
      if (discountType == DiscountType.percentage) {
        return subtotal * (discount! / 100);
      } else {
        return discount!;
      }
    }
    return 0;
  }

  double get singleLocalAmount {
    final rate = exchangeRate ?? 1.0;
    return (salePrice ?? 0) * rate;
  }

  void updateLocalAmount(double? exchangeRateValue) {
    exchangeRate = exchangeRateValue;
    if (salePrice != null && exchangeRate != null) {
      localAmount = salePrice! * exchangeRate!;
    } else {
      localAmount = null;
    }
  }

  SaleInvoiceItem copyWith({
    String? productId,
    String? productName,
    int? qty,
    int? batch,
    double? discount,
    DiscountType? discountType,
    double? purPrice,
    double? salePrice,
    double? localAmount,
    int? storageId,
    String? storageName,
    double? exchangeRate,
    String? unit,
  }) {
    return SaleInvoiceItem(
      itemId: rowId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      batch: batch ?? this.batch,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      purPrice: purPrice ?? this.purPrice,
      salePrice: salePrice ?? this.salePrice,
      localAmount: localAmount ?? this.localAmount,
      storageId: storageId ?? this.storageId,
      storageName: storageName ?? this.storageName,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      unit: unit ?? this.unit,
    );
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