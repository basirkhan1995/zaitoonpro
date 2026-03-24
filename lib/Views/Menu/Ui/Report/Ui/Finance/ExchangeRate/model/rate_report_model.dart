import 'package:zaitoonpro/Features/Other/extensions.dart';

class ExchangeRateReportModel {
  final DateTime rateDate;

  final String fromCode;
  final String fromCountryCode;
  final String fromName;
  final String fromLocalName;
  final String fromSymbol;
  final String fromCountry;

  final String toCode;
  final String toCountryCode;
  final String toName;
  final String toLocalName;
  final String toSymbol;
  final String toCountry;

  final double crExchange;
  final double avgRate;

  ExchangeRateReportModel({
    required this.rateDate,
    required this.fromCode,
    required this.fromCountryCode,
    required this.fromName,
    required this.fromLocalName,
    required this.fromSymbol,
    required this.fromCountry,
    required this.toCode,
    required this.toCountryCode,
    required this.toName,
    required this.toLocalName,
    required this.toSymbol,
    required this.toCountry,
    required this.crExchange,
    required this.avgRate,
  });

  /// ---------- FACTORY ----------
  factory ExchangeRateReportModel.fromMap(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    DateTime parseDate(String? v) {
      if (v == null || v.isEmpty) return DateTime.now();
      return DateTime.tryParse(v) ?? DateTime.now();
    }

    return ExchangeRateReportModel(
      rateDate: parseDate(json['rate_date']),
      fromCode: json['from_code'] ?? '',
      fromCountryCode: json['from_countryCode'] ?? '',
      fromName: json['from_name'] ?? '',
      fromLocalName: json['from_localName'] ?? '',
      fromSymbol: json['from_symbol'] ?? '',
      fromCountry: json['from_country'] ?? '',
      toCode: json['to_code'] ?? '',
      toCountryCode: json['to_countryCode'] ?? '',
      toName: json['to_name'] ?? '',
      toLocalName: json['to_localName'] ?? '',
      toSymbol: json['to_symbol'] ?? '',
      toCountry: json['to_country'] ?? '',
      crExchange: parseDouble(json['crExchange']),
      avgRate: parseDouble(json['avg_rate']),
    );
  }

  /// ---------- TO MAP ----------
  Map<String, dynamic> toMap() => {
    'rate_date': rateDate.toIso8601String().split('T').first,
    'from_code': fromCode,
    'from_countryCode': fromCountryCode,
    'from_name': fromName,
    'from_localName': fromLocalName,
    'from_symbol': fromSymbol,
    'from_country': fromCountry,
    'to_code': toCode,
    'to_countryCode': toCountryCode,
    'to_name': toName,
    'to_localName': toLocalName,
    'to_symbol': toSymbol,
    'to_country': toCountry,
    'crExchange': crExchange.toExchangeRate(),
    'avg_rate': avgRate.toExchangeRate(),
  };

  /// ---------- HELPERS ----------

  bool get isSameCurrency => fromCode == toCode;

  String get pair => '$fromCode → $toCode';

  String get displayRate => crExchange.toExchangeRate();

  String get displayAvgRate => avgRate.toExchangeRate();
}
