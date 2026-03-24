import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ExchangeRate/model/rate_report_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ExchangeRate/bloc/fx_rate_report_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../Features/Widgets/z_dragable_sheet.dart';

class FxRateReportView extends StatelessWidget {
  const FxRateReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  String? _selectedFromCurrency;
  String? _selectedToCurrency;

  String fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().subtract(const Duration(days: 7)).toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;

  void _onFilterChanged() {
    context.read<FxRateReportBloc>().add(
      LoadFxRateReportEvent(
        fromDate: fromDate,
        toDate: toDate,
        fromCcy: _selectedFromCurrency,
        toCcy: _selectedToCurrency,
      ),
    );
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;

    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      estimatedContentHeight: 400, // Adjust based on content
      bodyBuilder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 8),

                /// 🔹 Date Range
                Row(
                  children: [
                    Expanded(
                      child: ZDatePicker(
                        label: tr.fromDate,
                        value: fromDate,
                        onDateChanged: (v) {
                          setSheetState(() {
                            fromDate = v;
                            shamsiFromDate = v.toAfghanShamsi;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ZDatePicker(
                        label: tr.toDate,
                        value: toDate,
                        onDateChanged: (v) {
                          setSheetState(() {
                            toDate = v;
                            shamsiToDate = v.toAfghanShamsi;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// 🔹 From Currency
                CurrencyDropdown(
                  title: tr.fromCurrency,
                  isMulti: false,
                  onSingleChanged: (e) {
                    setSheetState(() {
                      _selectedFromCurrency = e?.ccyCode;
                    });
                  },
                  onMultiChanged: (e) {},
                ),

                const SizedBox(height: 12),

                /// 🔹 To Currency
                CurrencyDropdown(
                  title: tr.toCurrencyTitle,
                  isMulti: false,
                  onSingleChanged: (e) {
                    setSheetState(() {
                      _selectedToCurrency = e?.ccyCode;
                    });
                  },
                  onMultiChanged: (e) {},
                ),

                const SizedBox(height: 24),

                /// 🔹 Apply Button
                ZOutlineButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _onFilterChanged();
                  },
                  isActive: true,
                  label: Text(tr.applyFilter),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.exchangeRateTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Filters Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${tr.fromDate}: $fromDate",
                      style: TextStyle(fontSize: 11, color: color.primary),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${tr.toDate}: $toDate",
                      style: TextStyle(fontSize: 11, color: color.primary),
                    ),
                  ),
                  if (_selectedFromCurrency != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.secondary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "From: $_selectedFromCurrency",
                        style: TextStyle(fontSize: 11, color: color.secondary),
                      ),
                    ),
                  if (_selectedToCurrency != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.tertiary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "To: $_selectedToCurrency",
                        style: TextStyle(fontSize: 11, color: color.tertiary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Report Content
          Expanded(
            child: BlocConsumer<FxRateReportBloc, FxRateReportState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (state is FxRateReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is FxRateReportErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: color.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: TextStyle(color: color.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is FxRateReportLoadedState) {
                  if (state.rates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.currency_exchange,
                            size: 64,
                            color: color.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No exchange rate data available',
                            style: TextStyle(color: color.outline),
                          ),
                          const SizedBox(height: 24),
                          ZOutlineButton(
                            onPressed: _showFilterBottomSheet,
                            icon: Icons.filter_list,
                            isActive: true,
                            label: Text(tr.applyFilter),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.rates.length,
                    itemBuilder: (context, index) {
                      final rate = state.rates[index];
                      return _buildMobileRateCard(rate, index);
                    },
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.currency_exchange,
                        size: 64,
                        color: color.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select filters to load report',
                        style: TextStyle(color: color.outline),
                      ),
                      const SizedBox(height: 24),
                       ZOutlineButton(
                        onPressed: _showFilterBottomSheet,
                        isActive: true,
                        icon: Icons.filter_list,
                        label: Text(tr.applyFilter),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRateCard(ExchangeRateReportModel rate, int index) {
    final color = Theme.of(context).colorScheme;
    final isSameCurrency = rate.isSameCurrency;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.outline.withValues(alpha: .1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isSameCurrency ? Colors.amber.withValues(alpha: .05) : color.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Same Currency Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(rate.rateDate),
                      style: TextStyle(
                        color: color.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSameCurrency)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Same Currency',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // From Currency
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.secondary.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                rate.fromCode,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                rate.fromName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rate.fromCountry,
                          style: TextStyle(
                            fontSize: 10,
                            color: color.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Arrow
                  Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: color.outline,
                  ),
                  const SizedBox(width: 8),

                  // To Currency
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                rate.toName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.tertiary.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                rate.toCode,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color.tertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rate.toCountry,
                          style: TextStyle(
                            fontSize: 10,
                            color: color.outline,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Rates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exchange Rate',
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rate.displayRate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Avg Rate',
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rate.displayAvgRate,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
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
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  String? _selectedFromCurrency;
  String? _selectedToCurrency;
  bool _showFilters = true;

  String fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().subtract(const Duration(days: 7)).toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;

  void _onFilterChanged() {
    context.read<FxRateReportBloc>().add(
      LoadFxRateReportEvent(
        fromDate: fromDate,
        toDate: toDate,
        fromCcy: _selectedFromCurrency,
        toCcy: _selectedToCurrency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text("FX Rate"),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _onFilterChanged,
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Date Range
                  SizedBox(
                    width: 160,
                    child: ZDatePicker(
                      label: tr.fromDate,
                      value: fromDate,
                      onDateChanged: (v) {
                        setState(() {
                          fromDate = v;
                          shamsiFromDate = v.toAfghanShamsi;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: ZDatePicker(
                      label: tr.toDate,
                      value: toDate,
                      onDateChanged: (v) {
                        setState(() {
                          toDate = v;
                          shamsiToDate = v.toAfghanShamsi;
                        });
                      },
                    ),
                  ),

                  // From Currency
                  SizedBox(
                    width: 180,
                    child: CurrencyDropdown(
                      title: "From Currency",
                      isMulti: false,
                      onSingleChanged: (e) {
                        setState(() {
                          _selectedFromCurrency = e?.ccyCode;
                        });
                      },
                      onMultiChanged: (e) {},
                    ),
                  ),

                  // To Currency
                  SizedBox(
                    width: 180,
                    child: CurrencyDropdown(
                      title: "To Currency",
                      isMulti: false,
                      onSingleChanged: (e) {
                        setState(() {
                          _selectedToCurrency = e?.ccyCode;
                        });
                      },
                      onMultiChanged: (e) {},
                    ),
                  ),

                  // Apply Button
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                      onPressed: _onFilterChanged,
                      child: Text(tr.apply),
                    ),
                  ),
                ],
              ),
            ),

          // Report Content
          Expanded(
            child: BlocConsumer<FxRateReportBloc, FxRateReportState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (state is FxRateReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is FxRateReportErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: color.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: TextStyle(color: color.error),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is FxRateReportLoadedState) {
                  if (state.rates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.currency_exchange,
                            size: 80,
                            color: color.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No exchange rate data available',
                            style: TextStyle(color: color.outline),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: .1),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                          ),
                          child: Row(
                            children: [
                              _buildTableHeader('Date', flex: 1),
                              _buildTableHeader('From Currency', flex: 2),
                              _buildTableHeader('To Currency', flex: 2),
                              _buildTableHeader('Rate', flex: 1),
                              _buildTableHeader('Avg Rate', flex: 1),
                            ],
                          ),
                        ),

                        // Table Body
                        Expanded(
                          child: ListView.separated(
                            itemCount: state.rates.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                            itemBuilder: (context, index) {
                              final rate = state.rates[index];
                              return _buildTabletRow(rate, index);
                            },
                          ),
                        ),

                        // Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border(top: BorderSide(color: Colors.grey[200]!)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Records: ${state.rates.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.currency_exchange,
                        size: 80,
                        color: color.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select filters to load report',
                        style: TextStyle(color: color.outline),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTabletRow(ExchangeRateReportModel rate, int index) {
    final color = Theme.of(context).colorScheme;
    final isEven = index.isEven;
    final isSameCurrency = rate.isSameCurrency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSameCurrency
            ? Colors.amber[50]
            : (isEven ? Colors.grey[50] : Colors.white),
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('MMM dd, yyyy').format(rate.rateDate),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // From Currency
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.secondary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        rate.fromCode,
                        style: TextStyle(
                          fontSize: 11,
                          color: color.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rate.fromSymbol,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rate.fromName,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // To Currency
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.tertiary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        rate.toCode,
                        style: TextStyle(
                          fontSize: 11,
                          color: color.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rate.toSymbol,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rate.toName,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Exchange Rate
          Expanded(
            flex: 1,
            child: Text(
              rate.displayRate,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Average Rate
          Expanded(
            flex: 1,
            child: Text(
              rate.displayAvgRate,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {

  String? _selectedFromCurrency;
  String? _selectedToCurrency;

  String fromDate = DateTime.now().subtract(Duration(days: 7)).toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().subtract(Duration(days: 7)).toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;


  void _onFilterChanged(BuildContext context) {
    context.read<FxRateReportBloc>().add(
      LoadFxRateReportEvent(
        fromDate: fromDate,
        toDate: toDate,
        fromCcy: _selectedFromCurrency,
        toCcy: _selectedToCurrency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(AppLocalizations.of(context)!.exchangeRate),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Filters
            _buildFilterSection(context),
            const SizedBox(height: 30),

            // Report Content
            Expanded(
              child: BlocConsumer<FxRateReportBloc, FxRateReportState>(
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is FxRateReportLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is FxRateReportErrorState) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: color.error),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(color: color.error, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is FxRateReportLoadedState) {
                    return state.rates.isEmpty
                        ? Center(
                      child: Text(
                        'No exchange rate data available',
                        style: TextStyle(fontSize: 16, color: color.outline),
                      ),
                    )
                        : _buildReportTable(state.rates);
                  }

                  return Center(
                    child: Text(
                      'Select date range and currencies to load report',
                      style: TextStyle(fontSize: 16, color: color.outline),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.filterTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .9)
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 8,
          children: [
            Expanded(
              child: ZDatePicker(
                label: tr.fromDate,
                value: fromDate,
                onDateChanged: (v) {
                  setState(() {
                    fromDate = v;
                    shamsiFromDate = v.toAfghanShamsi;
                  });
                  _onFilterChanged(context);
                },
              ),
            ),
            Expanded(
              child: ZDatePicker(
                label: tr.toDate,
                value: toDate,
                onDateChanged: (v) {
                  setState(() {
                    toDate = v;
                    shamsiToDate = v.toAfghanShamsi;
                  });
                  _onFilterChanged(context);
                },
              ),
            ),

            Expanded(
              child: CurrencyDropdown(
                  title: tr.fromCurrency,
                  isMulti: false,
                  onSingleChanged: (e){
                    setState(() {
                      _selectedFromCurrency = e?.ccyCode;
                    });
                  },
                  onMultiChanged: (e){

                  }),
            ),
            Expanded(
              child: CurrencyDropdown(
                  title: tr.toCurrencyTitle,
                  isMulti: false,
                  onSingleChanged: (e){
                    setState(() {
                      _selectedToCurrency = e?.ccyCode;
                    });
                  },
                  onMultiChanged: (e){

                  }),
            ),
            ZOutlineButton(
              width: 120,
                icon: Icons.filter_alt_outlined,
                label: Text(tr.apply),
              isActive: true,
              onPressed: () => _onFilterChanged(context),
            ),

          ],
        ),
      ],
    );
  }

  Widget _buildReportTable(List<ExchangeRateReportModel> rates) {
    final tr = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .05),
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),)),
            ),
            child: Row(
              children: [
                _buildTableHeader(tr.date, flex: 1),
                _buildTableHeader(tr.fromCurrency, flex: 2),
                _buildTableHeader(tr.toCurrencyTitle, flex: 2),
                _buildTableHeader(tr.rate, flex: 1),
                _buildTableHeader(tr.averageTitle, flex: 1),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: rates.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),),
              itemBuilder: (context, index) {
                final rate = rates[index];
                return _buildTableRow(rate);
              },
            ),
          ),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .05),
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: .05),)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Records: ${rates.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: .9),
                  ),
                ),
                Text(
                  'Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: .9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .7),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTableRow(ExchangeRateReportModel rate) {
    final isSameCurrency = rate.isSameCurrency;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSameCurrency ? Colors.amber[50] :  Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              rate.rateDate.toFormattedDate(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildCurrencyInfo(
              code: rate.fromCode,
              name: rate.fromName,
              country: rate.fromCountry,
              symbol: rate.fromSymbol,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildCurrencyInfo(
              code: rate.toCode,
              name: rate.toName,
              country: rate.toCountry,
              symbol: rate.toSymbol,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              rate.displayRate,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              rate.displayAvgRate,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyInfo({
    required String code,
    required String name,
    required String country,
    required String symbol,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              symbol,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          country,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

