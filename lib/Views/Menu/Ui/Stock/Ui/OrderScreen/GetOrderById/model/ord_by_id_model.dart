import 'package:equatable/equatable.dart';
import 'dart:convert';

OrderByIdModel orderByIdModelFromMap(String str) => OrderByIdModel.fromMap(json.decode(str));

String orderByIdModelToMap(OrderByIdModel data) => json.encode(data.toMap());

class OrderByIdModel {
  final int? ordId;
  final String? ordName;
  final int? perId;
  final String? personal;
  final String? ordxRef;
  final String? ordTrnRef;
  final int? acc;
  final String? amount;
  final String? trnStateText;
  final DateTime? ordEntryDate;
  final List<OrderRecords>? records;

  OrderByIdModel({
    this.ordId,
    this.ordName,
    this.perId,
    this.personal,
    this.ordxRef,
    this.ordTrnRef,
    this.acc,
    this.amount,
    this.trnStateText,
    this.ordEntryDate,
    this.records,
  });

  OrderByIdModel copyWith({
    int? ordId,
    String? ordName,
    int? perId,
    String? personal,
    String? ordxRef,
    String? ordTrnRef,
    int? acc,
    String? amount,
    String? trnStateText,
    DateTime? ordEntryDate,
    List<OrderRecords>? records,
  }) =>
      OrderByIdModel(
        ordId: ordId ?? this.ordId,
        ordName: ordName ?? this.ordName,
        perId: perId ?? this.perId,
        personal: personal ?? this.personal,
        ordxRef: ordxRef ?? this.ordxRef,
        ordTrnRef: ordTrnRef ?? this.ordTrnRef,
        acc: acc ?? this.acc,
        amount: amount ?? this.amount,
        trnStateText: trnStateText ?? this.trnStateText,
        ordEntryDate: ordEntryDate ?? this.ordEntryDate,
        records: records ?? this.records,
      );

