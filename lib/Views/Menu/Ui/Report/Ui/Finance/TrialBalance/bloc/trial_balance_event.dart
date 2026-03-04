part of 'trial_balance_bloc.dart';

sealed class TrialBalanceEvent extends Equatable {
  const TrialBalanceEvent();
}

class LoadTrialBalanceEvent extends TrialBalanceEvent{
  final String date;
  final int? branchCode;
  const LoadTrialBalanceEvent({required this.date,this.branchCode});
  @override
  List<Object?> get props => [date, branchCode];
}