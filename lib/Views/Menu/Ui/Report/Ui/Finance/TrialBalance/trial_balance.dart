import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/features/branch_dropdown.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/Date/z_generic_date.dart';
import 'package:flutter/services.dart';
import 'PDF/trial_print.dart';
import 'bloc/trial_balance_bloc.dart';
import 'model/trial_balance_model.dart';
import 'package:shamsi_date/shamsi_date.dart';

class TrialBalanceView extends StatelessWidget {
  const TrialBalanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
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
  String? ccy;
  String todayDate = DateTime.now().toFormattedDate();
  Jalali shamsiTodayDate = DateTime.now().toAfghanShamsi;
  ReportModel company = ReportModel();
  int? branchCode;
  LoginData? loginData;
  @override
  void initState() {
    final authState = context.read<AuthBloc>().state;
    if(authState is AuthenticatedState){
      loginData = authState.loginData;
      ccy = loginData?.company?.comLocalCcy;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrialBalanceBloc>().add(
        LoadTrialBalanceEvent(date: todayDate, branchCode: loginData?.usrBranch),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.trialBalance),
        toolbarHeight: 75,
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
            builder: (context, comState) {
              if (comState is CompanyProfileLoadedState) {
                company.comName = comState.company.comName ?? "";
                company.comAddress = comState.company.addName ?? "";
                company.compPhone = comState.company.comPhone ?? "";
                company.comEmail = comState.company.comEmail ?? "";
                company.statementDate = DateTime.now().toFullDateTime;
                company.baseCurrency = comState.company.comLocalCcy;

                // Set logo if available
                final base64Logo = comState.company.comLogo;
                if (base64Logo != null && base64Logo.isNotEmpty) {
                  try {
                    company.comLogo = base64Decode(base64Logo);
                  } catch (e) {
                    company.comLogo = Uint8List(0);
                  }
                }
              }

              return BlocBuilder<TrialBalanceBloc, TrialBalanceState>(
                builder: (context, state) {
                  return ZOutlineButton(
                    width: 110,
                    icon: FontAwesomeIcons.solidFilePdf,
                    label: Text("PDF"),
                    onPressed: () {
                      if (state is TrialBalanceLoadedState) {
                        showDialog(
                          context: context,
                          builder: (_) => PrintPreviewDialog<List<TrialBalanceModel>>(
                            data: state.balance,
                            company: company,
                            buildPreview: ({
                              required data,
                              required language,
                              required orientation,
                              required pageFormat,
                            }) {
                              return TrialBalancePrintSettings().printPreview(
                                trialBalance: data,
                                date: todayDate,
                                company: company,
                                language: language,
                                orientation: orientation,
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
                              return TrialBalancePrintSettings().printDocument(
                                trialBalance: data,
                                date: todayDate,
                                company: company,
                                language: language,
                                orientation: orientation,
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
                              return TrialBalancePrintSettings().createDocument(
                                trialBalance: data,
                                date: todayDate,
                                company: company,
                                language: language,
                                orientation: orientation,
                                pageFormat: pageFormat,
                              );
                            },
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
          SizedBox(width: 8),
          ZOutlineButton(
            width: 100,
            icon: Icons.refresh,
            label: Text(tr.refresh),
            onPressed: () {
              context.read<TrialBalanceBloc>().add(
                LoadTrialBalanceEvent(date: todayDate, branchCode: loginData?.usrBranch),
              );
            },
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: ZDatePicker(
              label: '',
              value: todayDate,
              onDateChanged: (v) {
                setState(() {
                  todayDate = v;
                  shamsiTodayDate = v.toAfghanShamsi;
                });
                context.read<TrialBalanceBloc>().add(
                  LoadTrialBalanceEvent(date: todayDate),
                );
              },
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: BranchDropdown(
                showAllOption: true,
                selectedId: loginData?.usrBranch,
                onBranchSelected: (e){
                  context.read<TrialBalanceBloc>().add(
                    LoadTrialBalanceEvent(date: todayDate, branchCode: e?.brcId),
                  );
                }),
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(5),
        margin: EdgeInsets.all(5),
        child: ZCover(
          child: BlocBuilder<TrialBalanceBloc, TrialBalanceState>(
            builder: (context, state) {
              if (state is TrialBalanceErrorState) {
                return NoDataWidget(
                  message: state.message,
                );
              }
              if (state is TrialBalanceLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is TrialBalanceLoadedState) {
                final data = state.balance;

                // Get currency from first item (assuming all items have same currency)
                final currency = data.isNotEmpty ? data.first.currency : ccy;
                final totalDebit = TrialBalanceHelper.getTotalDebit(data);
                final totalCredit = TrialBalanceHelper.getTotalCredit(data);
                final difference = TrialBalanceHelper.getDifference(data);
                final differencePercentage = TrialBalanceHelper.getDifferencePercentage(data);

                return Column(
                  children: [
                    // Header row
                    _buildHeaderRow(currency??""),

                    // Divider
                    const Divider(),

                    // Data rows
                    Expanded(
                      child: ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: .2),
                        ),
                        itemBuilder: (context, index) {
                          final tb = data[index];
                          final rowDifference = tb.debit - tb.credit;
                          return _buildDataRow(context, tb, rowDifference);
                        },
                      ),
                    ),

                    // Total row
                    _buildTotalRow(
                      context,
                      totalDebit,
                      totalCredit,
                      difference,
                      differencePercentage,
                      ccy??"",
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.accounts,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              AppLocalizations.of(context)!.debitTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              AppLocalizations.of(context)!.creditTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 200,
            child: Text(
              AppLocalizations.of(context)!.actualBalance,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, TrialBalanceModel tb, double difference) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tb.accountName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  tb.accountNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              tb.category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildAmountCell(
              tb.debit,
              Theme.of(context).colorScheme.secondary,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildAmountCell(
              tb.credit,
              Theme.of(context).colorScheme.secondary,
            ),
          ),
          SizedBox(
            width: 200,
            child: _buildAmountCell(
              tb.actualBalance,
              ccy: tb.currency,
              Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCell(double amount, Color color, {String? ccy}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            amount == 0 ? "-" : amount.toAmount(),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (ccy != null) ...[
          SizedBox(width: 5),
          Text(
            ccy,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Utils.currencyColors(ccy),
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ]
      ],
    );
  }

  Widget _buildTotalRow(
      BuildContext context,
      double totalDebit,
      double totalCredit,
      double difference,
      double differencePercentage,
      String currency,
      ) {
    final isBalanced = difference == 0;
    final theme = Theme.of(context);

    return ZCover(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 18),
      margin: EdgeInsets.all(8),
      radius: 5,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.totalUpperCase,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                if (!isBalanced) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning,
                              size: 14,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.outOfBalance,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildTotalAmountCell(
              totalDebit,
              currency,
              theme.colorScheme.primary,
              theme,
              AppLocalizations.of(context)!.totalDebit,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildTotalAmountCell(
              totalCredit,
              currency,
              theme.colorScheme.secondary,
              theme,
              AppLocalizations.of(context)!.totalCredit,
            ),
          ),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(AppLocalizations.of(context)!.difference, style: theme.textTheme.bodySmall),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      difference.abs().toAmount(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isBalanced ? theme.colorScheme.primary : theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!isBalanced) ...[
                      Text(
                        "${differencePercentage.toStringAsFixed(2)}%",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountCell(
      double amount,
      String currency,
      Color color,
      ThemeData theme,
      String title,
      ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: theme.textTheme.bodySmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              amount.toAmount(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              currency,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
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
  String ccy = "USD";
  String todayDate = DateTime.now().toFormattedDate();
  Jalali shamsiTodayDate = DateTime.now().toAfghanShamsi;
  ReportModel company = ReportModel();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrialBalanceBloc>().add(
        LoadTrialBalanceEvent(date: todayDate),
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.trialBalance),
        actions: [
          // Date Picker in AppBar for tablet
          SizedBox(
            width: 180,
            child: ZDatePicker(
              label: '',
              value: todayDate,
              onDateChanged: (v) {
                setState(() {
                  todayDate = v;
                  shamsiTodayDate = v.toAfghanShamsi;
                });
                context.read<TrialBalanceBloc>().add(
                  LoadTrialBalanceEvent(date: todayDate),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TrialBalanceBloc>().add(
                LoadTrialBalanceEvent(date: todayDate),
              );
            },
          ),
          // PDF Button
          BlocBuilder<TrialBalanceBloc, TrialBalanceState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(FontAwesomeIcons.filePdf),
                onPressed: state is TrialBalanceLoadedState
                    ? () => _showPrintPreview(state.balance)
                    : null,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TrialBalanceBloc, TrialBalanceState>(
        builder: (context, state) {
          if (state is TrialBalanceErrorState) {
            return NoDataWidget(
              message: state.message,
              enableAction: false,
            );
          }
          if (state is TrialBalanceLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TrialBalanceLoadedState) {
            final data = state.balance;
            if (data.isEmpty) {
              return NoDataWidget(
                title: tr.noData,
                message: tr.noDataFound,
                enableAction: false,
              );
            }

            final currency = data.isNotEmpty ? data.first.currency : ccy;
            final totalDebit = TrialBalanceHelper.getTotalDebit(data);
            final totalCredit = TrialBalanceHelper.getTotalCredit(data);
            final difference = TrialBalanceHelper.getDifference(data);
            final differencePercentage = TrialBalanceHelper.getDifferencePercentage(data);
            final isBalanced = difference == 0;

            return Column(
              children: [
                // Summary Cards Row
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Debit Card
                      Expanded(
                        child: _buildSummaryCard(
                          title: tr.totalDebit,
                          amount: totalDebit,
                          currency: currency,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Credit Card
                      Expanded(
                        child: _buildSummaryCard(
                          title: tr.totalCredit,
                          amount: totalCredit,
                          currency: currency,
                          color: color.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Difference Card
                      Expanded(
                        child: _buildSummaryCard(
                          title: tr.difference,
                          amount: difference.abs(),
                          currency: currency,
                          color: isBalanced ? color.primary : color.error,
                          subtitle: !isBalanced
                              ? "${differencePercentage.toStringAsFixed(2)}%"
                              : null,
                          showWarning: !isBalanced,
                        ),
                      ),
                    ],
                  ),
                ),

                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          tr.accounts,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          tr.categoryTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          tr.debitTitle,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          tr.creditTitle,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text(
                          tr.actualBalance,
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

                // Data Rows
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final tb = data[index];
                      return _buildTabletDataRow(tb, index, currency);
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required String currency,
    required Color color,
    String? subtitle,
    bool showWarning = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
              if (showWarning)
                Icon(
                  Icons.warning,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  amount.toAmount(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: .8),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletDataRow(TrialBalanceModel tb, int index, String defaultCurrency) {
    final color = Theme.of(context).colorScheme;
    final isEven = index.isEven;
    final currency = tb.currency;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isEven ? color.primary.withValues(alpha: .02) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Account Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tb.accountName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        tb.accountNumber,
                        style: TextStyle(
                          fontSize: 10,
                          color: color.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Category
          SizedBox(
            width: 100,
            child: Text(
              tb.category,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // Debit
          SizedBox(
            width: 120,
            child: _buildTabletAmountCell(
              tb.debit,
              currency,
              tb.debit > 0 ? color.primary : color.outline,
            ),
          ),
          // Credit
          SizedBox(
            width: 120,
            child: _buildTabletAmountCell(
              tb.credit,
              currency,
              tb.credit > 0 ? color.secondary : color.outline,
            ),
          ),
          // Balance
          SizedBox(
            width: 150,
            child: _buildTabletAmountCell(
              tb.actualBalance,
              currency,
              tb.actualBalance >= 0 ? Colors.green : color.error,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletAmountCell(double amount, String currency, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            amount == 0 ? "-" : amount.toAmount(),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: amount == 0 ? null : color,
              fontSize: isBold ? 14 : 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (amount != 0) ...[
          const SizedBox(width: 4),
          Text(
            currency,
            style: TextStyle(
              fontSize: 11,
              color: Utils.currencyColors(currency),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  void _showPrintPreview(List<TrialBalanceModel> data) {
    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<List<TrialBalanceModel>>(
        data: data,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return TrialBalancePrintSettings().printPreview(
            trialBalance: data,
            date: todayDate,
            company: company,
            language: language,
            orientation: orientation,
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
          return TrialBalancePrintSettings().printDocument(
            trialBalance: data,
            date: todayDate,
            company: company,
            language: language,
            orientation: orientation,
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
          return TrialBalancePrintSettings().createDocument(
            trialBalance: data,
            date: todayDate,
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
          );
        },
      ),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  String ccy = "USD";
  String todayDate = DateTime.now().toFormattedDate();
  Jalali shamsiTodayDate = DateTime.now().toAfghanShamsi;
  ReportModel company = ReportModel();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrialBalanceBloc>().add(
        LoadTrialBalanceEvent(date: todayDate),
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.trialBalance),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TrialBalanceBloc>().add(
                LoadTrialBalanceEvent(date: todayDate),
              );
            },
          ),
          // PDF Button
          BlocBuilder<TrialBalanceBloc, TrialBalanceState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(FontAwesomeIcons.filePdf),
                onPressed: state is TrialBalanceLoadedState
                    ? () => _showPrintPreview(state.balance)
                    : null,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Picker
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ZDatePicker(
              label: tr.selectDate,
              value: todayDate,
              onDateChanged: (v) {
                setState(() {
                  todayDate = v;
                  shamsiTodayDate = v.toAfghanShamsi;
                });
                context.read<TrialBalanceBloc>().add(
                  LoadTrialBalanceEvent(date: todayDate),
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<TrialBalanceBloc, TrialBalanceState>(
              builder: (context, state) {
                if (state is TrialBalanceErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is TrialBalanceLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TrialBalanceLoadedState) {
                  final data = state.balance;
                  if (data.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }

                  final currency = data.isNotEmpty ? data.first.currency : ccy;
                  final totalDebit = TrialBalanceHelper.getTotalDebit(data);
                  final totalCredit = TrialBalanceHelper.getTotalCredit(data);
                  final difference = TrialBalanceHelper.getDifference(data);
                  final differencePercentage = TrialBalanceHelper.getDifferencePercentage(data);
                  final isBalanced = difference == 0;

                  return Column(
                    children: [
                      // Summary Card
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.primary.withValues(alpha: .2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tr.totalDebit,
                                  style: TextStyle(color: color.outline),
                                ),
                                Text(
                                  "${totalDebit.toAmount()} $currency",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tr.totalCredit,
                                  style: TextStyle(color: color.outline),
                                ),
                                Text(
                                  "${totalCredit.toAmount()} $currency",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tr.difference,
                                  style: TextStyle(color: color.outline),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      difference.abs().toAmount(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isBalanced ? color.primary : color.error,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      currency,
                                      style: TextStyle(
                                        color: isBalanced ? color.primary : color.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!isBalanced) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.error.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      size: 14,
                                      color: color.error,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${tr.outOfBalance} (${differencePercentage.toStringAsFixed(2)}%)",
                                      style: TextStyle(
                                        color: color.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Accounts List
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final tb = data[index];
                            return _buildMobileAccountCard(tb, index, currency);
                          },
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAccountCard(TrialBalanceModel tb, int index, String defaultCurrency) {
    final color = Theme.of(context).colorScheme;
    final isEven = index.isEven;
    final currency = tb.currency;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isEven ? color.primary.withValues(alpha: .02) : color.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.outline.withValues(alpha: .1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Number Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tb.accountNumber,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.secondary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tb.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Account Name
            Text(
              tb.accountName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Amounts Row
            Row(
              children: [
                // Debit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.debitTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: color.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tb.debit == 0 ? "-" : tb.debit.toAmount(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: tb.debit > 0 ? color.primary : color.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tb.debit > 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              currency,
                              style: TextStyle(
                                fontSize: 10,
                                color: Utils.currencyColors(currency),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Credit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.creditTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: color.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              tb.credit == 0 ? "-" : tb.credit.toAmount(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: tb.credit > 0 ? color.secondary : color.outline,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tb.credit > 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              currency,
                              style: TextStyle(
                                fontSize: 10,
                                color: Utils.currencyColors(currency),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.balance,
                        style: TextStyle(
                          fontSize: 11,
                          color: color.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              tb.actualBalance == 0 ? "-" : tb.actualBalance.toAmount(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: tb.actualBalance >= 0 ? Colors.green : color.error,
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tb.actualBalance != 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              currency,
                              style: TextStyle(
                                fontSize: 10,
                                color: Utils.currencyColors(currency),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrintPreview(List<TrialBalanceModel> data) {
    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<List<TrialBalanceModel>>(
        data: data,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return TrialBalancePrintSettings().printPreview(
            trialBalance: data,
            date: todayDate,
            company: company,
            language: language,
            orientation: orientation,
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
          return TrialBalancePrintSettings().printDocument(
            trialBalance: data,
            date: todayDate,
            company: company,
            language: language,
            orientation: orientation,
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
          return TrialBalancePrintSettings().createDocument(
            trialBalance: data,
            date: todayDate,
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
          );
        },
      ),
    );
  }
}

class TrialBalanceHelper {
  static double getTotalDebit(List<TrialBalanceModel> data) {
    return data.fold(0.0, (sum, item) => sum + item.debit);
  }

  static double getTotalCredit(List<TrialBalanceModel> data) {
    return data.fold(0.0, (sum, item) => sum + item.credit);
  }

  static double getDifference(List<TrialBalanceModel> data) {
    return getTotalDebit(data) - getTotalCredit(data);
  }

  static double getDifferencePercentage(List<TrialBalanceModel> data) {
    final totalDebit = getTotalDebit(data);
    final difference = getDifference(data);
    return totalDebit > 0 ? (difference.abs() / totalDebit * 100) : 0;
  }
}