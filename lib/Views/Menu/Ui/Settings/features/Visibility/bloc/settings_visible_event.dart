part of 'settings_visible_bloc.dart';

sealed class SettingsVisibleEvent extends Equatable {
  const SettingsVisibleEvent();
}

class SaveSettingsEvent extends SettingsVisibleEvent{
  final SettingsVisibilityState value;
  const SaveSettingsEvent(this.value);
  @override
  List<Object?> get props => [value];
}


class LoadSettingsEvent extends SettingsVisibleEvent{
  @override
  List<Object?> get props => [];
}

class UpdateSettingsEvent extends SettingsVisibleEvent {
  final bool? stock;
  final bool? attendance; // Added missing field
  final bool? exchangeRate;
  final bool? currencyRates; // Changed from currencyUsd
  final bool? dashboardClock;
  final bool? benefit;
  final bool? quickAccess;
  final bool? recentTransactions;
  final DateType? dateType;
  final bool? isDateExpiry;
  final String? dateFormat;
  final bool? profitAndLoss;
  final bool? transport;
  final bool? orders;
  final bool? todayTotalTransactions; // Added missing field
  final bool? statsCount; // Added missing field
  final bool? todayTotalTxnChart; // Added missing field

  const UpdateSettingsEvent({
    this.stock,
    this.attendance,
    this.exchangeRate,
    this.benefit,
    this.isDateExpiry,
    this.currencyRates, // Changed from currencyUsd
    this.dashboardClock,
    this.quickAccess,
    this.dateType,
    this.dateFormat,
    this.recentTransactions,
    this.profitAndLoss,
    this.transport,
    this.orders,
    this.todayTotalTransactions,
    this.statsCount,
    this.todayTotalTxnChart,
  });

  @override
  List<Object?> get props => [
    stock,
    attendance,
    exchangeRate,
    benefit,
    isDateExpiry,
    currencyRates, // Changed from currencyUsd
    dashboardClock,
    quickAccess,
    recentTransactions,
    dateType,
    dateFormat,
    profitAndLoss,
    transport,
    orders,
    todayTotalTransactions,
    statsCount,
    todayTotalTxnChart,
  ];
}