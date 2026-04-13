part of 'sale_invoice_bloc.dart';

abstract class SaleInvoiceEvent extends Equatable {
  const SaleInvoiceEvent();

  @override
  List<Object?> get props => [];
}

class InitializeSaleInvoiceEvent extends SaleInvoiceEvent {}

class SelectCustomerEvent extends SaleInvoiceEvent {
  final IndividualsModel supplier;
  const SelectCustomerEvent(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class SelectCustomerAccountEvent extends SaleInvoiceEvent {
  final AccountsModel customer;
  const SelectCustomerAccountEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class ClearCustomerEvent extends SaleInvoiceEvent {}

class AddNewSaleItemEvent extends SaleInvoiceEvent {}

class RemoveSaleItemEvent extends SaleInvoiceEvent {
  final String rowId;
  const RemoveSaleItemEvent(this.rowId);

  @override
  List<Object?> get props => [rowId];
}

class UpdateSaleItemEvent extends SaleInvoiceEvent {
  final String rowId;
  final String? productId;
  final String? productName;
  final int? qty;
  final int? batch;
  final double? localeAmount;
  final double? exchangeRate;
  final double? discount;
  final double? purPrice;
  final double? salePrice;
  final int? storageId;
  final String? storageName;

  const UpdateSaleItemEvent({
    required this.rowId,
    this.productId,
    this.productName,
    this.qty,
    this.discount,
    this.batch,
    this.localeAmount,
    this.exchangeRate,
    this.purPrice,
    this.salePrice,
    this.storageId,
    this.storageName,
  });

  @override
  List<Object?> get props => [
    rowId,
    productId,
    productName,
    qty,
    discount,
    batch,
    localeAmount,
    exchangeRate,
    purPrice,
    salePrice,
    storageId,
    storageName,
  ];
}
class UpdateExchangeRateEvent extends SaleInvoiceEvent {
  final double rate;
  final String fromCurrency;
  final String toCurrency;

  const UpdateExchangeRateEvent({
    required this.rate,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [rate, fromCurrency, toCurrency];
}

class UpdateItemLocalAmountEvent extends SaleInvoiceEvent {
  final String rowId;

  const UpdateItemLocalAmountEvent(this.rowId);

  @override
  List<Object?> get props => [rowId];
}

class UpdateAllLocalAmountsEvent extends SaleInvoiceEvent {
  const UpdateAllLocalAmountsEvent();
}

class UpdateSaleReceivePaymentEvent extends SaleInvoiceEvent {
  final double payment;
  final bool isCreditAmount;

  const UpdateSaleReceivePaymentEvent(this.payment, {this.isCreditAmount = false});

  @override
  List<Object?> get props => [payment, isCreditAmount];
}

class ResetSaleInvoiceEvent extends SaleInvoiceEvent {}

class SaveSaleInvoiceEvent extends SaleInvoiceEvent {
  final String usrName;
  final String orderName;
  final int ordPersonal;
  final String? xRef;
  final List<SaleInvoiceItem> items;
  final Completer<String> completer;

  const SaveSaleInvoiceEvent({
    required this.usrName,
    required this.ordPersonal,
    required this.orderName,
    this.xRef,
    required this.items,
    required this.completer,
  });

  @override
  List<Object?> get props => [usrName, ordPersonal, orderName, xRef, items, completer];
}
class ClearCustomerAccountEvent extends SaleInvoiceEvent {
  const ClearCustomerAccountEvent();
  @override
  List<Object?> get props => [];
}
class LoadSaleStoragesEvent extends SaleInvoiceEvent {
  final int productId;
  const LoadSaleStoragesEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

// Add these events to sale_invoice_event.dart

class UpdateItemDiscountTypeEvent extends SaleInvoiceEvent {
  final String rowId;
  final DiscountType discountType; // 'percentage' or 'amount'

  const UpdateItemDiscountTypeEvent({
    required this.rowId,
    required this.discountType,
  });

  @override
  List<Object?> get props => [rowId, discountType];
}


class UpdateItemDiscountValueEvent extends SaleInvoiceEvent {
  final String rowId;
  final double discountValue;

  const UpdateItemDiscountValueEvent({
    required this.rowId,
    required this.discountValue,
  });

  @override
  List<Object?> get props => [rowId, discountValue];
}

class UpdateGeneralDiscountEvent extends SaleInvoiceEvent {
  final double discountValue;
  final DiscountType discountType; // 'percentage' or 'amount'

  const UpdateGeneralDiscountEvent({
    required this.discountValue,
    required this.discountType,
  });

  @override
  List<Object?> get props => [discountValue, discountType];
}

class UpdateItemUnitEvent extends SaleInvoiceEvent {
  final String rowId;
  final String unit;

  const UpdateItemUnitEvent({
    required this.rowId,
    required this.unit,
  });

  @override
  List<Object?> get props => [rowId, unit];
}