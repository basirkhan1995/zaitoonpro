import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/features/branch_dropdown.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/bloc/cash_balances_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/model/cash_balance_model.dart';
import '../../../../../../../Features/Other/toast.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import 'Print/cash_print.dart';
import 'Print/feature_model.dart';
import 'package:flutter/services.dart';

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

// ==================== DESKTOP VIEW ====================
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
      final authState = context.read<AuthBloc>().state;
      ReportModel company = ReportModel();

      if (authState is AuthenticatedState) {
        final auth = authState.loginData;
        company.comName = auth.company?.comName ?? "";
        company.comAddress = auth.company?.comAddress ?? "";
        company.compPhone = auth.company?.comPhone ?? "";
        company.comEmail = auth.company?.comEmail ?? "";
        company.statementDate = DateTime.now().toFullDateTime;
        company.baseCurrency = auth.company?.comLocalCcy;
        baseCcy = authState.loginData.company?.comLocalCcy;
        final base64Logo = auth.company?.comLogo;
        if (base64Logo != null && base64Logo.isNotEmpty) {
          try {
            company.comLogo = base64Decode(base64Logo);
          } catch (e) {
            company.comLogo = Uint8List(0);
          }
        }
      }

      final currencyTotals = _calculateSingleBranchCurrencyTotals(state.cash);
      final systemTotals = _calculateSingleBranchSystemTotals(state.cash);

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
    return {'opening': totalOpeningSys, 'closing': totalClosingSys};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
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

    double totalOpeningSys = 0;
    double totalClosingSys = 0;
    if (branch.records != null) {
      for (var record in branch.records!) {
        totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
        totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
      }
    }
    final totalCashFlowSys = totalClosingSys - totalOpeningSys;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Balances (40%)
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompactBranchInfo(branch, tr),
                const SizedBox(height: 16),
                if (branch.records != null && branch.records!.isNotEmpty)
                  _buildCurrencyBalancesSection(branch, tr),
                const SizedBox(height: 16),
                _buildGrandTotalCard(
                  totalOpeningSys,
                  totalClosingSys,
                  totalCashFlowSys,
                  tr,
                  branch.brcName ?? '',
                ),
              ],
            ),
          ),
        ),
        // Right Column - Transactions (60%)
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: branch.transactions != null && branch.transactions!.isNotEmpty
                ? _buildTransactionHistorySection(branch, tr)
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Transactions',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBranchInfo(CashBalancesModel branch, AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.brcName ?? 'N/A',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: BranchDropdown(
                  selectedId: branchId,
                  height: 36,
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _buildInlineInfo('${tr.branchId}:', branch.brcId?.toString() ?? 'N/A'),
              _buildInlineInfo('${tr.mobile1}:', branch.brcPhone ?? 'N/A'),
              _buildInlineInfo('${tr.status}:',
                  branch.brcStatus == 1 ? tr.active : tr.inactive),
              if (branch.address != null && branch.address!.isNotEmpty)
                _buildInlineInfo('${tr.address}:', branch.address!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInfo(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        ...branch.records!.map((record) => _buildCurrencyItem(record, tr)),
      ],
    );
  }

  Widget _buildCurrencyItem(Record record, AppLocalizations tr) {
    final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
    final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
    final openingSys = double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
    final closingSys = double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
    final cashFlow = closing - opening;
    final cashFlowSys = closingSys - openingSys;

    final currencyCode = record.trdCcy ?? '';
    final isBaseCurrency = currencyCode == baseCcy;
    final currencyColor = Utils.currencyColors(currencyCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: currencyColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    color: currencyColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.ccyName ?? currencyCode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: currencyColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: currencyColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  currencyCode,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.opening,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "${opening.toAmount()} $currencyCode",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isBaseCurrency)
                      Text(
                        "${openingSys.toAmount()} $baseCcy",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
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
                      tr.closing,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "${closing.toAmount()} $currencyCode",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (!isBaseCurrency)
                      Text(
                        "${closingSys.toAmount()} $baseCcy",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
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
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "${cashFlow.toAmount()} $currencyCode",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cashFlow >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    if (!isBaseCurrency)
                      Text(
                        "${cashFlowSys.toAmount()} $baseCcy",
                        style: TextStyle(
                          fontSize: 10,
                          color: cashFlowSys >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalCard(
      double openingSys,
      double closingSys,
      double cashFlowSys,
      AppLocalizations tr,
      String branchName,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${tr.grandTotal} (${tr.systemEquivalent})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTotalItem(tr.openingBalance, openingSys, Colors.grey.shade700),
              ),
              Expanded(
                child: _buildTotalItem(tr.closingBalance, closingSys, Colors.green.shade700),
              ),
              Expanded(
                child: _buildTotalItem(
                  tr.cashFlow,
                  cashFlowSys,
                  cashFlowSys >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          "${value.toAmount()} ${baseCcy ?? ''}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== TRANSACTION HISTORY SECTION ====================
  Widget _buildTransactionHistorySection(CashBalancesModel branch, AppLocalizations tr) {
    final transactions = branch.transactions!;

    // Group transactions by currency
    final transactionsByCurrency = <String, List<Transaction>>{};
    for (var txn in transactions) {
      final currency = txn.currency ?? 'UNKNOWN';
      transactionsByCurrency.putIfAbsent(currency, () => []).add(txn);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                tr.cashFlow,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${transactions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: transactionsByCurrency.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Utils.currencyColors(entry.key).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${entry.key} (${entry.value.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Utils.currencyColors(entry.key),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...entry.value.map((txn) => _buildTransactionItem(txn, entry.key)),
                const SizedBox(height: 16),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction txn, String currency) {
    final debit = double.tryParse(txn.debit ?? '0') ?? 0;
    final credit = double.tryParse(txn.credit ?? '0') ?? 0;
    final runningBalance = double.tryParse(txn.runningBalance ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                txn.date != null
                    ? '${txn.date!.toFormattedDate()} | ${txn.date!.shamsiDateString}'
                    : 'N/A',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (txn.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: txn.status == 'Authorized'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    txn.status!,
                    style: TextStyle(
                      fontSize: 12,
                      color: txn.status == 'Authorized'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            spacing: 8,
            children: [
              if (txn.creditAccountName != null && txn.creditAccountName!.isNotEmpty)...[
                Text(
                  '${txn.creditAccountName} |',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
              Text(
                txn.narration ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (debit > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'DR',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (credit > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'CR',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      (debit > 0 ? debit : credit).toAmount(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: debit > 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    Text(
                      ' $currency',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                runningBalance.toAmount(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: runningBalance >= 0
                      ? Colors.blue.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== TABLET VIEW ====================
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

  Future<void> _printBranchBalance() async {
    final state = context.read<CashBalancesBloc>().state;

    if (state is CashBalancesLoadedState) {
      final authState = context.read<AuthBloc>().state;
      ReportModel company = ReportModel();

      if (authState is AuthenticatedState) {
        final auth = authState.loginData;
        company.comName = auth.company?.comName ?? "";
        company.comAddress = auth.company?.comAddress ?? "";
        company.compPhone = auth.company?.comPhone ?? "";
        company.comEmail = auth.company?.comEmail ?? "";
        company.statementDate = DateTime.now().toFullDateTime;
        company.baseCurrency = auth.company?.comLocalCcy;
        baseCcy = authState.loginData.company?.comLocalCcy;
        final base64Logo = auth.company?.comLogo;
        if (base64Logo != null && base64Logo.isNotEmpty) {
          try {
            company.comLogo = base64Decode(base64Logo);
          } catch (e) {
            company.comLogo = Uint8List(0);
          }
        }
      }

      final currencyTotals = _calculateSingleBranchCurrencyTotals(state.cash);
      final systemTotals = _calculateSingleBranchSystemTotals(state.cash);

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
    return {'opening': totalOpeningSys, 'closing': totalClosingSys};
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
          const SizedBox(width: 5),
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
          return _buildBranchDetails(state.cash, context);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildBranchDetails(CashBalancesModel branch, BuildContext context) {
    final tr = AppLocalizations.of(context)!;

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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBranchInfoCard(branch, tr),
          const SizedBox(height: 12),
          Text(
            tr.currencyBalances,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (branch.records != null && branch.records!.isNotEmpty)
            ...branch.records!.map((record) => _buildTabletCurrencyItem(record, tr)),
          const SizedBox(height: 12),
          _buildTabletGrandTotal(totalOpeningSys, totalClosingSys, totalCashFlowSys, tr),
          if (branch.transactions != null && branch.transactions!.isNotEmpty)
            _buildTabletTransactionSection(branch, tr),
        ],
      ),
    );
  }

  Widget _buildBranchInfoCard(CashBalancesModel branch, AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                branch.brcName ?? 'Unknown Branch',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
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
    );
  }

  Widget _buildTabletInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletCurrencyItem(Record record, AppLocalizations tr) {
    final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
    final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
    final cashFlow = closing - opening;
    final currencyCode = record.trdCcy ?? '';
    final currencyColor = Utils.currencyColors(currencyCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: currencyColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            color: currencyColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.ccyName ?? currencyCode,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: currencyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tr.opening}: ${opening.toAmount()}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${tr.closing}: ${closing.toAmount()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${tr.cashFlow}: ${cashFlow.toAmount()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cashFlow >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: currencyColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              currencyCode,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletGrandTotal(double opening, double closing, double cashFlow, AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.openingBalance,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${opening.toAmount()} ${baseCcy ?? ''}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.closingBalance,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${closing.toAmount()} ${baseCcy ?? ''}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.cashFlow,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${cashFlow.toAmount()} ${baseCcy ?? ''}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cashFlow >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletTransactionSection(CashBalancesModel branch, AppLocalizations tr) {
    final transactions = branch.transactions!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.history, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Transactions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${transactions.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...transactions.take(5).map((txn) {
          final debit = double.tryParse(txn.debit ?? '0') ?? 0;
          final credit = double.tryParse(txn.credit ?? '0') ?? 0;
          final runningBalance = double.tryParse(txn.runningBalance ?? '0') ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    txn.date != null
                        ? '${txn.date!.year}/${txn.date!.month.toString().padLeft(2, '0')}/${txn.date!.day.toString().padLeft(2, '0')}'
                        : 'N/A',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    txn.narration ?? '',
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    (debit > 0 ? debit : credit).toAmount(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: debit > 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    runningBalance.toAmount(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: runningBalance >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (transactions.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${transactions.length - 5} more transactions',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== MOBILE VIEW ====================
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

  Future<void> _printBranchBalance() async {
    final state = context.read<CashBalancesBloc>().state;

    if (state is CashBalancesLoadedState) {
      final authState = context.read<AuthBloc>().state;
      ReportModel company = ReportModel();

      if (authState is AuthenticatedState) {
        final auth = authState.loginData;
        company.comName = auth.company?.comName ?? "";
        company.comAddress = auth.company?.comAddress ?? "";
        company.compPhone = auth.company?.comPhone ?? "";
        company.comEmail = auth.company?.comEmail ?? "";
        company.statementDate = DateTime.now().toFullDateTime;
        company.baseCurrency = auth.company?.comLocalCcy;
        baseCcy = authState.loginData.company?.comLocalCcy;
        final base64Logo = auth.company?.comLogo;
        if (base64Logo != null && base64Logo.isNotEmpty) {
          try {
            company.comLogo = base64Decode(base64Logo);
          } catch (e) {
            company.comLogo = Uint8List(0);
          }
        }
      }

      final currencyTotals = _calculateSingleBranchCurrencyTotals(state.cash);
      final systemTotals = _calculateSingleBranchSystemTotals(state.cash);

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
    return {'opening': totalOpeningSys, 'closing': totalClosingSys};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cashBalances),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CashBalancesBloc>().add(
                LoadCashBalanceBranchWiseEvent(branchId: branchId),
              );
            },
          ),
          const SizedBox(width: 5),
          IconButton(
            onPressed: _printBranchBalance,
            icon: const Icon(Icons.print),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NoDataWidget(
                message: state.error,
                onRefresh: () {
                  context.read<CashBalancesBloc>().add(
                    LoadCashBalanceBranchWiseEvent(branchId: branchId),
                  );
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

    double totalOpeningSys = 0;
    double totalClosingSys = 0;
    if (branch.records != null) {
      for (var record in branch.records!) {
        totalOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
        totalClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
      }
    }
    final totalCashFlowSys = totalClosingSys - totalOpeningSys;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildMobileBranchInfo(branch, tr),
        const SizedBox(height: 12),
        Text(
          tr.currencyBalances,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (branch.records != null && branch.records!.isNotEmpty)
          ...branch.records!.map((record) => _buildMobileCurrencyItem(record, tr)),
        const SizedBox(height: 12),
        _buildMobileGrandTotal(totalOpeningSys, totalClosingSys, totalCashFlowSys, tr),
        if (branch.transactions != null && branch.transactions!.isNotEmpty)
          _buildMobileTransactionSection(branch, tr),
      ],
    );
  }

  Widget _buildMobileBranchInfo(CashBalancesModel branch, AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  branch.brcName ?? 'Unknown Branch',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: branch.brcStatus == 1 ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  branch.brcStatus == 1 ? tr.active : tr.inactive,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              _buildMobileChip('${tr.branchId}:', branch.brcId?.toString() ?? 'N/A'),
              _buildMobileChip(tr.mobile1, branch.brcPhone ?? 'N/A'),
              if (branch.address != null && branch.address!.isNotEmpty)
                _buildMobileChip(tr.address, branch.address!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMobileCurrencyItem(Record record, AppLocalizations tr) {
    final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
    final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
    final cashFlow = closing - opening;
    final currencyCode = record.trdCcy ?? '';
    final currencyColor = Utils.currencyColors(currencyCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: currencyColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                color: currencyColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  record.ccyName ?? currencyCode,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: currencyColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: currencyColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  currencyCode,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${tr.opening}: ${opening.toAmount()}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              Expanded(
                child: Text(
                  '${tr.closing}: ${closing.toAmount()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${tr.cashFlow}: ${cashFlow.toAmount()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cashFlow >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileGrandTotal(double opening, double closing, double cashFlow, AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.openingBalance,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${opening.toAmount()} ${baseCcy ?? ''}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.closingBalance,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${closing.toAmount()} ${baseCcy ?? ''}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.cashFlow,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${cashFlow.toAmount()} ${baseCcy ?? ''}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cashFlow >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransactionSection(CashBalancesModel branch, AppLocalizations tr) {
    final transactions = branch.transactions!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.history, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'Transactions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${transactions.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...transactions.take(3).map((txn) {
          final debit = double.tryParse(txn.debit ?? '0') ?? 0;
          final credit = double.tryParse(txn.credit ?? '0') ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        txn.narration ?? '',
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      (debit > 0 ? debit : credit).toAmount(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: debit > 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                Text(
                  txn.date != null
                      ? '${txn.date!.year}/${txn.date!.month.toString().padLeft(2, '0')}/${txn.date!.day.toString().padLeft(2, '0')}'
                      : 'N/A',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }),
        if (transactions.length > 3)
          Text(
            '+ ${transactions.length - 3} more',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue.shade600,
            ),
          ),
      ],
    );
  }
}