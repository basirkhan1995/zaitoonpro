import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Other/extensions.dart';
import 'bloc/total_daily_bloc.dart';
import 'model/total_daily_compare.dart';

class TotalDailyColumnView extends StatefulWidget {
  const TotalDailyColumnView({super.key,});

  @override
  State<TotalDailyColumnView> createState() => _TotalDailyColumnViewState();
}

class _TotalDailyColumnViewState extends State<TotalDailyColumnView> {

  late String fromDate;
  late String toDate;

  @override
  void initState() {
    // Trigger load when widget is built with new dates
    fromDate = DateTime.now().toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TotalDailyBloc>().add(
        LoadTotalDailyEvent(fromDate: fromDate, toDate:  toDate,),
      );
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TotalDailyBloc, TotalDailyState>(
      builder: (context, state) {
        /// 🔴 ERROR - Silent for dashboard
        if (state is TotalDailyError) {
          return const SizedBox();
        }

        /// 🟢 LOADED
        if (state is TotalDailyLoaded) {
          // Filter and prepare today's data only
          final todayData = _prepareTodayData(state.data);

          // Show no-data message if empty
          if (todayData.isEmpty) {
            return _buildNoDataWidget(context);
          }

          return ZCover(
            radius: 8,
            margin: const EdgeInsets.all(4),
            borderColor: theme.colorScheme.outline.withValues(alpha: .1),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with refresh button
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.dailyTransactions,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          // Refresh button
                          IconButton(
                            onPressed: () {
                              context.read<TotalDailyBloc>().add(
                                LoadTotalDailyEvent(
                                  fromDate: fromDate,
                                toDate:  toDate,
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.refresh,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.today,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chart with pull-to-refresh
                SizedBox(
                  height: 220,
                  child: _buildChart(context, todayData),
                ),

                // Summary stats
                const SizedBox(height: 16),
                _buildSummaryStats(context, todayData),
              ],
            ),
          );
        }

        /// 🔄 LOADING - Show loading indicator
        if (state is TotalDailyLoading) {
          return ZCover(
            radius: 8,
            margin: const EdgeInsets.all(4),
            borderColor: theme.colorScheme.outline.withValues(alpha: .1),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.dailyTransactions,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.today,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading indicator
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: .08),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading transactions...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline.withValues(alpha: .6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        /// Initial state - Show nothing
        return const SizedBox();
      },
    );
  }

  /// 🆕 Build widget for no-data state
  Widget _buildNoDataWidget(BuildContext context) {
    final theme = Theme.of(context);

    return ZCover(
      radius: 8,
      margin: const EdgeInsets.all(4),
      borderColor: theme.colorScheme.outline.withValues(alpha: .1),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with refresh button
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.dailyTransactions,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    // Refresh button
                    IconButton(
                      onPressed: () {
                          context.read<TotalDailyBloc>().add(
                            LoadTotalDailyEvent(
                              fromDate: fromDate,
                              toDate:  toDate,
                            ),
                          );

                      },
                      icon: Icon(
                        Icons.refresh,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.today,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // No-data message
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: .08),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: .05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.show_chart,
                    size: 48,
                    color: theme.colorScheme.primary.withValues(alpha: .3),
                  ),
                ),

                const SizedBox(height: 16),

                // Main message
                Text(
                  'No Data Available',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.outline,
                  ),
                ),

                const SizedBox(height: 8),

                // Sub message
                Text(
                  'There are no transactions recorded for today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline.withValues(alpha: .6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_ChartItem> _prepareTodayData(List<TotalDailyCompare> data) {
    // Extract today's data, filter out zero amounts, sort by amount descending
    return data
        .map((item) => _ChartItem(
      name: item.today.txnName ?? 'Unknown',
      amount: item.today.totalAmount ?? 0,
      count: item.today.totalCount ?? 0,
    ))
        .where((item) => item.amount > 0)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Widget _buildChart(BuildContext context, List<_ChartItem> data) {
    final theme = Theme.of(context);
    final colors = _getChartColors(data.length);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TotalDailyBloc>().add(
          LoadTotalDailyEvent(
            fromDate: fromDate,
            toDate:  toDate,
          ),
        );
        // Wait for the new state
        await context.read<TotalDailyBloc>().stream.firstWhere(
              (state) => state is TotalDailyLoaded || state is TotalDailyError,
        );
      },
      child: SfCartesianChart(
        margin: const EdgeInsets.all(0),
        plotAreaBorderWidth: 0,

        // Primary X Axis
        primaryXAxis: CategoryAxis(
          labelRotation: data.length > 5 ? -45 : 0,
          labelStyle: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.outline.withValues(alpha: .7),
          ),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          axisLine: AxisLine(
            width: 1,
            color: theme.colorScheme.outline.withValues(alpha: .1),
          ),
        ),

        // Primary Y Axis
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.compactSimpleCurrency(
            decimalDigits: 0,
          ),
          labelStyle: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.outline.withValues(alpha: .7),
          ),
          majorGridLines: MajorGridLines(
            width: 1,
            color: theme.colorScheme.outline.withValues(alpha: .05),
          ),
          majorTickLines: const MajorTickLines(width: 0),
          axisLine: const AxisLine(width: 0),
          minimum: 0,
        ),

        // Tooltip
        tooltipBehavior: TooltipBehavior(
          enable: true,
          header: '',
          format: 'point.x\nAmount: point.y\nTransactions: point.count',
          color: theme.colorScheme.surface,
          textStyle: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 12,
          ),
        ),

        // Series
        series: <CartesianSeries>[
          ColumnSeries<_ChartItem, String>(
            dataSource: data,
            xValueMapper: (_ChartItem item, _) => item.name,
            yValueMapper: (_ChartItem item, _) => item.amount,
            pointColorMapper: (_ChartItem item, index) => colors[index],

            // Styling
            width: 0.7,
            spacing: 0.2,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),

            // Animation
            animationDuration: 1000,
            animationDelay: 100,

            // Data labels
            dataLabelSettings: DataLabelSettings(
              isVisible: data.length <= 8,
              textStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.surface,
              ),
              labelAlignment: ChartDataLabelAlignment.top,
              labelPosition: ChartDataLabelPosition.outside,
            ),

            name: 'Amount',

            // Add border to columns
            borderWidth: 1,
            borderColor: theme.colorScheme.surface,

            // Better gradient
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: .5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, List<_ChartItem> data) {
    final theme = Theme.of(context);

    final totalCount = data.fold<int>(0, (sum, item) => sum + item.count);
    final lowestTransaction = data.isNotEmpty ? data.last : null;
    final highestTransaction = data.isNotEmpty ? data.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: .08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Quick Stats',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          // Stats in a row with dividers
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Transactions
                _buildMinimalStat(
                  context,
                  value: totalCount.toString(),
                  label: 'Transactions',
                  color: Colors.green,
                ),

                // Divider
                Container(
                  width: 1,
                  color: theme.colorScheme.outline.withValues(alpha: .1),
                ),

                // Categories
                _buildMinimalStat(
                  context,
                  value: data.length.toString(),
                  label: 'Categories',
                  color: Colors.purple,
                ),

                // Divider
                Container(
                  width: 1,
                  color: theme.colorScheme.outline.withValues(alpha: .1),
                ),

                // Range (Highest - Lowest)
                if (lowestTransaction != null && highestTransaction != null)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${lowestTransaction.amount.toAmount()} - ${highestTransaction.amount.toAmount()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Range',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline.withValues(alpha: .6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStat(BuildContext context, {
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline.withValues(alpha: .6),
          ),
        ),
      ],
    );
  }

  List<Color> _getChartColors(int count) {
    // Use Material Design color palette for better aesthetics
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
      Colors.cyan.shade600,
      Colors.amber.shade600,
      Colors.deepPurple.shade600,
      Colors.deepOrange.shade600,
    ];

    // If we have more items than colors, repeat with slight variation
    if (count <= colors.length) {
      return colors.sublist(0, count);
    }

    return List.generate(count, (index) {
      // Create variations of base colors
      final baseColor = colors[index % colors.length];
      final variation = (index ~/ colors.length) * 0.1;
      return HSLColor.fromColor(baseColor)
          .withLightness(HSLColor.fromColor(baseColor).lightness + variation)
          .toColor();
    });
  }
}


// Chart data model
class _ChartItem {
  final String name;
  final double amount;
  final int count;

  _ChartItem({
    required this.name,
    required this.amount,
    required this.count,
  });
}