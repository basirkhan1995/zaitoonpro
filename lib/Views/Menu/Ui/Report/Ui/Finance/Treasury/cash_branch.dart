import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/cover.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/HR/Ui/Users/features/branch_dropdown.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Finance/Treasury/bloc/cash_balances_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Finance/Treasury/model/cash_balance_model.dart';
import '../../../../../../../Features/Other/toast.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'Print/cash_print.dart';
import 'Print/feature_model.dart';

class CashBalancesBranchWiseView extends StatelessWidget {
  const CashBalancesBranchWiseView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Mobile(),
      desktop: _Desktop(),
      tablet: _Tablet(),
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  String? baseCcy;
  int? branchId;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }
  void _loadBalances() {
    try {
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthenticatedState) {
        branchId = auth.loginData.usrBranch;
        baseCcy = auth.loginData.company?.comLocalCcy;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CashBalancesBloc>().add(
            LoadCashBalanceBranchWiseEvent(branchId: branchId),
          );
        });
      }
    } catch (e) {
      branchId = null;
    }
  }
  Future<void> _printBranchBalance() async {
    final state = context.read<CashBalancesBloc>().state;

    if (state is CashBalancesLoadedState) {
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

      // Calculate currency totals for single branch
      final currencyTotals = _calculateSingleBranchCurrencyTotals(state.cash);

      // Calculate system totals for single branch
      final systemTotals = _calculateSingleBranchSystemTotals(state.cash);

      // Prepare print data
      final printData = CashBalancesPrintData(
        reportType: 'single',
        branches: [state.cash],
        currencyTotals: currencyTotals,
        systemTotal: SystemTotal(
          totalOpeningSys: systemTotals['opening'] ?? 0,
          totalClosingSys: systemTotals['closing'] ?? 0,
        ),
        baseCcy: baseCcy,
        reportDate: DateTime.now(),
        selectedBranchName: state.cash.brcName,
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
  Map<String, CurrencyTotal> _calculateSingleBranchCurrencyTotals(CashBalancesModel branch) {
    final Map<String, CurrencyTotal> currencyTotals = {};

    if (branch.records != null) {
      for (var record in branch.records!) {
        final currencyCode = record.trdCcy ?? 'UNKNOWN';

        currencyTotals[currencyCode] = CurrencyTotal(
          name: record.ccyName ?? currencyCode,
          symbol: record.ccySymbol ?? '',
          totalOpening: double.tryParse(record.openingBalance ?? '0') ?? 0,
          totalClosing: double.tryParse(record.closingBalance ?? '0') ?? 0,
          totalOpeningSys: double.tryParse(record.openingSysEquivalent ?? '0') ?? 0,
          totalClosingSys: double.tryParse(record.closingSysEquivalent ?? '0') ?? 0,
        );
      }
    }

    return currencyTotals;
  }
  Map<String, double> _calculateSingleBranchSystemTotals(CashBalancesModel branch) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    if (branch.records != null) {
      for (var record in branch.records!) {
        totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
        totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
      }
    }

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
    };
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cashBalances),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CashBalancesBloc>().add(
                LoadCashBalanceBranchWiseEvent(branchId: branchId),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printBranchBalance,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<CashBalancesBloc, CashBalancesState>(
      builder: (context, state) {
        if (state is CashBalancesLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CashBalancesErrorState) {
          return Center(
            child: NoDataWidget(
              message: state.error,
              onRefresh: () {
                context.read<CashBalancesBloc>().add(
                  LoadCashBalanceBranchWiseEvent(branchId: branchId),
                );
              },
            ),
          );
        }

        if (state is CashBalancesLoadedState) {
          return _buildBranchDetails(state.cash);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildBranchDetails(CashBalancesModel branch) {
    final tr = AppLocalizations.of(context)!;

    // Calculate branch totals
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    if (branch.records != null) {
      for (var record in branch.records!) {
        totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
        totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
      }
    }

    final totalCashFlowSys = totalClosingSys - totalOpeningSys;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch Information Card
          _buildBranchInfoCard(branch, tr),

          const SizedBox(height: 20),

          // Currency Balances Section
          _buildCurrencyBalancesSection(branch, tr),

          const SizedBox(height: 20),

          // Grand Total Card
          _buildGrandTotalCard(
            totalOpeningSys,
            totalClosingSys,
            totalCashFlowSys,
            tr,
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfoCard(CashBalancesModel branch, AppLocalizations tr) {
    return ZCover(
      color: Theme.of(context).colorScheme.surface,
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr.branchInformation,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: BranchDropdown(
                    selectedId: branchId,
                    disableAction: true,
                    height: 40,
                    title: "",
                    onBranchSelected: (e) {
                      final newBranchId = e?.brcId;
                      setState(() {
                        branchId = newBranchId;
                      });
                      context.read<CashBalancesBloc>().add(
                        LoadCashBalanceBranchWiseEvent(branchId: newBranchId),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            _buildInfoRow('${tr.branchId}:', branch.brcId?.toString() ?? 'N/A'),
            _buildInfoRow('${tr.branchName}:', branch.brcName ?? 'N/A'),
            _buildInfoRow('${tr.address}:', branch.address ?? 'N/A'),
            _buildInfoRow('${tr.mobile1}:', branch.brcPhone ?? 'N/A'),
            _buildInfoRow('${tr.status}:',
                branch.brcStatus == 1 ? tr.active : tr.inactive),
            _buildInfoRow('${tr.entryDate}:',
                branch.brcEntryDate?.toLocal().toString().split(' ')[0] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBalancesSection(CashBalancesModel branch, AppLocalizations tr) {
    if (branch.records == null || branch.records!.isEmpty) {
      return Center(
        child: Text(
          'No cash records found',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.currencyBalances,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 4 :
            constraints.maxWidth > 800 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: branch.records!.length,
              itemBuilder: (context, index) {
                final record = branch.records![index];
                return _buildCurrencyCard(record, tr);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrencyCard(Record record, AppLocalizations tr) {
    final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
    final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
    final openingSys = double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
    final closingSys = double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
    final cashFlow = closing - opening;
    final cashFlowSys = closingSys - openingSys;

    return ZCover(
      color: Theme.of(context).colorScheme.surface,
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Currency Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record.ccyName ?? record.trdCcy ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Utils.currencyColors(record.trdCcy ?? ""),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Utils.currencyColors(record.trdCcy ?? ''),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    record.trdCcy ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildBalanceRow(
              label: tr.opening,
              amount: opening,
              symbol: record.trdCcy ?? '',
              isSys: false,
            ),
            const SizedBox(height: 2),
            _buildBalanceRow(
              label: tr.closing,
              amount: closing,
              symbol: record.trdCcy ?? '',
              isSys: false,
              isClosing: true,
            ),
            const Divider(height: 12),
            _buildBalanceRow(
              label: '${tr.opening} (Sys)',
              amount: openingSys,
              symbol: baseCcy ?? '',
              isSys: true,
            ),
            const SizedBox(height: 2),
            _buildBalanceRow(
              label: '${tr.closing} (Sys)',
              amount: closingSys,
              symbol: baseCcy ?? '',
              isSys: true,
              isClosing: true,
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.cashFlow,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${cashFlow.toAmount()} ${record.trdCcy}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cashFlow >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      "${cashFlowSys.toAmount()} $baseCcy",
                      style: TextStyle(
                        fontSize: 11,
                        color: cashFlowSys >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow({
    required String label,
    required double amount,
    required String symbol,
    required bool isSys,
    bool isClosing = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Flexible(
          child: Text(
            "${amount.toAmount()} $symbol",
            style: TextStyle(
              fontSize: 13,
              fontWeight: isClosing ? FontWeight.bold : FontWeight.w500,
              color: isClosing
                  ? (isSys ? Colors.purple : Colors.green)
                  : Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildGrandTotalCard(
      double openingSys,
      double closingSys,
      double cashFlowSys,
      AppLocalizations tr,
      ) {
    return ZCover(
      color: Colors.purple.withValues(alpha: .05),
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tr.branch.toUpperCase()} | ${tr.grandTotal.toUpperCase()} (${tr.systemEquivalent})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      _buildTotalItem(
                        label: tr.openingBalance,
                        value: openingSys,
                        color: Theme.of(context).colorScheme.outline,
                        symbol: baseCcy ?? '',
                      ),
                      const SizedBox(height: 12),
                      _buildTotalItem(
                        label: tr.closingBalance,
                        value: closingSys,
                        color: Colors.green,
                        symbol: baseCcy ?? '',
                      ),
                      const SizedBox(height: 12),
                      _buildTotalItem(
                        label: tr.cashFlow,
                        value: cashFlowSys,
                        color: cashFlowSys >= 0 ? Colors.green : Colors.red,
                        symbol: baseCcy ?? '',
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildTotalItem(
                        label: tr.openingBalance,
                        value: openingSys,
                        color: Theme.of(context).colorScheme.outline,
                        symbol: baseCcy ?? '',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTotalItem(
                        label: tr.closingBalance,
                        value: closingSys,
                        color: Colors.green,
                        symbol: baseCcy ?? '',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTotalItem(
                        label: tr.cashFlow,
                        value: cashFlowSys,
                        color: cashFlowSys >= 0 ? Colors.green : Colors.red,
                        symbol: baseCcy ?? '',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem({
    required String label,
    required double value,
    required Color color,
    required String symbol,
  }) {
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
            Flexible(
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
            const SizedBox(width: 4),
            Text(
              symbol,
              style: TextStyle(
                fontSize: 14,
                color: color.withValues(alpha: .8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }


}


class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  String? baseCcy;
  int? branchId;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }
  void _loadBalances() {
    try {
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthenticatedState) {
        branchId = auth.loginData.usrBranch;
        baseCcy = auth.loginData.company?.comLocalCcy;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CashBalancesBloc>().add(
            LoadCashBalanceBranchWiseEvent(branchId: branchId),
          );
        });
      }
    } catch (e) {
      branchId = null;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cashBalances),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBalances,
          ),
          SizedBox(width: 5),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printBranchBalance,
          ),
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<CashBalancesBloc, CashBalancesState>(
      builder: (context, state) {
        if (state is CashBalancesLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CashBalancesErrorState) {
          return Center(
            child: NoDataWidget(
              message: state.error,
              title: "Error",
              enableAction: false,
            ),
          );
        }

        if (state is CashBalancesLoadedState) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildBranchDetails(state.cash, context),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildBranchDetails(CashBalancesModel branch, BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBranchInfoCard(branch, tr, context),
          const SizedBox(height: 16),
          Text(
            tr.currencyBalances,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildCurrencyCards(branch, tr, context),
          const SizedBox(height: 16),
          _buildTotalsCard(branch, tr, context),
        ],
      ),
    );
  }

  Widget _buildBranchInfoCard(CashBalancesModel branch, AppLocalizations tr, BuildContext context) {
    return ZCover(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch.brcName ?? 'Unknown Branch',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildTabletInfoChip('${tr.branchId}:', branch.brcId?.toString() ?? 'N/A'),
                _buildTabletInfoChip(tr.address, branch.address ?? 'N/A'),
                _buildTabletInfoChip(tr.mobile1, branch.brcPhone ?? 'N/A'),
                _buildTabletInfoChip(
                  tr.status,
                  branch.brcStatus == 1 ? tr.active : tr.inactive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCards(CashBalancesModel branch, AppLocalizations tr, BuildContext context) {
    if (branch.records == null || branch.records!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No cash records found',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: branch.records!.length,
          itemBuilder: (context, index) {
            return _buildTabletCurrencyCard(branch.records![index], context, tr);
          },
        );
      },
    );
  }

  Widget _buildTabletCurrencyCard(Record record, BuildContext context, AppLocalizations tr) {
    final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
    final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
    final cashFlow = closing - opening;

    return ZCover(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record.ccyName ?? record.trdCcy ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Utils.currencyColors(record.trdCcy ?? ''),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    record.trdCcy ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            _buildTabletBalanceRow(tr.opening, opening, record.trdCcy ?? ''),
            const SizedBox(height: 2),
            _buildTabletBalanceRow(tr.closing, closing, record.trdCcy ?? ''),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.cashFlow,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "${cashFlow.toAmount()} ${record.trdCcy}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cashFlow >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletBalanceRow(String label, double amount, String symbol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Flexible(
          child: Text(
            "${amount.toAmount()} $symbol",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard(CashBalancesModel branch, AppLocalizations tr, BuildContext context) {
    double totalOpening = 0;
    double totalClosing = 0;

    if (branch.records != null) {
      for (var record in branch.records!) {
        totalOpening += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
        totalClosing += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
      }
    }

    final totalCashFlow = totalClosing - totalOpening;

    return ZCover(
      color: Colors.purple.withValues(alpha: .05),
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.grandTotal,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTabletTotalItem(tr.opening, totalOpening),
                ),
                Expanded(
                  child: _buildTabletTotalItem(tr.closing, totalClosing),
                ),
                Expanded(
                  child: _buildTabletTotalItem(tr.cashFlow, totalCashFlow,
                      isCashFlow: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletTotalItem(String label, double value, {bool isCashFlow = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toAmount(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isCashFlow
                ? (value >= 0 ? Colors.green : Colors.red)
                : Colors.purple,
          ),
        ),
      ],
    );
  }

  Future<void> _printBranchBalance() async {
    final state = context.read<CashBalancesBloc>().state;

    if (state is CashBalancesLoadedState) {
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

      // Calculate currency totals for single branch
      final currencyTotals = _calculateSingleBranchCurrencyTotals(state.cash);

      // Calculate system totals for single branch
      final systemTotals = _calculateSingleBranchSystemTotals(state.cash);

      // Prepare print data
      final printData = CashBalancesPrintData(
        reportType: 'single',
        branches: [state.cash],
        currencyTotals: currencyTotals,
        systemTotal: SystemTotal(
          totalOpeningSys: systemTotals['opening'] ?? 0,
          totalClosingSys: systemTotals['closing'] ?? 0,
        ),
        baseCcy: baseCcy,
        reportDate: DateTime.now(),
        selectedBranchName: state.cash.brcName,
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

  Map<String, CurrencyTotal> _calculateSingleBranchCurrencyTotals(CashBalancesModel branch) {
    final Map<String, CurrencyTotal> currencyTotals = {};

    if (branch.records != null) {
      for (var record in branch.records!) {
        final currencyCode = record.trdCcy ?? 'UNKNOWN';

        currencyTotals[currencyCode] = CurrencyTotal(
          name: record.ccyName ?? currencyCode,
          symbol: record.ccySymbol ?? '',
          totalOpening: double.tryParse(record.openingBalance ?? '0') ?? 0,
          totalClosing: double.tryParse(record.closingBalance ?? '0') ?? 0,
          totalOpeningSys: double.tryParse(record.openingSysEquivalent ?? '0') ?? 0,
          totalClosingSys: double.tryParse(record.closingSysEquivalent ?? '0') ?? 0,
        );
      }
    }

    return currencyTotals;
  }

  Map<String, double> _calculateSingleBranchSystemTotals(CashBalancesModel branch) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    if (branch.records != null) {
      for (var record in branch.records!) {
        totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
        totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
      }
    }

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
    };
  }
}


class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  String? baseCcy;
  int? branchId;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }
  void _loadBalances() {
    try {
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthenticatedState) {
        branchId = auth.loginData.usrBranch;
        baseCcy = auth.loginData.company?.comLocalCcy;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CashBalancesBloc>().add(
            LoadCashBalanceBranchWiseEvent(branchId: branchId),
          );
        });
      }
    } catch (e) {
      branchId = null;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.cashBalances,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
             context.read<CashBalancesBloc>().add(LoadCashBalanceBranchWiseEvent(branchId: branchId));
            },
          ),
          SizedBox(width: 5),
          IconButton(onPressed: _printBranchBalance, icon: Icon(Icons.print))
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<CashBalancesBloc, CashBalancesState>(
      builder: (context, state) {
        if (state is CashBalancesLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CashBalancesErrorState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NoDataWidget(
                message: state.error,
                onRefresh: () {
                  // Add refresh logic
                },
              ),
            ),
          );
        }

        if (state is CashBalancesLoadedState) {
          return _buildMobileDetails(state.cash, context);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildMobileDetails(CashBalancesModel branch, BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(12.0),
      children: [
        // Branch Info Card
        ZCover(
          radius: 8,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        branch.brcName ?? 'Unknown Branch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: branch.brcStatus == 1 ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        branch.brcStatus == 1 ? tr.active : tr.inactive,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMobileInfoRow(Icons.badge, '${tr.branchId}:', branch.brcId?.toString() ?? 'N/A'),
                const SizedBox(height: 8),
                _buildMobileInfoRow(Icons.location_on, tr.address, branch.address ?? 'N/A'),
                const SizedBox(height: 8),
                _buildMobileInfoRow(Icons.phone, tr.mobile1, branch.brcPhone ?? 'N/A'),
                const SizedBox(height: 8),
                _buildMobileInfoRow(Icons.calendar_today, tr.entryDate,
                    branch.brcEntryDate?.toLocal().toString().split(' ')[0] ?? 'N/A'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Currency Balances Section
        Text(
          tr.currencyBalances,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        const SizedBox(height: 12),

        if (branch.records != null && branch.records!.isNotEmpty)
          ...branch.records!.map((record) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildMobileCurrencyCard(record, context, tr),
          ))
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No cash records found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Grand Total Card
        _buildMobileGrandTotal(branch, context, tr),
      ],
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String label, String value) {
    final color = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color.outline),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: color.onSurface, fontSize: 13),
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' $value'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCurrencyCard(Record record, BuildContext context, AppLocalizations tr) {
    final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
    final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
    final openingSys = double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
    final closingSys = double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
    final cashFlow = closing - opening;
    final cashFlowSys = closingSys - openingSys;

    return ZCover(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.ccyName ?? record.trdCcy ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Utils.currencyColors(record.trdCcy ?? ""),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Utils.currencyColors(record.trdCcy ?? ''),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    record.trdCcy ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Local Currency Balances
            Row(
              children: [
                Expanded(
                  child: _buildMobileLabelValue(
                    tr.opening,
                    "${opening.toAmount()} ${record.trdCcy}",
                  ),
                ),
                Expanded(
                  child: _buildMobileLabelValue(
                    tr.closing,
                    "${closing.toAmount()} ${record.trdCcy}",
                    isHighlighted: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // System Equivalent
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMobileLabelValue(
                      '${tr.opening} (Sys)',
                      "${openingSys.toAmount()} ${baseCcy ?? ''}",
                    ),
                  ),
                  Expanded(
                    child: _buildMobileLabelValue(
                      '${tr.closing} (Sys)',
                      "${closingSys.toAmount()} ${baseCcy ?? ''}",
                      isHighlighted: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Cash Flow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (cashFlow >= 0 ? Colors.green : Colors.red).withValues(alpha: .05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.cashFlow,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${cashFlow.toAmount()} ${record.trdCcy}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cashFlow >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        "${cashFlowSys.toAmount()} ${baseCcy ?? ''}",
                        style: TextStyle(
                          fontSize: 11,
                          color: cashFlowSys >= 0 ? Colors.green : Colors.red,
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
    );
  }

  Widget _buildMobileLabelValue(String label, String value, {bool isHighlighted = false}) {
    final color = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.outline.withValues(alpha: .6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Colors.green : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMobileGrandTotal(CashBalancesModel branch, BuildContext context, AppLocalizations tr) {
    double totalOpening = 0;
    double totalClosing = 0;

    if (branch.records != null) {
      for (var record in branch.records!) {
        totalOpening += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
        totalClosing += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
      }
    }

    final totalCashFlow = totalClosing - totalOpening;

    return ZCover(
      color: Colors.purple.withValues(alpha: .05),
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.grandTotal,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildMobileTotalRow(tr.openingBalance, totalOpening, ''),
            const SizedBox(height: 8),
            _buildMobileTotalRow(tr.closingBalance, totalClosing, ''),
            const SizedBox(height: 8),
            _buildMobileTotalRow(tr.cashFlow, totalCashFlow, '', isCashFlow: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTotalRow(String label, double value, String symbol, {bool isCashFlow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value.toAmount(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isCashFlow
                ? (value >= 0 ? Colors.green : Colors.red)
                : Colors.purple,
          ),
        ),
      ],
    );
  }

  Future<void> _printBranchBalance() async {
    final state = context.read<CashBalancesBloc>().state;

    if (state is CashBalancesLoadedState) {
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

      // Calculate currency totals for single branch
      final currencyTotals = _calculateSingleBranchCurrencyTotals(state.cash);

      // Calculate system totals for single branch
      final systemTotals = _calculateSingleBranchSystemTotals(state.cash);

      // Prepare print data
      final printData = CashBalancesPrintData(
        reportType: 'single',
        branches: [state.cash],
        currencyTotals: currencyTotals,
        systemTotal: SystemTotal(
          totalOpeningSys: systemTotals['opening'] ?? 0,
          totalClosingSys: systemTotals['closing'] ?? 0,
        ),
        baseCcy: baseCcy,
        reportDate: DateTime.now(),
        selectedBranchName: state.cash.brcName,
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
  Map<String, CurrencyTotal> _calculateSingleBranchCurrencyTotals(CashBalancesModel branch) {
    final Map<String, CurrencyTotal> currencyTotals = {};

    if (branch.records != null) {
      for (var record in branch.records!) {
        final currencyCode = record.trdCcy ?? 'UNKNOWN';

        currencyTotals[currencyCode] = CurrencyTotal(
          name: record.ccyName ?? currencyCode,
          symbol: record.ccySymbol ?? '',
          totalOpening: double.tryParse(record.openingBalance ?? '0') ?? 0,
          totalClosing: double.tryParse(record.closingBalance ?? '0') ?? 0,
          totalOpeningSys: double.tryParse(record.openingSysEquivalent ?? '0') ?? 0,
          totalClosingSys: double.tryParse(record.closingSysEquivalent ?? '0') ?? 0,
        );
      }
    }

    return currencyTotals;
  }
  Map<String, double> _calculateSingleBranchSystemTotals(CashBalancesModel branch) {
    double totalOpeningSys = 0;
    double totalClosingSys = 0;

    if (branch.records != null) {
      for (var record in branch.records!) {
        totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
        totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
      }
    }

    return {
      'opening': totalOpeningSys,
      'closing': totalClosingSys,
    };
  }
}