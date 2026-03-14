part of 'shipping_bloc.dart';

abstract class ShippingEvent extends Equatable {
  const ShippingEvent();
}

// List operations
class LoadShippingEvent extends ShippingEvent {
  @override
  List<Object> get props => [];
}

class AddShippingEvent extends ShippingEvent {
  final ShippingModel newShipping;
  const AddShippingEvent(this.newShipping);

  @override
  List<Object> get props => [newShipping];
}

class UpdateShippingEvent extends ShippingEvent {
  final ShippingModel updatedShipping;
  const UpdateShippingEvent(this.updatedShipping);

  @override
  List<Object> get props => [updatedShipping];
}

// Detail operations
class LoadShippingDetailEvent extends ShippingEvent {
  final int shpId;
  const LoadShippingDetailEvent(this.shpId);

  @override
  List<Object> get props => [shpId];
}

// Clear loading state
class ClearDetailLoadingEvent extends ShippingEvent {
  @override
  List<Object> get props => [];
}

class AddShippingPaymentEvent extends ShippingEvent{
  final String usrName;
  final int shpId;
  final String paymentType;
  final double? cashAmount;
  final double? accountAmount;
  final int? accNumber;

  const AddShippingPaymentEvent({required this. usrName, required this.shpId, required this. paymentType, this.cashAmount,  this.accountAmount,  this.accNumber});
  @override
  List<Object?> get props => [
    usrName,
    shpId,
    paymentType,
    cashAmount,
    accountAmount,
    accNumber,
  ];
}
class EditShippingPaymentEvent extends ShippingEvent{
  final String? reference;
  final String usrName;
  final int shpId;
  final String paymentType;
  final double? cashAmount;
  final double? accountAmount;
  final int? accNumber;

  const EditShippingPaymentEvent({required this.reference, required this. usrName, required this.shpId, required this. paymentType, this.cashAmount,  this.accountAmount,  this.accNumber});
  @override
  List<Object?> get props => [
    reference,
    usrName,
    shpId,
    paymentType,
    cashAmount,
    accountAmount,
    accNumber,
  ];
}

// Stepper operations
class UpdateStepperStepEvent extends ShippingEvent {
  final int step;
  const UpdateStepperStepEvent(this.step);

  @override
  List<Object> get props => [step];
}

class ClearShippingDetailEvent extends ShippingEvent {
  @override
  List<Object> get props => [];
}

class ClearShippingSuccessEvent extends ShippingEvent {
  @override
  List<Object> get props => [];
}

// Expense operations
class AddShippingExpenseEvent extends ShippingEvent {
  final int shpId;
  final int accNumber;
  final String amount;
  final String narration;
  final String usrName;

  const AddShippingExpenseEvent({
    required this.shpId,
    required this.accNumber,
    required this.amount,
    required this.narration,
    required this.usrName,
  });

  @override
  List<Object> get props => [shpId, accNumber, amount, narration, usrName];
}

class UpdateShippingExpenseEvent extends ShippingEvent {
  final int shpId;
  final String trnReference;
  final int accNumber;
  final String amount;
  final String narration;
  final String usrName;

  const UpdateShippingExpenseEvent({
    required this.shpId,
    required this.trnReference,
    required this.accNumber,
    required this.amount,
    required this.narration,
    required this.usrName,
  });

  @override
  List<Object> get props => [shpId, trnReference, accNumber, amount, narration, usrName];
}

class DeleteShippingExpenseEvent extends ShippingEvent {
  final int shpId;
  final String trnReference;
  final String usrName;

  const DeleteShippingExpenseEvent({
    required this.shpId,
    required this.trnReference,
    required this.usrName,
  });

  @override
  List<Object> get props => [shpId, trnReference, usrName];
}