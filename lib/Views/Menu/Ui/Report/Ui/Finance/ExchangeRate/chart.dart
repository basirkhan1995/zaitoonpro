import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ExchangeRate/bloc/fx_rate_report_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ExchangeRate/model/rate_report_model.dart';

import '../../../../HR/Ui/Users/features/date_range_string.dart';

/// =======================================================
/// FX RATE DASHBOARD CHART (AREA + LINE)
/// =======================================================
class FxRateDashboardChart extends StatelessWidget {
  const FxRateDashboardChart({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _ChartContent(),
      tablet: _ChartContent(),
      desktop: _ChartContent(),
    );
  }
}

class _ChartContent extends StatefulWidget {
  const _ChartContent();

  @override
  State<_ChartContent> createState() => _ChartContentState();
}

class _ChartContentState extends State<_ChartContent> {
  String? fromCcy = 'USD';
  String? toCcy = 'AFN';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData({String? fromDate, String? toDate}) {
    final now = DateTime.now();
    final from = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
    final to = DateFormat('yyyy-MM-dd').format(now);

    context.read<FxRateReportBloc>().add(
      LoadFxRateReportEvent(
        fromDate: fromDate ?? from,
        toDate: toDate ?? to,
        fromCcy: fromCcy,
        toCcy: toCcy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ZCover(
      radius: 8,
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ---------------- FILTER ROW ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.exchangeRate,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(flex: 2),

                Flexible(
                  child: CurrencyDropdown(
                    title: AppLocalizations.of(context)!.from,
                    height: 35,
                    initiallySelectedSingle: CurrenciesModel(ccyCode: fromCcy),
                    isMulti: false,
                    onSingleChanged: (e) {
                      setState(() => fromCcy = e?.ccyCode);
                      _loadData();
                    },
                    onMultiChanged: (_) {},
                  ),
                ),

                const SizedBox(width: 10),

                Flexible(
                  child: CurrencyDropdown(
                    height: 35,
                    title: AppLocalizations.of(context)!.toCurrency,
                    initiallySelectedSingle: CurrenciesModel(ccyCode: toCcy),
                    isMulti: false,
                    onSingleChanged: (e) {
                      setState(() => toCcy = e?.ccyCode);
                      _loadData();
                    },
                    onMultiChanged: (_) {},
                  ),
                ),

                const SizedBox(width: 10),

                Flexible(
                  child: DateRangeDropdown(
                    title: AppLocalizations.of(context)!.dateRange,
                    height: 35,
                    onChanged: (fromDate, toDate) {
                      _loadData(fromDate: fromDate, toDate: toDate);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// ---------------- CHART ----------------
          SizedBox(
            height: 280,
            width: double.infinity,
            child: BlocBuilder<FxRateReportBloc, FxRateReportState>(
              builder: (context, state) {
                // Handle all states
                if (state is FxRateReportErrorState) {
                  // For dashboard, don't show errors - just hide the chart
                  return Container();
                }

                // Show only when we have loaded data
                if (state is FxRateReportLoadedState && state.rates.isNotEmpty) {
                  return Stack(
                    children: [
                      _buildAreaChart(context, state.rates),

                      // Subtle refresh indicator overlay
                      if (state.isRefreshing)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: .8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  );
                }

                // For all other states (Initial, Loading, Loaded with empty data) - return empty container
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// =======================================================
  /// AREA + LINE CHART
  /// =======================================================
  SfCartesianChart _buildAreaChart(
      BuildContext context,
      List<ExchangeRateReportModel> rates,
      ) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final data = rates
        .map(
          (e) => _ChartPoint(
        date: e.rateDate,
        value: e.avgRate,
      ),
    )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SfCartesianChart(
      tooltipBehavior: TooltipBehavior(enable: true),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      ),
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.days,
        dateFormat: DateFormat('MM/dd'),
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat('#,##0.00'),
      ),
      series: <CartesianSeries>[
        AreaSeries<_ChartPoint, DateTime>(
          dataSource: data,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.value,
          borderColor: primaryColor,
          borderWidth: 2,
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.15),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          markerSettings: const MarkerSettings(isVisible: true),
          name: '$fromCcy → $toCcy',
        ),
      ],
    );
  }
}

/// =======================================================
/// INTERNAL CHART POINT
/// =======================================================
class _ChartPoint {
  final DateTime date;
  final double value;

  _ChartPoint({
    required this.date,
    required this.value,
  });
}