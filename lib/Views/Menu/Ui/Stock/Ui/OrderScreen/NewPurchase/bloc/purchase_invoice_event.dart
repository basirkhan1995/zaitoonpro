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
  List<Object?> get props => [rowId, productId, productName, qty, batch, purPrice, sellPriceAmount, storageId, storageName];
}

class UpdateCashPaymentEvent extends PurchaseInvoiceEvent {
  final double cashPayment;
  const UpdateCashPaymentEvent(this.cashPayment);
  @override
  List<Object?> get props => [cashPayment];
}

class ResetPurchaseInvoiceEvent extends PurchaseInvoiceEvent {}

class SavePurchaseInvoiceEvent extends PurchaseInvoiceEvent {
  final String usrName;
  final String orderName;
  final int ordPersonal;
  final String? xRef;
  final String? remark;
  final Completer<String> completer;
  const SavePurchaseInvoiceEvent({
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

class ClearSupplierAccountEvent extends PurchaseInvoiceEvent {
  const ClearSupplierAccountEvent();
}

class LoadPurchaseStoragesEvent extends PurchaseInvoiceEvent {
  final int productId;
  const LoadPurchaseStoragesEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

// Unified Payment Events
class AddPaymentEvent extends PurchaseInvoiceEvent {
  final bool isExpense;
  const AddPaymentEvent({this.isExpense = true});
  @override
  List<Object?> get props => [isExpense];
}

class RemovePaymentEvent extends PurchaseInvoiceEvent {
  final int index;
  final bool wasExpense;
  const RemovePaymentEvent(this.index, {this.wasExpense = true});
  @override
  List<Object?> get props => [index, wasExpense];
}

class UpdatePaymentEvent extends PurchaseInvoiceEvent {
  final int index;
  final int? accountNumber;
  final double? amount;
  final String? currency;
  final double? exRate;
  final String? narration;
  final bool? isExpense;
  const UpdatePaymentEvent({
    required this.index,
    this.accountNumber,
    this.amount,
    this.currency,
    this.exRate,
    this.narration,
    this.isExpense,
  });
  @override
  List<Object?> get props => [index, accountNumber, amount, currency, exRate, narration, isExpense];
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