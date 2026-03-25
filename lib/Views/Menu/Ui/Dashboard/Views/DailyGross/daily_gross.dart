import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

import '../../../HR/Ui/Users/features/date_range_string.dart';
import 'bloc/daily_gross_bloc.dart';
import 'model/gross_model.dart';

/// =======================
/// DAILY GROSS VIEW
/// =======================
class DailyGrossView extends StatefulWidget {
  const DailyGrossView({super.key});

  @override
  State<DailyGrossView> createState() => _DailyGrossViewState();
}

class _DailyGrossViewState extends State<DailyGrossView> {
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final from = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7)));
    final to = DateFormat('yyyy-MM-dd').format(now);

    context.read<DailyGrossBloc>().add(
      FetchDailyGrossEvent(
        from: from,
        to: to,
        startGroup: 3,
        stopGroup: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(8),
    child: _DailyGrossContent(),
  );
}

class _Tablet extends StatelessWidget {
  const _Tablet();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: _DailyGrossContent(),
  );
}

class _Desktop extends StatelessWidget {
  const _Desktop();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 5,horizontal: 3),
    child: _DailyGrossContent(),
  );
}

/// =======================
/// DAILY GROSS CONTENT
/// =======================

class _DailyGrossContent extends StatefulWidget {
  const _DailyGrossContent();
  @override
  State<_DailyGrossContent> createState() => _DailyGrossContentState();
}

class _DailyGrossContentState extends State<_DailyGrossContent> {
  int chartType = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyGrossBloc, DailyGrossState>(
      builder: (context, state) {
        // Handle all states
        if (state is DailyGrossError) {
          // For dashboard, don't show errors - just hide the widget
          return Container();
        }

        // Show only when we have loaded data
        if (state is DailyGrossLoaded && state.data.isNotEmpty) {
          final chartData = _prepareChartData(state.data);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main chart container
              ZCover(
                radius: 5,
                borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    // Header: Title + Date Range + Chart Toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.profitAndLoss,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Expanded(

                            child: DateRangeDropdown(
                              title: '',
                              height: 35,
                              onChanged: (fromDate, toDate) {
                                // Silent refresh when date changes
                                context.read<DailyGrossBloc>().add(
                                  FetchDailyGrossEvent(
                                    from: fromDate,
                                    to: toDate,
                                    startGroup: 3,
                                    stopGroup: 4,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          ToggleButtons(
                            isSelected: [chartType == 0, chartType == 1],
                            onPressed: (index) {
                              setState(() {
                                chartType = index;
                              });
                            },
                            constraints: const BoxConstraints(
                              minHeight: 32,
                              minWidth: 50,
                            ),
                            borderRadius: BorderRadius.circular(3),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text("Line"),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text("Bar"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Chart Area
                    SizedBox(
                      height: 200,
                      child: chartType == 0
                          ? _buildLineChart(chartData, context)
                          : _buildBarChart(chartData, context),
                    ),
                  ],
                ),
              ),

              // Subtle refresh indicator (only shown during silent refresh)
              if (state.isRefreshing)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        padding: const EdgeInsets.all(2),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: .7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }

        // For all other states (Initial, Loading, Loaded with empty data) - return empty container
        return Container();
      },
    );
  }

  /// Line chart
  SfCartesianChart _buildLineChart(List<GrossChartData> chartData, BuildContext context) {
    return SfCartesianChart(
      legend: Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        position: LegendPosition.bottom,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.days,
        dateFormat: DateFormat('MM/dd'),
      ),
      primaryYAxis: NumericAxis(),
      series: [
        LineSeries<GrossChartData, DateTime>(
          dataSource: chartData,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.profit,
          name: AppLocalizations.of(context)!.profit,
          color: Colors.green,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
        LineSeries<GrossChartData, DateTime>(
          dataSource: chartData,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.loss,
          name: AppLocalizations.of(context)!.loss,
          color: Colors.red,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  /// Bar chart
  SfCartesianChart _buildBarChart(List<GrossChartData> chartData, BuildContext context) {
    return SfCartesianChart(
      tooltipBehavior: TooltipBehavior(enable: true),
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.days,
        dateFormat: DateFormat('MM/dd'),
      ),
      primaryYAxis: NumericAxis(),
      series: [
        ColumnSeries<GrossChartData, DateTime>(
          dataSource: chartData,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.profit,
          name: AppLocalizations.of(context)!.profit,
          color: Colors.green.withValues(alpha: .7),
        ),
        ColumnSeries<GrossChartData, DateTime>(
          dataSource: chartData,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.loss,
          name: AppLocalizations.of(context)!.loss,
          color: Colors.red.withValues(alpha: .7),
        ),
      ],
    );
  }

  /// Aggregate profit/loss per day
  List<GrossChartData> _prepareChartData(List<DailyGrossModel> data) {
    final map = <DateTime, GrossChartData>{};

    for (final item in data) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);

      map.putIfAbsent(
        date,
            () => GrossChartData(date: date, profit: 0, loss: 0),
      );

      if (item.category == GrossCategory.profit) {
        map[date] = GrossChartData(
          date: date,
          profit: map[date]!.profit + item.balance,
          loss: map[date]!.loss,
        );
      } else {
        map[date] = GrossChartData(
          date: date,
          profit: map[date]!.profit,
          loss: map[date]!.loss + item.balance,
        );
      }
    }

    final list = map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}

/// Chart data
class GrossChartData {
  final DateTime date;
  final double profit;
  final double loss;

  GrossChartData({
    required this.date,
    required this.profit,
    required this.loss,
  });
}