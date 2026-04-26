part of 'settings_visible_bloc.dart';

enum DateType {
  hijriShamsi,
  gregorian,
}

class SettingsVisibilityState extends Equatable {
  final bool stock;
  final bool attendance;
  final bool exchangeRate;
  final bool currencyRates;
  final bool dashboardClock;
  final bool recentTransactions;
  final DateType dateType;
  final String dateFormat;
  final bool isDateExpiry;
  final bool quickAccess;
  final bool profitAndLoss;
  final bool todayTotalTransactions;
  final bool statsCount;
  final bool todayTotalTxnChart;
  final bool transport;
  final bool orders;
  final bool benefit;
  final bool isWholeSale;

  const SettingsVisibilityState({
    this.stock = false,
    this.attendance = false,
    this.benefit = true,
    this.exchangeRate = true,
    this.isDateExpiry = false,
    this.currencyRates = false,
    this.dashboardClock = true,
    this.recentTransactions = false,
    this.quickAccess = true,
    this.dateType = DateType.gregorian,
    this.dateFormat = 'yyyy-MM-dd',
    this.profitAndLoss = true,
    this.todayTotalTransactions = true,
    this.statsCount = true,
    this.todayTotalTxnChart = true,
    this.transport = true,
    this.orders = true,
    this.isWholeSale = false,
  });

  factory SettingsVisibilityState.fromMap(Map<String, dynamic> map) {
    return SettingsVisibilityState(
      stock: map['stock'] ?? false,
      benefit: map['benefit'] ?? true,
      attendance: map['attendance'] ?? false,
      exchangeRate: map['exchangeRate'] ?? true,
      currencyRates: map['currencyRates'] ?? false, // Changed from 'currencyUsd' to match toMap
      dashboardClock: map['dashboardClock'] ?? true, // Changed from 'clock' to match toMap
      isDateExpiry: map['isDateExpiry'] ?? false, // Added null check
      quickAccess: map['quickAccess'] ?? true, // Changed default to match constructor
      recentTransactions: map['recentTransactions'] ?? false,
      dateType: _dateTypeFromString(map['dateType'] ?? 'gregorian'),
      dateFormat: map['dateFormat'] ?? 'yyyy-MM-dd',
      profitAndLoss: map['profitAndLoss'] ?? true,
      statsCount: map['statsCount'] ?? true,
      todayTotalTransactions: map['todayTotalTransactions'] ?? true,
      todayTotalTxnChart: map['todayTotalTxnChart'] ?? true,
      transport: map['transport'] ?? true,
      orders: map['orders'] ?? true,
      isWholeSale: map['isWholeSale'] ?? false
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stock': stock,
      'attendance': attendance,
      'exchangeRate': exchangeRate, // Changed from 'currencyAfn' to match fromMap
      'benefit': benefit,
      'currencyRates': currencyRates, // Changed from 'currencyUsd' to match fromMap
      'dashboardClock': dashboardClock, // Changed from 'clock' to match fromMap
      'dateType': dateType.name,
      'dateFormat': dateFormat,
      'isDateExpiry': isDateExpiry, // Changed from 'dateExpiry' to match fromMap
      'quickAccess': quickAccess,
      'recentTransactions': recentTransactions,
      'profitAndLoss': profitAndLoss,
      'statsCount': statsCount,
      'todayTotalTransactions': todayTotalTransactions,
      'todayTotalTxnChart': todayTotalTxnChart,
      'transport': transport,
      'orders': orders,
      'isWholeSale': isWholeSale
    };
  }

  static DateType _dateTypeFromString(String value) {
    return DateType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => DateType.gregorian,
    );
  }

  @override
  List<Object?> get props => [
    stock,
    attendance,
    exchangeRate,
    currencyRates,
    dashboardClock,
    recentTransactions,
    dateType,
    dateFormat,
    isDateExpiry,
    quickAccess,
    profitAndLoss,
    todayTotalTransactions,
    statsCount,
    todayTotalTxnChart,
    transport,
    orders,
    benefit,
    isWholeSale
  ];
}
