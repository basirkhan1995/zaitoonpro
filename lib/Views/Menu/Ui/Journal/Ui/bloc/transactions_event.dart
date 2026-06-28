part of 'transactions_bloc.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();
}

class OnCashTransactionEvent extends TransactionsEvent{
  final TransactionsModel transaction;
  const OnCashTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class OnACTATTransactionEvent extends TransactionsEvent{
  final TransactionsModel transaction;
  const OnACTATTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}
class UnAuthorizedTxnEvent extends TransactionsEvent {
  final String reference;
  final String usrName;
  const UnAuthorizedTxnEvent({required this.reference,required this.usrName});
  @override
  List<Object?> get props => [reference, usrName];
}

class UpdatePendingTransactionEvent extends TransactionsEvent{
  final TransactionsModel transaction;
  const UpdatePendingTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class LoadAllTransactionsEvent extends TransactionsEvent {
  final String status;
  const LoadAllTransactionsEvent(this.status);
  @override
  List<Object?> get props => [status];
}

class AuthorizeTxnEvent extends TransactionsEvent {
  final String reference;
  final String usrName;
  const AuthorizeTxnEvent({required this.reference,required this.usrName});
  @override
  List<Object?> get props => [reference, usrName];
}

class ReverseTxnEvent extends TransactionsEvent {
  final String reference;
  final String usrName;
  const ReverseTxnEvent({required this.reference,required this.usrName});
  @override
  List<Object?> get props => [reference, usrName];
}

class DeletePendingTxnEvent extends TransactionsEvent {
  final String reference;
  final String usrName;
  const DeletePendingTxnEvent({required this.reference,required this.usrName});
  @override
  List<Object?> get props => [reference, usrName];
}