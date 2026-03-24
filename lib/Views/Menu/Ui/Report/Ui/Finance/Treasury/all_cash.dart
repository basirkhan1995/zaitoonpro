import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/bloc/cash_balances_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/model/cash_balance_model.dart';
import '../../../../../../../Features/Other/toast.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'Print/cash_print.dart';
import 'Print/feature_model.dart';

class TreasuryView extends StatelessWidget {
  const TreasuryView({super.key});

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
  String? baseCcy;

  @override
  void initState() {
    super.initState();
    context.read<CashBalancesBloc>().add(const LoadAllCashBalancesEvent());
    _loadBaseCurrency();
  }

  void _loadBaseCurrency() {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        baseCcy = authState.loginData.company?.comLocalCcy;
      }
    } catch (e) {
      baseCcy = "";
    }
  }

  Map<String, CurrencyTotal> _calculateCurrencyTotalsForPrint(List<CashBalancesModel> cashList) {
    final Map<String, CurrencyTotal> currencyTotals = {};
    final tempData = <String, Map<String, dynamic>>{};

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          final currencyCode = record.trdCcy ?? 'UNKNOWN';

          if (!tempData.containsKey(currencyCode)) {
            tempData[currencyCode] = {
              'name': record.ccyName ?? currencyCode,
              'symbol': record.ccySymbol ?? '',
              'totalOpening': 0.0,
              'totalClosing': 0.0,
              'totalOpeningSys': 0.0,
              'totalClosingSys': 0.0,
            };
          }

          tempData[currencyCode]!['totalOpening'] +=
              double.tryParse(record.openingBalance ?? '0') ?? 0;
          tempData[currencyCode]!['totalClosing'] +=
              double.tryParse(record.closingBalance ?? '0') ?? 0;
          tempData[currencyCode]!['totalOpeningSys'] +=
              double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          tempData[currencyCode]!['totalClosingSys'] +=
              double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    tempData.forEach((key, value) {
      currencyTotals[key] = CurrencyTotal(
        name: value['name'],
        symbol: value['symbol'],
        totalOpening: value['totalOpening'],
        totalClosing: value['totalClosing'],
        totalOpeningSys: value['totalOpeningSys'],
        totalClosingSys: value['totalClosingSys'],
      );
    });

    return currencyTotals;
  }
  Map<String, double> _calculateSystemTotalsForPrint(List<CashBalancesModel> cashList) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
    };
  }
  Future<void> _printReport() async {
    final state = context.read<CashBalancesBloc>().state;

    if (state is AllCashBalancesLoadedState) {
      // Get company info from CompanyProfileBloc
      final companyState = context.read<CompanyProfileBloc>().state;
      ReportModel company = ReportModel();

      if (companyState is CompanyProfileLoadedState) {
        company = ReportModel(
          comName: companyState.company.comName ?? '',
          comAddress: companyState.company.addName ?? '',
          compPhone: companyState.company.comPhone ?? '',
          comEmail: companyState.company.comEmail ?? '',
          statementDate: DateTime.now().toFullDateTime,
          comLogo: companyState.company.comLogo != null
              ? base64Decode(companyState.company.comLogo!)
              : null,
        );
      }

      // Get base currency from AuthBloc
      String? baseCcy;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        baseCcy = authState.loginData.company?.comLocalCcy;
      }

      // Calculate currency totals
      final currencyTotals = _calculateCurrencyTotalsForPrint(state.cashList);

      // Calculate system totals
      final systemTotals = _calculateSystemTotalsForPrint(state.cashList);

      // Prepare print data
      final printData = CashBalancesPrintData(
        reportType: 'all',
        branches: state.cashList,
        currencyTotals: currencyTotals,
        systemTotal: SystemTotal(
          totalOpeningSys: systemTotals['opening'] ?? 0,
          totalClosingSys: systemTotals['closing'] ?? 0,
        ),
        baseCcy: baseCcy,
        reportDate: DateTime.now(),
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<CashBalancesPrintData>(
            data: printData,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashBalancesPrintSettings().printPreview(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
              );
            },
            onPrint: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return CashBalancesPrintSettings().printDocument(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                copies: copies,
                pages: pages,
              );
            },
            onSave: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashBalancesPrintSettings().createDocument(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      }
    } else {
      ToastManager.show(
          context: context,
          title: "Attention",
          message: "Please load the data first.",
          type: ToastType.warning
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.cashBalances),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CashBalancesBloc>().add(const LoadAllCashBalancesEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReport,
          ),
        ],
      ),
      body: BlocBuilder<CashBalancesBloc, CashBalancesState>(
        builder: (context, state) {
          if (state is CashBalancesLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CashBalancesErrorState) {
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
                      'Error: ${state.error}',
                      style: TextStyle(color: color.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AllCashBalancesLoadedState) {
            if (state.cashList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: color.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No cash balances found',
                      style: TextStyle(color: color.outline),
                    ),
                  ],
                ),
              );
            }

            // Calculate totals
            final currencyTotals = _calculateCurrencyTotals(state.cashList);
            final systemTotals = _calculateSystemTotals(state.cashList);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Cash Balances Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.primary.withValues(alpha: .2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL CASH BALANCES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Currency Totals List
                        ...currencyTotals.entries.map((entry) {
                          final currencyCode = entry.key;
                          final data = entry.value;
                          final symbol = data['symbol'] as String;
                          final totalClosing = data['totalClosing'] as double;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.outline.withValues(alpha: .1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Utils.currencyColors(currencyCode),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        currencyCode,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: color.surface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      data['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${totalClosing.toAmount()} $symbol",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const Divider(height: 16),

                        // Grand Total in System Currency
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Opening (SYS)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color.outline,
                                    ),
                                  ),
                                  Text(
                                    "${systemTotals['opening']?.toAmount()} $baseCcy",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Closing (SYS)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color.outline,
                                    ),
                                  ),
                                  Text(
                                    "${systemTotals['closing']?.toAmount()} $baseCcy",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tr.cashFlow,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color.outline,
                                    ),
                                  ),
                                  Text(
                                    "${systemTotals['cashFlow']?.toAmount()} $baseCcy",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (systemTotals['cashFlow'] ?? 0) >= 0
                                          ? Colors.green
                                          : color.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Branch Wise Section
                  Text(
                    'BRANCH WISE BALANCES',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Branch List
                  ...state.cashList.map((branch) => _buildMobileBranchCard(branch)),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: color.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Load cash balances to view data',
                  style: TextStyle(color: color.outline),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<CashBalancesBloc>().add(const LoadAllCashBalancesEvent());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load Data'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileBranchCard(CashBalancesModel branch) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.primary.withValues(alpha: .1),
          radius: 20,
          child: Icon(
            Icons.business,
            size: 20,
            color: color.primary,
          ),
        ),
        title: Text(
          branch.brcName ?? 'Unnamed Branch',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          branch.brcPhone ?? 'No phone',
          style: TextStyle(
            fontSize: 12,
            color: color.outline,
          ),
        ),
        children: [
          // Branch Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .02),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Info Rows
                _buildMobileInfoRow(
                  Icons.location_on,
                  '${tr.address}:',
                  branch.address ?? 'N/A',
                ),
                const SizedBox(height: 8),
                _buildMobileInfoRow(
                  Icons.calendar_today,
                  '${tr.date}:',
                  branch.brcEntryDate?.toDateTime ?? 'N/A',
                ),
                const SizedBox(height: 8),
                _buildMobileInfoRow(
                  Icons.info,
                  '${tr.status}:',
                  branch.brcStatus == 1 ? tr.active : tr.inactive,
                  valueColor: branch.brcStatus == 1 ? Colors.green : color.error,
                ),

                const SizedBox(height: 12),

                // Records Header
                if (branch.records != null && branch.records!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            tr.currencyTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Opening',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Closing',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Records
                  ...branch.records!.map((record) {
                    final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
                    final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: color.outline.withValues(alpha: .1),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Utils.currencyColors(record.trdCcy ?? ''),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    record.trdCcy ?? '',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: color.surface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    record.ccyName ?? '',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              opening.toAmount(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              closing.toAmount(),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: closing >= 0 ? Colors.green : color.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    final color = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color.outline,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Calculate currency totals across all branches
  Map<String, Map<String, dynamic>> _calculateCurrencyTotals(List<CashBalancesModel> cashList) {
    final Map<String, Map<String, dynamic>> currencyTotals = {};

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          final currencyCode = record.trdCcy ?? 'UNKNOWN';
          final currencyName = record.ccyName ?? currencyCode;
          final symbol = record.ccySymbol ?? '';

          if (!currencyTotals.containsKey(currencyCode)) {
            currencyTotals[currencyCode] = {
              'name': currencyName,
              'symbol': symbol,
              'totalClosing': 0.0,
              'totalOpening': 0.0,
            };
          }

          final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
          final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;

          currencyTotals[currencyCode]!['totalOpening'] =
              (currencyTotals[currencyCode]!['totalOpening'] as double) + opening;
          currencyTotals[currencyCode]!['totalClosing'] =
              (currencyTotals[currencyCode]!['totalClosing'] as double) + closing;
        }
      }
    }

    return currencyTotals;
  }

  // Calculate system equivalent totals across all branches
  Map<String, double> _calculateSystemTotals(List<CashBalancesModel> cashList) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    final totalCashFlowSys = totalClosingSys - totalOpeningSys;

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
      'cashFlow': totalCashFlowSys,
    };
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  String? baseCcy;
  bool _showSummary = true;

  @override
  void initState() {
    super.initState();
    context.read<CashBalancesBloc>().add(const LoadAllCashBalancesEvent());
    _loadBaseCurrency();
  }

  void _loadBaseCurrency() {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        baseCcy = authState.loginData.company?.comLocalCcy;
      }
    } catch (e) {
      baseCcy = "";
    }
  }

  Map<String, CurrencyTotal> _calculateCurrencyTotalsForPrint(List<CashBalancesModel> cashList) {
    final Map<String, CurrencyTotal> currencyTotals = {};
    final tempData = <String, Map<String, dynamic>>{};

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          final currencyCode = record.trdCcy ?? 'UNKNOWN';

          if (!tempData.containsKey(currencyCode)) {
            tempData[currencyCode] = {
              'name': record.ccyName ?? currencyCode,
              'symbol': record.ccySymbol ?? '',
              'totalOpening': 0.0,
              'totalClosing': 0.0,
              'totalOpeningSys': 0.0,
              'totalClosingSys': 0.0,
            };
          }

          tempData[currencyCode]!['totalOpening'] +=
              double.tryParse(record.openingBalance ?? '0') ?? 0;
          tempData[currencyCode]!['totalClosing'] +=
              double.tryParse(record.closingBalance ?? '0') ?? 0;
          tempData[currencyCode]!['totalOpeningSys'] +=
              double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          tempData[currencyCode]!['totalClosingSys'] +=
              double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    tempData.forEach((key, value) {
      currencyTotals[key] = CurrencyTotal(
        name: value['name'],
        symbol: value['symbol'],
        totalOpening: value['totalOpening'],
        totalClosing: value['totalClosing'],
        totalOpeningSys: value['totalOpeningSys'],
        totalClosingSys: value['totalClosingSys'],
      );
    });

    return currencyTotals;
  }
  Map<String, double> _calculateSystemTotalsForPrint(List<CashBalancesModel> cashList) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
    };
  }
  Future<void> _printReport() async {
    final state = context.read<CashBalancesBloc>().state;

    if (state is AllCashBalancesLoadedState) {
      // Get company info from CompanyProfileBloc
      final companyState = context.read<CompanyProfileBloc>().state;
      ReportModel company = ReportModel();

      if (companyState is CompanyProfileLoadedState) {
        company = ReportModel(
          comName: companyState.company.comName ?? '',
          comAddress: companyState.company.addName ?? '',
          compPhone: companyState.company.comPhone ?? '',
          comEmail: companyState.company.comEmail ?? '',
          statementDate: DateTime.now().toFullDateTime,
          comLogo: companyState.company.comLogo != null
              ? base64Decode(companyState.company.comLogo!)
              : null,
        );
      }

      // Get base currency from AuthBloc
      String? baseCcy;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        baseCcy = authState.loginData.company?.comLocalCcy;
      }

      // Calculate currency totals
      final currencyTotals = _calculateCurrencyTotalsForPrint(state.cashList);

      // Calculate system totals
      final systemTotals = _calculateSystemTotalsForPrint(state.cashList);

      // Prepare print data
      final printData = CashBalancesPrintData(
        reportType: 'all',
        branches: state.cashList,
        currencyTotals: currencyTotals,
        systemTotal: SystemTotal(
          totalOpeningSys: systemTotals['opening'] ?? 0,
          totalClosingSys: systemTotals['closing'] ?? 0,
        ),
        baseCcy: baseCcy,
        reportDate: DateTime.now(),
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<CashBalancesPrintData>(
            data: printData,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashBalancesPrintSettings().printPreview(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
              );
            },
            onPrint: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return CashBalancesPrintSettings().printDocument(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                copies: copies,
                pages: pages,
              );
            },
            onSave: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashBalancesPrintSettings().createDocument(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      }
    } else {
      ToastManager.show(
          context: context,
          title: "Attention",
          message: "Please load the data first.",
          type: ToastType.warning
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(AppLocalizations.of(context)!.cashBalances),
        actions: [
          IconButton(
            icon: Icon(_showSummary ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onPressed: () {
              setState(() {
                _showSummary = !_showSummary;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CashBalancesBloc>().add(const LoadAllCashBalancesEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReport,
          ),
        ],
      ),
      body: BlocBuilder<CashBalancesBloc, CashBalancesState>(
        builder: (context, state) {
          if (state is CashBalancesLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CashBalancesErrorState) {
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
                      'Error: ${state.error}',
                      style: TextStyle(color: color.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AllCashBalancesLoadedState) {
            if (state.cashList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 80,
                      color: color.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No cash balances found',
                      style: TextStyle(color: color.outline),
                    ),
                  ],
                ),
              );
            }

            // Calculate totals
            final currencyTotals = _calculateCurrencyTotals(state.cashList);
            final systemTotals = _calculateSystemTotals(state.cashList);

            return CustomScrollView(
              slivers: [
                // Summary Section (Collapsible)
                if (_showSummary)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: .05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.primary.withValues(alpha: .2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL CASH BALANCES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Currency Totals Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: currencyTotals.length,
                            itemBuilder: (context, index) {
                              final entry = currencyTotals.entries.elementAt(index);
                              final data = entry.value;
                              final symbol = data['symbol'] as String;
                              final totalClosing = data['totalClosing'] as double;

                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: color.outline.withValues(alpha: .1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Utils.currencyColors(entry.key),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            entry.key,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: color.surface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            data['name'] as String,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${totalClosing.toAmount()} $symbol",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Grand Total
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Opening (SYS)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color.outline,
                                        ),
                                      ),
                                      Text(
                                        "${systemTotals['opening']?.toAmount()} $baseCcy",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Closing (SYS)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color.outline,
                                        ),
                                      ),
                                      Text(
                                        "${systemTotals['closing']?.toAmount()} $baseCcy",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
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
                                        tr.cashFlow,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color.outline,
                                        ),
                                      ),
                                      Text(
                                        "${systemTotals['cashFlow']?.toAmount()} $baseCcy",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (systemTotals['cashFlow'] ?? 0) >= 0
                                              ? Colors.green
                                              : color.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Branch List
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return _buildTabletBranchCard(state.cashList[index]);
                      },
                      childCount: state.cashList.length,
                    ),
                  ),
                ),
              ],
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: color.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Load cash balances to view data',
                  style: TextStyle(color: color.outline),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<CashBalancesBloc>().add(const LoadAllCashBalancesEvent());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load Data'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabletBranchCard(CashBalancesModel branch) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.primary.withValues(alpha: .1),
          child: Icon(Icons.business, color: color.primary),
        ),
        title: Text(
          branch.brcName ?? 'Unnamed Branch',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.phone,
              size: 12,
              color: color.outline,
            ),
            const SizedBox(width: 4),
            Text(
              branch.brcPhone ?? 'No phone',
              style: TextStyle(color: color.outline),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.location_on,
              size: 12,
              color: color.outline,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                branch.address ?? 'No address',
                style: TextStyle(color: color.outline),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        children: [
          // Records Header
          if (branch.records != null && branch.records!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        tr.currencyTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color.primary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Opening',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Opening (SYS)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Closing',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Closing (SYS)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        tr.cashFlow,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Records
            ...branch.records!.map((record) {
              final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
              final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
              final openingSys = double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
              final closingSys = double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
              final cashFlow = closing - opening;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: color.outline.withValues(alpha: .1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Utils.currencyColors(record.trdCcy ?? ''),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                record.trdCcy ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color.surface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                record.ccyName ?? '',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${opening.toAmount()} ${record.ccySymbol}",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${openingSys.toAmount()} $baseCcy",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${closing.toAmount()} ${record.ccySymbol}",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${closingSys.toAmount()} $baseCcy",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          "${cashFlow.toAmount()} ${record.ccySymbol}",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cashFlow >= 0 ? Colors.green : color.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // Calculate currency totals across all branches
  Map<String, Map<String, dynamic>> _calculateCurrencyTotals(List<CashBalancesModel> cashList) {
    final Map<String, Map<String, dynamic>> currencyTotals = {};

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          final currencyCode = record.trdCcy ?? 'UNKNOWN';
          final currencyName = record.ccyName ?? currencyCode;
          final symbol = record.ccySymbol ?? '';

          if (!currencyTotals.containsKey(currencyCode)) {
            currencyTotals[currencyCode] = {
              'name': currencyName,
              'symbol': symbol,
              'totalClosing': 0.0,
              'totalOpening': 0.0,
            };
          }

          final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
          final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;

          currencyTotals[currencyCode]!['totalOpening'] =
              (currencyTotals[currencyCode]!['totalOpening'] as double) + opening;
          currencyTotals[currencyCode]!['totalClosing'] =
              (currencyTotals[currencyCode]!['totalClosing'] as double) + closing;
        }
      }
    }

    return currencyTotals;
  }

  // Calculate system equivalent totals across all branches
  Map<String, double> _calculateSystemTotals(List<CashBalancesModel> cashList) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    final totalCashFlowSys = totalClosingSys - totalOpeningSys;

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
      'cashFlow': totalCashFlowSys,
    };
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  String? baseCcy;

  @override
  void initState() {
    super.initState();
    context.read<CashBalancesBloc>().add(const LoadAllCashBalancesEvent());
    _loadBaseCurrency();
  }

  void _loadBaseCurrency() {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        baseCcy = authState.loginData.company?.comLocalCcy;
      }
    } catch (e) {
      baseCcy = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cashBalances),
        titleSpacing: 0,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        actions: [
          IconButton(
            onPressed: () {
              context.read<CashBalancesBloc>().add(const LoadAllCashBalancesEvent());
            },
            icon: Icon(Icons.refresh),
          ),
          const SizedBox(width: 5),
          IconButton(
            onPressed: _printReport,
            icon: Icon(Icons.print),
          ),


        ],
      ),
      body: BlocBuilder<CashBalancesBloc, CashBalancesState>(
        builder: (context, state) {
          if (state is CashBalancesLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CashBalancesErrorState) {
            return Center(
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is AllCashBalancesLoadedState) {
            if (state.cashList.isEmpty) {
              return const Center(
                child: Text('No cash balances found'),
              );
            }

            // Calculate all totals
            final currencyTotals = _calculateCurrencyTotals(state.cashList);
            final systemTotals = _calculateSystemTotals(state.cashList);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP SECTION: General Currency Totals
                  _buildGeneralTotalsSection(currencyTotals, systemTotals),
                  const SizedBox(height: 20),

                  // BOTTOM SECTION: Branch List
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'CASH BALANCES - BRANCH WISE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  _buildCashBalancesList(state.cashList),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Map<String, CurrencyTotal> _calculateCurrencyTotalsForPrint(List<CashBalancesModel> cashList) {
    final Map<String, CurrencyTotal> currencyTotals = {};
    final tempData = <String, Map<String, dynamic>>{};

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          final currencyCode = record.trdCcy ?? 'UNKNOWN';

          if (!tempData.containsKey(currencyCode)) {
            tempData[currencyCode] = {
              'name': record.ccyName ?? currencyCode,
              'symbol': record.ccySymbol ?? '',
              'totalOpening': 0.0,
              'totalClosing': 0.0,
              'totalOpeningSys': 0.0,
              'totalClosingSys': 0.0,
            };
          }

          tempData[currencyCode]!['totalOpening'] +=
              double.tryParse(record.openingBalance ?? '0') ?? 0;
          tempData[currencyCode]!['totalClosing'] +=
              double.tryParse(record.closingBalance ?? '0') ?? 0;
          tempData[currencyCode]!['totalOpeningSys'] +=
              double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          tempData[currencyCode]!['totalClosingSys'] +=
              double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    tempData.forEach((key, value) {
      currencyTotals[key] = CurrencyTotal(
        name: value['name'],
        symbol: value['symbol'],
        totalOpening: value['totalOpening'],
        totalClosing: value['totalClosing'],
        totalOpeningSys: value['totalOpeningSys'],
        totalClosingSys: value['totalClosingSys'],
      );
    });

    return currencyTotals;
  }
  Map<String, double> _calculateSystemTotalsForPrint(List<CashBalancesModel> cashList) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
    };
  }
  Future<void> _printReport() async {
    final state = context.read<CashBalancesBloc>().state;

    if (state is AllCashBalancesLoadedState) {
      // Get company info from CompanyProfileBloc
      final companyState = context.read<CompanyProfileBloc>().state;
      ReportModel company = ReportModel();

      if (companyState is CompanyProfileLoadedState) {
        company = ReportModel(
          comName: companyState.company.comName ?? '',
          comAddress: companyState.company.addName ?? '',
          compPhone: companyState.company.comPhone ?? '',
          comEmail: companyState.company.comEmail ?? '',
          statementDate: DateTime.now().toFullDateTime,
          comLogo: companyState.company.comLogo != null
              ? base64Decode(companyState.company.comLogo!)
              : null,
        );
      }

      // Get base currency from AuthBloc
      String? baseCcy;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        baseCcy = authState.loginData.company?.comLocalCcy;
      }

      // Calculate currency totals
      final currencyTotals = _calculateCurrencyTotalsForPrint(state.cashList);

      // Calculate system totals
      final systemTotals = _calculateSystemTotalsForPrint(state.cashList);

      // Prepare print data
      final printData = CashBalancesPrintData(
        reportType: 'all',
        branches: state.cashList,
        currencyTotals: currencyTotals,
        systemTotal: SystemTotal(
          totalOpeningSys: systemTotals['opening'] ?? 0,
          totalClosingSys: systemTotals['closing'] ?? 0,
        ),
        baseCcy: baseCcy,
        reportDate: DateTime.now(),
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<CashBalancesPrintData>(
            data: printData,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashBalancesPrintSettings().printPreview(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
              );
            },
            onPrint: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return CashBalancesPrintSettings().printDocument(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                copies: copies,
                pages: pages,
              );
            },
            onSave: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashBalancesPrintSettings().createDocument(
                printData: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      }
    } else {
      ToastManager.show(
          context: context,
          title: "Attention",
          message: "Please load the data first.",
          type: ToastType.warning
      );
    }
  }

  Map<String, Map<String, dynamic>> _calculateCurrencyTotals(List<CashBalancesModel> cashList) {
    final Map<String, Map<String, dynamic>> currencyTotals = {};

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          final currencyCode = record.trdCcy ?? 'UNKNOWN';
          final currencyName = record.ccyName ?? currencyCode;
          final symbol = record.ccySymbol ?? '';

          if (!currencyTotals.containsKey(currencyCode)) {
            currencyTotals[currencyCode] = {
              'name': currencyName,
              'symbol': symbol,
              'totalClosing': 0.0,
              'totalOpening': 0.0,
            };
          }

          final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
          final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;

          currencyTotals[currencyCode]!['totalOpening'] =
              (currencyTotals[currencyCode]!['totalOpening'] as double) + opening;
          currencyTotals[currencyCode]!['totalClosing'] =
              (currencyTotals[currencyCode]!['totalClosing'] as double) + closing;
        }
      }
    }

    return currencyTotals;
  }
  Map<String, double> _calculateSystemTotals(List<CashBalancesModel> cashList) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    for (var branch in cashList) {
      if (branch.records != null) {
        for (var record in branch.records!) {
          totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
        }
      }
    }

    final totalCashFlowSys = totalClosingSys - totalOpeningSys;

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
      'cashFlow': totalCashFlowSys,
    };
  }
  Widget _buildGeneralTotalsSection(Map<String, Map<String, dynamic>> currencyTotals, Map<String, double> systemTotals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            AppLocalizations.of(context)!.totalCashBalancesAllBranch.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),

        // Currency Total Cards - Responsive Grid
        _buildCurrencyTotalsGrid(currencyTotals),

        // Grand Total Card (System Equivalent)
        const SizedBox(height: 16),
        _buildGrandTotalCard(systemTotals),
      ],
    );
  }
  Widget _buildCurrencyTotalsGrid(Map<String, Map<String, dynamic>> currencyTotals) {
    // Determine grid column count based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;

        if (screenWidth > 1400) {
          crossAxisCount = 5;
        } else if (screenWidth > 1100) {
          crossAxisCount = 4;
        } else if (screenWidth > 800) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0, // Wider cards
          ),
          itemCount: currencyTotals.length,
          itemBuilder: (context, index) {
            final entry = currencyTotals.entries.elementAt(index);
            final currencyCode = entry.key;
            final data = entry.value;
            final currencyName = data['name'] as String;
            final symbol = data['symbol'] as String;
            final totalOpening = data['totalOpening'] as double;
            final totalClosing = data['totalClosing'] as double;
            final cashFlow = totalClosing - totalOpening;

            // Different colors for different currencies
            final colors = [
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
              Colors.red,
              Colors.teal,
              Colors.amber,
              Colors.indigo,
            ];
            final color = colors[index % colors.length];

            return ZCover(
              color: color.withValues(alpha: .05),
              radius: 8,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Currency Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currencyName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                       ZCover(
                           color: Utils.currencyColors(currencyCode),
                           child: Text(currencyCode,style: TextStyle(color: Theme.of(context).colorScheme.surface),))
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Opening Balance
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Opening',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        Text(
                          "${totalOpening.toAmount()} $symbol",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Closing Balance
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Closing',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        Text(
                          "${totalClosing.toAmount()} $symbol",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Cash Flow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.cashFlow,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Text(
                          "${cashFlow.toAmount()} $symbol",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cashFlow >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildGrandTotalCard(Map<String, double> systemTotals) {
    return ZCover(
      color: Colors.purple.withValues(alpha: .05),
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GRAND TOTAL CASH FLOW',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.purple,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'System Equivalent ($baseCcy)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),

            const SizedBox(height: 16),

            // Totals in a row
            Row(
              children: [
                Expanded(
                  child: _buildTotalItem(
                    label: AppLocalizations.of(context)!.openingBalance,
                    value: systemTotals['opening']!,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTotalItem(
                    label: 'Closing Balance',
                    value: systemTotals['closing']!,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTotalItem(
                    label: AppLocalizations.of(context)!.cashFlow,
                    value: systemTotals['cashFlow']!,
                    color: systemTotals['cashFlow']! >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTotalItem({required String label, required double value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value.toAmount(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              baseCcy ?? '',
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: .8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildCashBalancesList(List<CashBalancesModel> cashList) {
    return Column(
      children: List.generate(cashList.length, (index) {
        final branch = cashList[index];
        return _buildBranchCard(branch);
      }),
    );
  }
  Widget _buildBranchCard(CashBalancesModel branch) {
    final tr = AppLocalizations.of(context)!;
    return ZCover(
      margin: const EdgeInsets.only(bottom: 10),
      radius: 8,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: .1),
          child: Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          branch.brcName ?? 'Unnamed Branch',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${tr.branch}: ${branch.brcId} | ${tr.mobile1}: ${branch.brcPhone ?? 'N/A'}',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch Information
                _buildInfoRow('${tr.address}:', branch.address ?? 'N/A'),
                _buildInfoRow('${tr.status}:', branch.brcStatus == 1 ? tr.active : tr.inactive),
                _buildInfoRow('${tr.date}:', branch.brcEntryDate?.toDateTime ?? 'N/A'),
                const SizedBox(height: 20),

                // Records Section
                if (branch.records != null && branch.records!.isNotEmpty)
                  _buildRecordsList(branch.records!),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: Text(value),
            ),
          ],
        )
    );
  }
  Widget _buildRecordsList(List<Record> records) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    // Calculate branch totals for SYS equivalent
    double branchOpeningSys = 0;
    double branchClosingSys = 0;

    for (var record in records) {
      branchOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
      branchClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
    }

    final branchCashFlowSys = branchClosingSys - branchOpeningSys;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: .1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  tr.currencyTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  tr.openingBalance,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Opening (SYS)',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Closing Balance',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Closing (SYS)',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  tr.cashFlow,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Records Items
        ...records.map((record) {
          final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
          final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
          final openingSys = double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          final closingSys = double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
          final cashFlow = closing - opening;
        //  final cashFlowSys = closingSys - openingSys;

          return Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: color.outline.withValues(alpha: .05),
              border: Border.all(color: color.outline.withValues(alpha: .1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${record.ccyName} (${record.trdCcy})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${opening.toAmount()} ${record.ccySymbol}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${openingSys.toAmount()} $baseCcy",
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${closing.toAmount()} ${record.ccySymbol}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${closingSys.toAmount()} $baseCcy",
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${cashFlow.toAmount()} ${record.ccySymbol}",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cashFlow >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Branch Grand Total Row (Added at the end)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: .1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(3),
              bottomRight: Radius.circular(3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '${tr.grandTotal} ($baseCcy)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  "", // Empty for Opening Balance column
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  "${branchOpeningSys.toAmount()} $baseCcy",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  "", // Empty for Closing Balance column
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  "${branchClosingSys.toAmount()} $baseCcy",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  "",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: branchCashFlowSys >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

