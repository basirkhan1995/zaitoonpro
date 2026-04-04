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
  final int? pcs;
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
    this.pcs,
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
    pcs,
    purPrice,
    salePrice,
    storageId,
    storageName,
  ];
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