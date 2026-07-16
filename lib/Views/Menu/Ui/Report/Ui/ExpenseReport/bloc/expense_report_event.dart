part of 'expense_report_bloc.dart';

sealed class ExpenseReportEvent extends Equatable {
  const ExpenseReportEvent();

  @override
  List<Object> get props => [];
}

class FetchExpenseReport extends ExpenseReportEvent {
  final String? dateFrom;
  final String? dateTo;
  final String? currency;
  final int? accountNumber;

  const FetchExpenseReport({
    this.dateFrom,
    this.dateTo,
    this.currency,
    this.accountNumber,
  });

  @override
  List<Object> get props => [
    dateFrom ?? '',
    dateTo ?? '',
    currency ?? '',
    accountNumber ?? 0,
  ];
}

class FilterExpenseReport extends ExpenseReportEvent {
  final String? dateFrom;
  final String? dateTo;
  final String? currency;
  final int? accountNumber;

  const FilterExpenseReport({
    this.dateFrom,
    this.dateTo,
    this.currency,
    this.accountNumber,
  });

  @override
  List<Object> get props => [
    dateFrom ?? '',
    dateTo ?? '',
    currency ?? '',
    accountNumber ?? 0,
  ];
}

class RefreshExpenseReport extends ExpenseReportEvent {
  const RefreshExpenseReport();
}

class ClearExpenseReportFilters extends ExpenseReportEvent {
  const ClearExpenseReportFilters();
}