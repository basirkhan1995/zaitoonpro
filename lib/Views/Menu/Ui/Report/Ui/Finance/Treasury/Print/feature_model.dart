
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Finance/Treasury/model/cash_balance_model.dart';

class CashBalancesPrintData {
  final String reportType;
  final List<CashBalancesModel> branches;
  final Map<String, CurrencyTotal> currencyTotals;
  final SystemTotal systemTotal;
  final String? baseCcy;
  final DateTime reportDate;
  final String? selectedBranchName;

  CashBalancesPrintData({
    required this.reportType,
    required this.branches,
    required this.currencyTotals,
    required this.systemTotal,
    this.baseCcy,
    required this.reportDate,
    this.selectedBranchName,
  });
}

class CurrencyTotal {
  final String name;
  final String symbol;
  final double totalOpening;
  final double totalClosing;
  final double totalOpeningSys;
  final double totalClosingSys;

  CurrencyTotal({
    required this.name,
    required this.symbol,
    required this.totalOpening,
    required this.totalClosing,
    required this.totalOpeningSys,
    required this.totalClosingSys,
  });

  double get cashFlow => totalClosing - totalOpening;
  double get cashFlowSys => totalClosingSys - totalOpeningSys;
}

class SystemTotal {
  final double totalOpeningSys;
  final double totalClosingSys;

  SystemTotal({
    required this.totalOpeningSys,
    required this.totalClosingSys,
  });

  double get cashFlowSys => totalClosingSys - totalOpeningSys;
}