  factory OrderByIdModel.fromMap(Map<String, dynamic> json) => OrderByIdModel(
    ordId: json["ordID"] ?? json["ordId"],
    ordName: json["ordName"],
    perId: json["ordPersonal"] ?? json["ordPersonal"],
    personal: json["ordPersonalName"],
    ordxRef: json["ordxRef"],
    ordTrnRef: json["ordTrnRef"],
    acc: json["account"],
    amount: json["amount"] ?? json["totalBill"]?.toString(), // Notice: totalBill instead of amount
    trnStateText: json["trnStateText"],
    ordEntryDate: json["ordEntryDate"] == null ? null : DateTime.parse(json["ordEntryDate"]),
    records: json["records"] == null ? [] : List<OrderRecords>.from(json["records"]!.map((x) => OrderRecords.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "ordID": ordId,
    "ordName": ordName,
    "ordPersonal": perId,
    "ordPersonalName": personal,
    "ordxRef": ordxRef,
    "ordTrnRef": ordTrnRef,
    "account": acc,
    "amount": amount,
    "trnStateText": trnStateText,
    "ordEntryDate": ordEntryDate?.toIso8601String(),
    "records": records == null ? [] : List<dynamic>.from(records!.map((x) => x.toMap())),
  };
}


class OrderRecords {
  final int? stkId;
  final int? stkOrder;
  final int? stkProduct;
  final String? stkEntryType;
  final int? stkStorage;
  final dynamic stkExpiryDate;
  final String? stkQuantity;
  final String? stkPurPrice;
  final int? stkQtyInBatch;
  final String? stkLandedPurPrice;
  final String? stkDiscount;
  final String? stkSalePrice;

  OrderRecords({
    this.stkId,
    this.stkOrder,
    this.stkProduct,
    this.stkEntryType,
    this.stkStorage,
    this.stkExpiryDate,
    this.stkQuantity,
    this.stkPurPrice,
    this.stkQtyInBatch,
    this.stkLandedPurPrice,
    this.stkDiscount,
    this.stkSalePrice,
  });

  OrderRecords copyWith({
    int? stkId,
    int? stkOrder,
    int? stkProduct,
    String? stkEntryType,
    int? stkStorage,
    dynamic stkExpiryDate,
    String? stkQuantity,
    String? stkPurPrice,
    int? stkQtyInBatch,
    String? stkLandedPurPrice,
    String? stkDiscount,
    String? stkSalePrice,
  }) =>
      OrderRecords(
        stkId: stkId ?? this.stkId,
        stkOrder: stkOrder ?? this.stkOrder,
        stkProduct: stkProduct ?? this.stkProduct,
        stkEntryType: stkEntryType ?? this.stkEntryType,
        stkStorage: stkStorage ?? this.stkStorage,
        stkExpiryDate: stkExpiryDate ?? this.stkExpiryDate,
        stkQuantity: stkQuantity ?? this.stkQuantity,
        stkPurPrice: stkPurPrice ?? this.stkPurPrice,
        stkQtyInBatch: stkQtyInBatch ?? this.stkQtyInBatch,
        stkLandedPurPrice: stkLandedPurPrice ?? this.stkLandedPurPrice,
        stkDiscount: stkDiscount ?? this.stkDiscount,
        stkSalePrice: stkSalePrice ?? this.stkSalePrice,
      );

  factory OrderRecords.fromMap(Map<String, dynamic> json) => OrderRecords(
    stkId: json["stkID"],
    stkOrder: json["stkOrder"],
    stkProduct: json["stkProduct"],
    stkEntryType: json["stkEntryType"],
    stkStorage: json["stkStorage"],
    stkExpiryDate: json["stkExpiryDate"],
    stkQuantity: json["stkQuantity"]?.toString(),
    stkPurPrice: json["stkPurPrice"],
    stkQtyInBatch: json["stkQtyInBatch"],
    stkLandedPurPrice: json["stkLandedPurPrice"],
    stkDiscount: json["stkDiscount"],
    stkSalePrice: json["stkSalePrice"],
  );

  Map<String, dynamic> toMap() => {
    "stkID": stkId,
    "stkOrder": stkOrder,
    "stkProduct": stkProduct,
    "stkEntryType": stkEntryType,
    "stkStorage": stkStorage,
    "stkExpiryDate": stkExpiryDate,
    "stkQuantity": stkQuantity,
    "stkPurPrice": stkPurPrice,
    "stkQtyInBatch": stkQtyInBatch,
    "stkLandedPurPrice": stkLandedPurPrice,
    "stkDiscount": stkDiscount,
    "stkSalePrice": stkSalePrice,
  };
}



enum OrderType { purchase, sale, purchaseReturn, saleReturn }

class GenericOrderModel extends Equatable {
  final int? ordId;
  final String? ordName;
  final int? perId;
  final String? personal;
  final String? ordxRef;
  final String? ordTrnRef;
  final int? acc;
  final double amount;
  final String? trnStateText;
  final DateTime? ordEntryDate;
  final List<GenericOrderItem> records;
  final OrderType orderType;

  const GenericOrderModel({
    this.ordId,
    this.ordName,
    this.perId,
    this.personal,
    this.ordxRef,
    this.ordTrnRef,
    this.acc,
    this.amount = 0.0,
    this.trnStateText,
    this.ordEntryDate,
    required this.records,
    required this.orderType,
  });

  // Add copyWith method
  GenericOrderModel copyWith({
    int? ordId,
    String? ordName,
    int? perId,
    String? personal,
    String? ordxRef,
    String? ordTrnRef,
    int? acc,
    double? amount,
    String? trnStateText,
    DateTime? ordEntryDate,
    List<GenericOrderItem>? records,
    OrderType? orderType,
  }) {
    return GenericOrderModel(
      ordId: ordId ?? this.ordId,
      ordName: ordName ?? this.ordName,
      perId: perId ?? this.perId,
      personal: personal ?? this.personal,
      ordxRef: ordxRef ?? this.ordxRef,
      ordTrnRef: ordTrnRef ?? this.ordTrnRef,
      acc: acc ?? this.acc,
      amount: amount ?? this.amount,
      trnStateText: trnStateText ?? this.trnStateText,
      ordEntryDate: ordEntryDate ?? this.ordEntryDate,
      records: records ?? this.records,
      orderType: orderType ?? this.orderType,
    );
  }

  double get grandTotal {
    return records.fold(0.0, (sum, item) => sum + item.total);
  }

  bool get isEditable => trnStateText?.toLowerCase() == 'pending';

  bool get isCredit => acc != null && acc! > 0;

  // Factory constructor from OrderByIdModel
  factory GenericOrderModel.fromOrderById(OrderByIdModel order, OrderType type) {
    return GenericOrderModel(
      ordId: order.ordId,
      ordName: order.ordName,
      perId: order.perId,
      personal: order.personal,
      ordxRef: order.ordxRef,
      ordTrnRef: order.ordTrnRef,
      acc: order.acc,
      amount: double.tryParse(order.amount ?? "0.0") ?? 0.0,
      trnStateText: order.trnStateText,
      ordEntryDate: order.ordEntryDate,
      records: order.records?.map((record) => GenericOrderItem.fromRecord(record, type)).toList() ?? [],
      orderType: type,
    );
  }

  // Determine order type from ordName
  static OrderType getOrderTypeFromName(String? ordName) {
    final name = ordName?.toLowerCase() ?? '';
    if (name.contains('purchase') && name.contains('return')) return OrderType.purchaseReturn;
    if (name.contains('sale') && name.contains('return')) return OrderType.saleReturn;
    if (name.contains('purchase')) return OrderType.purchase;
    if (name.contains('sale')) return OrderType.sale;
    return OrderType.purchase; // default
  }

  @override
  List<Object?> get props => [
    ordId,
    ordName,
    perId,
    personal,
    ordxRef,
    ordTrnRef,
    acc,
    amount,
    trnStateText,
    ordEntryDate,
    records,
    orderType,
  ];
}

class GenericOrderItem extends Equatable {
  final int? stkId;
  final int? stkOrder;
  final int stkProduct;
  final String? stkEntryType;
  final int stkStorage;
  final DateTime? stkExpiryDate;
  final double quantity;
  final double purPrice;
  final double salePrice;
  final String? productName;
  final String? storageName;
  final OrderType orderType;

  const GenericOrderItem({
    this.stkId,
    this.stkOrder,
    required this.stkProduct,
    this.stkEntryType,
    required this.stkStorage,
    this.stkExpiryDate,
    required this.quantity,
    required this.purPrice,
    required this.salePrice,
    this.productName,
    this.storageName,
    required this.orderType,
  });

  // Get appropriate price based on order type
  double get price {
    switch (orderType) {
      case OrderType.purchase:
      case OrderType.purchaseReturn:
        return purPrice;
      case OrderType.sale:
      case OrderType.saleReturn:
        return salePrice;
    }
  }

  double get total => quantity * price;

  // Determine if this is an IN or OUT transaction
  String get entryType {
    switch (orderType) {
      case OrderType.purchase:
      case OrderType.saleReturn:
        return 'IN';
      case OrderType.sale:
      case OrderType.purchaseReturn:
        return 'OUT';
    }
  }

  factory GenericOrderItem.fromRecord(OrderRecords record, OrderType type) {
    return GenericOrderItem(
      stkId: record.stkId,
      stkOrder: record.stkOrder,
      stkProduct: record.stkProduct ?? 0,
      stkEntryType: record.stkEntryType,
      stkStorage: record.stkStorage ?? 0,
      stkExpiryDate: record.stkExpiryDate,
      quantity: double.tryParse(record.stkQuantity ?? "0.0") ?? 0.0,
      purPrice: double.tryParse(record.stkPurPrice ?? "0.0") ?? 0.0,
      salePrice: double.tryParse(record.stkSalePrice ?? "0.0") ?? 0.0,
      orderType: type,
    );
  }

  GenericOrderItem copyWith({
    int? stkId,
    int? stkOrder,
    int? stkProduct,
    String? stkEntryType,
    int? stkStorage,
    DateTime? stkExpiryDate,
    double? quantity,
    double? purPrice,
    double? salePrice,
    String? productName,
    String? storageName,
    OrderType? orderType,
  }) {
    return GenericOrderItem(
      stkId: stkId ?? this.stkId,
      stkOrder: stkOrder ?? this.stkOrder,
      stkProduct: stkProduct ?? this.stkProduct,
      stkEntryType: stkEntryType ?? this.stkEntryType,
      stkStorage: stkStorage ?? this.stkStorage,
      stkExpiryDate: stkExpiryDate ?? this.stkExpiryDate,
      quantity: quantity ?? this.quantity,
      purPrice: purPrice ?? this.purPrice,
      salePrice: salePrice ?? this.salePrice,
      productName: productName ?? this.productName,
      storageName: storageName ?? this.storageName,
      orderType: orderType ?? this.orderType,
    );
  }

  @override
  List<Object?> get props => [
    stkId,
    stkOrder,
    stkProduct,
    stkEntryType,
    stkStorage,
    stkExpiryDate,
    quantity,
    purPrice,
    salePrice,
    productName,
    storageName,
    orderType,
  ];
}