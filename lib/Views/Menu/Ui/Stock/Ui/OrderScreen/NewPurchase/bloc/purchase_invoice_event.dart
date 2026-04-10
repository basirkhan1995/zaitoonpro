part of 'purchase_invoice_bloc.dart';

abstract class PurchaseInvoiceEvent extends Equatable {
  const PurchaseInvoiceEvent();

  @override
  List<Object?> get props => [];
}

class InitializePurchaseInvoiceEvent extends PurchaseInvoiceEvent {}

class SelectSupplierEvent extends PurchaseInvoiceEvent {
  final IndividualsModel supplier;
  const SelectSupplierEvent(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class SelectSupplierAccountEvent extends PurchaseInvoiceEvent {
  final AccountsModel supplier;
  const SelectSupplierAccountEvent(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class ClearSupplierEvent extends PurchaseInvoiceEvent {}

class AddNewPurchaseItemEvent extends PurchaseInvoiceEvent {}

class RemovePurchaseItemEvent extends PurchaseInvoiceEvent {
  final String rowId;
  const RemovePurchaseItemEvent(this.rowId);

  @override
  List<Object?> get props => [rowId];
}

class UpdatePurchaseItemEvent extends PurchaseInvoiceEvent {
  final String rowId;
  final String? productId;
  final String? productName;
  final int? qty;
  final int? batch;
  final double? purPrice;
  final double? sellPriceAmount;
  final int? storageId;
  final String? storageName;

  const UpdatePurchaseItemEvent({
    required this.rowId,
    this.productId,
    this.productName,
    this.qty,
    this.batch,
    this.purPrice,
    this.sellPriceAmount,
    this.storageId,
    this.storageName,
  });

  @override
  List<Object?> get props => [
    rowId,
    productId,
    productName,
    qty,
    batch,
    purPrice,
    sellPriceAmount,
    storageId,
    storageName,
  ];
}

class UpdatePurchasePaymentEvent extends PurchaseInvoiceEvent {
  final double payment;
  final bool isCreditAmount;

  const UpdatePurchasePaymentEvent(this.payment, {this.isCreditAmount = false});

  @override
  List<Object?> get props => [payment, isCreditAmount];
}

class ResetPurchaseInvoiceEvent extends PurchaseInvoiceEvent {}

class SavePurchaseInvoiceEvent extends PurchaseInvoiceEvent {
  final String usrName;
  final String orderName;
  final int ordPersonal;
  final String? xRef;
  final String? invoiceCcy;
  final String? remark;
  final List<PurchaseInvoiceItem> items;
  final List<PurExpenseRecord> expenses;
  final Completer<String> completer;

  const SavePurchaseInvoiceEvent({
    required this.usrName,
    required this.ordPersonal,
    required this.orderName,
    this.xRef,
    this.invoiceCcy,
    this.remark,
    required this.items,
    required this.expenses,
    required this.completer,
  });

  @override
  List<Object?> get props => [usrName, ordPersonal, orderName, xRef,invoiceCcy,remark, items, completer];
}

class ClearSupplierAccountEvent extends PurchaseInvoiceEvent {
  const ClearSupplierAccountEvent();
  @override
  List<Object?> get props => [];
}

class LoadPurchaseStoragesEvent extends PurchaseInvoiceEvent {
  final int productId;
  const LoadPurchaseStoragesEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}


class AddExpenseEvent extends PurchaseInvoiceEvent {
  const AddExpenseEvent();
}

class RemoveExpenseEvent extends PurchaseInvoiceEvent {
  final String rowId;
  const RemoveExpenseEvent(this.rowId);

  @override
  List<Object?> get props => [rowId];
}

class UpdateExpenseEvent extends PurchaseInvoiceEvent {
  final String rowId;
  final String? narration;
  final int? account;
  final double? amount;
  final String? accountName;

  const UpdateExpenseEvent({
    required this.rowId,
    this.narration,
    this.account,
    this.amount,
    this.accountName,
  });

  @override
  List<Object?> get props => [rowId, narration, account, amount, accountName];
}

class UpdateAllLandedPricesEvent extends PurchaseInvoiceEvent {
  const UpdateAllLandedPricesEvent();
}



class UpdateExchangeRateForInvoiceEvent extends PurchaseInvoiceEvent {
  final String fromCurrency;
  final String toCurrency;

  const UpdateExchangeRateForInvoiceEvent({
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [fromCurrency, toCurrency];
}

class UpdateItemLocalAmountEvent extends PurchaseInvoiceEvent {
  final String rowId;

  const UpdateItemLocalAmountEvent(this.rowId);

  @override
  List<Object?> get props => [rowId];
}

class UpdateAllLocalAmountsEvent extends PurchaseInvoiceEvent {
  const UpdateAllLocalAmountsEvent();
}

class UpdateExchangeRateManuallyEvent extends PurchaseInvoiceEvent {
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