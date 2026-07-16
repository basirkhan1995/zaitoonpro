part of 'expense_report_bloc.dart';

sealed class ExpenseReportState extends Equatable {
  const ExpenseReportState();

  @override
  List<Object> get props => [];
}

final class ExpenseReportInitial extends ExpenseReportState {}

final class ExpenseReportLoading extends ExpenseReportState {}

final class ExpenseReportLoaded extends ExpenseReportState {
  final ExpenseReportModel expenseReport;
  final String? dateFrom;
  final String? dateTo;
  final String? currency;
  final int? accountNumber;

  const ExpenseReportLoaded({
    required this.expenseReport,
    this.dateFrom,
    this.dateTo,
    this.currency,
    this.accountNumber,
  });

  @override
  List<Object> get props => [
    expenseReport,
    dateFrom ?? '',
    dateTo ?? '',
    currency ?? '',
    accountNumber ?? 0,
  ];
}

final class ExpenseReportError extends ExpenseReportState {
  final String message;

  const ExpenseReportError(this.message);

  @override
  List<Object> get props => [message];
}