
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/FetchATAT/model/fetch_atat_model.dart';

class AtatPrintData {
  final String reportType; // 'single' or 'multiple'
  final FetchAtatModel transaction;
  final Map<String, CurrencyTotals> currencyTotals;
  final SystemTotal systemTotal;
  final String? baseCcy;
  final DateTime reportDate;
  final String? selectedReference;

  AtatPrintData({
    required this.reportType,
    required this.transaction,
    required this.currencyTotals,
    required this.systemTotal,
    this.baseCcy,
    required this.reportDate,
    this.selectedReference,
  });
}

class CurrencyTotals {
  final String name;
  final double totalDebit;
  final double totalCredit;
  final double netAmount;

  CurrencyTotals({
    required this.name,
    required this.totalDebit,
    required this.totalCredit,
    required this.netAmount,
  });
}

class SystemTotal {
  final double totalDebitSys;
  final double totalCreditSys;
  final double netAmountSys;

  SystemTotal({
    required this.totalDebitSys,
    required this.totalCreditSys,
    required this.netAmountSys,
  });
}