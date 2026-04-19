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

class UpdateExchangeRateManuallyEvent extends SaleInvoiceEvent {
  final double rate;
  final String fromCurrency;
  final String toCurrency;
  const UpdateExchangeRateManuallyEvent({
    required this.rate,
    required this.fromCurrency,
    required this.toCurrency,
  });
  @override
  List<Object?> get props => [rate, fromCurrency, toCurrency];
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
  final DiscountType? discountType;
  final double? purPrice;
  final double? salePrice;
  final int? storageId;
  final String? storageName;
  final double? landedPrice;
  final double? purchasePrice;
  final String? unit;

  const UpdateSaleItemEvent({
    required this.rowId,
    this.productId,
    this.productName,
    this.qty,
    this.discount,
    this.discountType,
    this.batch,
    this.localeAmount,
    this.exchangeRate,
    this.purPrice,
    this.salePrice,
    this.storageId,
    this.storageName,
    this.landedPrice,
    this.purchasePrice,
    this.unit,
  });

  @override
  List<Object?> get props => [
    rowId, productId, productName, qty, discount, discountType, batch,
    localeAmount, exchangeRate, purPrice, salePrice, storageId, storageName, landedPrice, purchasePrice, unit
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

class UpdateCashPaymentEvent extends SaleInvoiceEvent {
  final double cashPayment;
  const UpdateCashPaymentEvent(this.cashPayment);
  @override
  List<Object?> get props => [cashPayment];
}

class ResetSaleInvoiceEvent extends SaleInvoiceEvent {}

class SaveSaleInvoiceEvent extends SaleInvoiceEvent {
  final String usrName;
  final String orderName;
  final int ordPersonal;
  final String? xRef;

  final String? remark;
  final Completer<String> completer;

  const SaveSaleInvoiceEvent({
    required this.usrName,
    required this.ordPersonal,
    required this.orderName,
    this.xRef,
    this.remark,
    required this.completer,
  });

  @override
  List<Object?> get props => [usrName, ordPersonal, orderName, xRef, remark, completer];
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

class UpdateExtraChargesEvent extends SaleInvoiceEvent {
  final double charges;
  const UpdateExtraChargesEvent(this.charges);
  @override List<Object?> get props => [charges];
}

class UpdateItemDiscountTypeEvent extends SaleInvoiceEvent {
  final String rowId;
  final DiscountType discountType;
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
  final DiscountType discountType;
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

class UpdateCashCurrencyEvent extends SaleInvoiceEvent {
  final String currency;
  final double exchangeRate;
  const UpdateCashCurrencyEvent({
    required this.currency,
    required this.exchangeRate,
  });
  @override
  List<Object?> get props => [currency, exchangeRate];
}