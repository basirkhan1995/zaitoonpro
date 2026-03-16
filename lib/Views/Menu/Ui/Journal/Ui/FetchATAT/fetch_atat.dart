import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/zForm_dialog.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/FetchATAT/bloc/fetch_atat_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/FetchATAT/model/fetch_atat_model.dart';

import '../../../../../../Features/Other/cover.dart';
import '../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../bloc/transactions_bloc.dart';
import 'Print/atat_print.dart';
import 'model/print_data_model.dart';

class FetchAtatView extends StatelessWidget {
  const FetchAtatView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _Mobile(),
      desktop: const _Desktop(),
      tablet: const _Tablet(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  String getTitle(BuildContext context, String code) {
    switch (code) {
      case "SLRY": return AppLocalizations.of(context)!.postSalary;
      case "ATAT": return AppLocalizations.of(context)!.accountTransfer;
      case "CRFX": return AppLocalizations.of(context)!.fxTransaction;
      case "PLCL": return AppLocalizations.of(context)!.profitAndLoss;
      default: return "";
    }
  }

  FetchAtatModel? loadedAtat;

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
    final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = auth.loginData;

    return BlocConsumer<FetchAtatBloc, FetchAtatState>(
      listener: (context, state) {
        if (state is FetchATATLoadedState) {
          loadedAtat = state.atat;
        }
      },
      builder: (context, state) {
        if (state is FetchATATLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FetchATATLoadedState) {
          loadedAtat = state.atat;
        }

        if (state is FetchATATErrorState) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Calculate totals
        double totalDebit = 0;
        double totalCredit = 0;

        if (loadedAtat != null) {
          if (loadedAtat!.debit != null) {
            for (var dr in loadedAtat!.debit!) {
              totalDebit += double.tryParse(dr.trdAmount ?? '0') ?? 0;
            }
          }
          if (loadedAtat!.credit != null) {
            for (var cr in loadedAtat!.credit!) {
              totalCredit += double.tryParse(cr.trdAmount ?? '0') ?? 0;
            }
          }
        }

        final bool showAuthorizeButton = loadedAtat?.trnStatus == 0 &&
            login.usrName != loadedAtat?.maker;
        final bool showDeleteButton = loadedAtat?.trnStatus == 0 &&
            loadedAtat?.maker == login.usrName;
        final bool showAnyButton = showAuthorizeButton || showDeleteButton;

        return Scaffold(
          appBar: AppBar(
            title: Text(getTitle(context, loadedAtat?.trnType ?? "")),
            actions: const [Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.print),
            )],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Details Card
                ZCover(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.details,
                        style: textTheme.titleMedium?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildDetailRow(tr.referenceNumber, loadedAtat?.trnReference ?? "", context),
                      _buildDetailRow(tr.status,
                          loadedAtat?.trnStatus == 1 ? tr.authorizedTransaction : tr.pendingTransactions,
                          context),
                      _buildDetailRow(tr.branch, loadedAtat?.trdBranch.toString() ?? "", context),
                      _buildDetailRow(tr.maker, loadedAtat?.maker ?? "", context),
                      if(loadedAtat?.checker != null && loadedAtat!.checker!.isNotEmpty)
                        _buildDetailRow(tr.checker, loadedAtat?.checker ?? "", context),
                      _buildDetailRow(tr.narration, loadedAtat?.trdNarration ?? "", context),
                      _buildDetailRow(tr.date, loadedAtat!.trnEntryDate!.toFullDateTime, context),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Debit Section
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(text: "${tr.debitTitle} (${loadedAtat?.debit?.length ?? 0})"),
                            Tab(text: "${tr.creditTitle} (${loadedAtat?.credit?.length ?? 0})"),
                          ],
                          labelColor: color.primary,
                          unselectedLabelColor: color.outline,
                          indicatorColor: color.primary,
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Debit Tab
                              _buildTransactionList(
                                items: loadedAtat?.debit,
                                isDebit: true,
                                color: color,
                                textTheme: textTheme,
                              ),
                              // Credit Tab
                              _buildTransactionList(
                                items: loadedAtat?.credit,
                                isDebit: false,
                                color: color,
                                textTheme: textTheme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Totals Card
                ZCover(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.totalDebit, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            "${totalDebit.toAmount()} ${loadedAtat?.debit?.isNotEmpty == true ? loadedAtat!.debit!.first.trdCcy : ''}",
                            style: textTheme.titleSmall?.copyWith(color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.totalCredit, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            "${totalCredit.toAmount()} ${loadedAtat?.credit?.isNotEmpty == true ? loadedAtat!.credit!.first.trdCcy : ''}",
                            style: textTheme.titleSmall?.copyWith(color: Colors.red),
                          ),
                        ],
                      ),
                      if (totalDebit == totalCredit)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                tr.balanced,
                                style: textTheme.bodySmall?.copyWith(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action Buttons
                if (showAnyButton)
                  Row(
                    children: [
                      if (showAuthorizeButton)
                        Expanded(
                          child: ZOutlineButton(
                            onPressed: isAuthorizeLoading ? null : () {
                              context.read<TransactionsBloc>().add(
                                AuthorizeTxnEvent(
                                  reference: loadedAtat?.trnReference ?? "",
                                  usrName: login.usrName ?? "",
                                ),
                              );
                            },
                            icon: isAuthorizeLoading ? null : Icons.check_box_outlined,
                            isActive: true,
                            label: isAuthorizeLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                                : Text(tr.authorize),
                          ),
                        ),
                      if (showAuthorizeButton && showDeleteButton)
                        const SizedBox(width: 8),
                      if (showDeleteButton)
                        Expanded(
                          child: ZOutlineButton(
                            onPressed: isDeleteLoading ? null : () {
                              context.read<TransactionsBloc>().add(
                                DeletePendingTxnEvent(
                                  reference: loadedAtat?.trnReference ?? "",
                                  usrName: login.usrName ?? "",
                                ),
                              );
                            },
                            icon: isDeleteLoading ? null : Icons.delete_outline_rounded,
                            isActive: true,
                            backgroundHover: Theme.of(context).colorScheme.error,
                            label: isDeleteLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                                : Text(tr.delete),
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
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList({
    required List<Records>? items,
    required bool isDebit,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    if (items == null || items.isEmpty) {
      return Center(
        child: Text(
          isDebit ? 'No debit entries' : 'No credit entries',
          style: textTheme.bodyMedium?.copyWith(color: color.outline),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: index.isOdd ? color.primary.withValues(alpha: .05) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.accName ?? "",
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${AppLocalizations.of(context)!.accountNumber}: ${item.trdAccount ?? ""}",
                    style: textTheme.bodySmall,
                  ),
                  Text(
                    "${item.trdAmount?.toAmount()} ${item.trdCcy}",
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDebit ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  String getTitle(BuildContext context, String code) {
    switch (code) {
      case "SLRY": return AppLocalizations.of(context)!.postSalary;
      case "ATAT": return AppLocalizations.of(context)!.accountTransfer;
      case "CRFX": return AppLocalizations.of(context)!.fxTransaction;
      case "PLCL": return AppLocalizations.of(context)!.profitAndLoss;
      default: return "";
    }
  }

  FetchAtatModel? loadedAtat;

  Future<void> _printTransaction() async {
    if (loadedAtat == null) return;

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
    final currencyTotals = _calculateCurrencyTotals(loadedAtat!);

    // Calculate system totals
    final systemTotals = _calculateSystemTotals(loadedAtat!);

    // Prepare print data
    final printData = AtatPrintData(
      reportType: 'single',
      transaction: loadedAtat!,
      currencyTotals: currencyTotals,
      systemTotal: SystemTotal(
        totalDebitSys: systemTotals['debit'] ?? 0,
        totalCreditSys: systemTotals['credit'] ?? 0,
        netAmountSys: systemTotals['net'] ?? 0,
      ),
      baseCcy: baseCcy,
      reportDate: DateTime.now(),
      selectedReference: loadedAtat?.trnReference,
    );

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => PrintPreviewDialog<AtatPrintData>(
          data: printData,
          company: company,
          buildPreview: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return AtatPrintSettings().printPreview(
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
            return AtatPrintSettings().printDocument(
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
            return AtatPrintSettings().createDocument(
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
  }

  Map<String, CurrencyTotals> _calculateCurrencyTotals(FetchAtatModel transaction) {
    final Map<String, CurrencyTotals> totals = {};

    // Process debit items
    if (transaction.debit != null) {
      for (var item in transaction.debit!) {
        final currency = item.trdCcy ?? 'UNKNOWN';
        final amount = double.tryParse(item.trdAmount ?? '0') ?? 0;

        if (!totals.containsKey(currency)) {
          totals[currency] = CurrencyTotals(
            name: item.accName ?? currency,
            totalDebit: 0,
            totalCredit: 0,
            netAmount: 0,
          );
        }

        totals[currency] = CurrencyTotals(
          name: totals[currency]!.name,
          totalDebit: totals[currency]!.totalDebit + amount,
          totalCredit: totals[currency]!.totalCredit,
          netAmount: totals[currency]!.totalDebit + amount - totals[currency]!.totalCredit,
        );
      }
    }

    // Process credit items
    if (transaction.credit != null) {
      for (var item in transaction.credit!) {
        final currency = item.trdCcy ?? 'UNKNOWN';
        final amount = double.tryParse(item.trdAmount ?? '0') ?? 0;

        if (!totals.containsKey(currency)) {
          totals[currency] = CurrencyTotals(
            name: item.accName ?? currency,
            totalDebit: 0,
            totalCredit: 0,
            netAmount: 0,
          );
        }

        totals[currency] = CurrencyTotals(
          name: totals[currency]!.name,
          totalDebit: totals[currency]!.totalDebit,
          totalCredit: totals[currency]!.totalCredit + amount,
          netAmount: totals[currency]!.totalDebit - (totals[currency]!.totalCredit + amount),
        );
      }
    }

    return totals;
  }

  Map<String, double> _calculateSystemTotals(FetchAtatModel transaction) {
    double totalDebitSys = 0;
    double totalCreditSys = 0;

    if (transaction.debit != null) {
      for (var item in transaction.debit!) {
        totalDebitSys += double.tryParse(item.trdAmount ?? '0') ?? 0;
      }
    }

    if (transaction.credit != null) {
      for (var item in transaction.credit!) {
        totalCreditSys += double.tryParse(item.trdAmount ?? '0') ?? 0;
      }
    }

    return {
      'debit': totalDebitSys,
      'credit': totalCreditSys,
      'net': totalDebitSys - totalCreditSys,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);
    TextStyle? bodyStyle = textTheme.bodyMedium?.copyWith();
    final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
    final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = auth.loginData;

    return BlocConsumer<FetchAtatBloc, FetchAtatState>(
      listener: (context, state) {
        if (state is FetchATATLoadedState) {
          loadedAtat = state.atat;
        }
      },
      builder: (context, state) {
        if (state is FetchATATLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FetchATATLoadedState) {
          loadedAtat = state.atat;
        }

        if (state is FetchATATErrorState) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Calculate totals
        double totalDebit = 0;
        double totalCredit = 0;

        if (loadedAtat != null) {
          if (loadedAtat!.debit != null) {
            for (var dr in loadedAtat!.debit!) {
              totalDebit += double.tryParse(dr.trdAmount ?? '0') ?? 0;
            }
          }
          if (loadedAtat!.credit != null) {
            for (var cr in loadedAtat!.credit!) {
              totalCredit += double.tryParse(cr.trdAmount ?? '0') ?? 0;
            }
          }
        }

        final bool showAuthorizeButton = loadedAtat?.trnStatus == 0 &&
            login.usrName != loadedAtat?.maker;
        final bool showDeleteButton = loadedAtat?.trnStatus == 0 &&
            loadedAtat?.maker == login.usrName;
        final bool showAnyButton = showAuthorizeButton || showDeleteButton;

        return Scaffold(
          appBar: AppBar(
            title: Text(getTitle(context, loadedAtat?.trnType ?? "")),
            actions: [
              IconButton(
                onPressed: _printTransaction,
                icon: const Icon(Icons.print),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZCover(
                  padding: const EdgeInsets.all(16),
                  radius: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.details,
                        style: textTheme.titleMedium?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          _buildDetailItem(tr.referenceNumber, loadedAtat?.trnReference ?? "", titleStyle, bodyStyle),
                          _buildDetailItem(tr.status,
                              loadedAtat?.trnStatus == 1 ? tr.authorizedTransaction : tr.pendingTransactions,
                              titleStyle, bodyStyle),
                          _buildDetailItem(tr.branch, loadedAtat?.trdBranch.toString() ?? "", titleStyle, bodyStyle),
                          _buildDetailItem(tr.maker, loadedAtat?.maker ?? "", titleStyle, bodyStyle),
                          if(loadedAtat?.checker != null && loadedAtat!.checker!.isNotEmpty)
                            _buildDetailItem(tr.checker, loadedAtat?.checker ?? "", titleStyle, bodyStyle),
                          _buildDetailItem(tr.narration, loadedAtat?.trdNarration ?? "", titleStyle, bodyStyle),
                          _buildDetailItem(tr.date, loadedAtat!.trnEntryDate!.toFullDateTime, titleStyle, bodyStyle),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Debit and Credit Tables Side by Side
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Debit Table
                      Expanded(
                        child: _buildTransactionTable(
                          title: tr.debitTitle,
                          items: loadedAtat?.debit,
                          total: totalDebit,
                          color: color,
                          textTheme: textTheme,
                          context: context,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Credit Table
                      Expanded(
                        child: _buildTransactionTable(
                          title: tr.creditTitle,
                          items: loadedAtat?.credit,
                          total: totalCredit,
                          color: color,
                          textTheme: textTheme,
                          context: context,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Totals Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.outline.withValues(alpha: .2)),
                  ),
                  child: Row(
                    children: [
                      // Total Debit
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${tr.totalDebit}: ',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              totalDebit.toAmount(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loadedAtat?.debit?.isNotEmpty == true
                                  ? loadedAtat!.debit!.first.trdCcy ?? ''
                                  : '',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      // Vertical Divider
                      Container(
                        height: 30,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: color.outline.withValues(alpha: .3),
                      ),

                      // Total Credit
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${tr.totalCredit}: ',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              totalCredit.toAmount(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loadedAtat?.credit?.isNotEmpty == true
                                  ? loadedAtat!.credit!.first.trdCcy ?? ''
                                  : '',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      // Balance Indicator (if needed)
                      if (totalDebit != totalCredit)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Δ: ${(totalDebit - totalCredit).abs().toAmount()}',
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                if (showAnyButton)
                  Row(
                    children: [
                      if (showAuthorizeButton)
                        Expanded(
                          child: ZOutlineButton(
                            onPressed: isAuthorizeLoading ? null : () {
                              context.read<TransactionsBloc>().add(
                                AuthorizeTxnEvent(
                                  reference: loadedAtat?.trnReference ?? "",
                                  usrName: login.usrName ?? "",
                                ),
                              );
                            },
                            icon: isAuthorizeLoading ? null : Icons.check_box_outlined,
                            isActive: true,
                            label: isAuthorizeLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                                : Text(tr.authorize),
                          ),
                        ),
                      if (showAuthorizeButton && showDeleteButton)
                        const SizedBox(width: 8),
                      if (showDeleteButton)
                        Expanded(
                          child: ZOutlineButton(
                            onPressed: isDeleteLoading ? null : () {
                              context.read<TransactionsBloc>().add(
                                DeletePendingTxnEvent(
                                  reference: loadedAtat?.trnReference ?? "",
                                  usrName: login.usrName ?? "",
                                ),
                              );
                            },
                            icon: isDeleteLoading ? null : Icons.delete_outline_rounded,
                            isActive: true,
                            backgroundHover: Theme.of(context).colorScheme.error,
                            label: isDeleteLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                                : Text(tr.delete),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ZOutlineButton(
                          onPressed: _printTransaction,
                          isActive: true,
                          icon: Icons.print,
                          label: Text(tr.print),
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
  }

  Widget _buildDetailItem(String label, String value, TextStyle? titleStyle, TextStyle? bodyStyle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: titleStyle,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: bodyStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTable({
    required String title,
    required List<Records>? items,
    required double total,
    required ColorScheme color,
    required TextTheme textTheme,
    required BuildContext context,
  }) {
    final tr = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.outline.withValues(alpha: .2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header with Title and Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${tr.totalTitle}: ',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      total.toAmount(),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.surface,
              border: Border(
                bottom: BorderSide(color: color.outline.withValues(alpha: .2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    tr.accountName,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    tr.accountNumber,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    tr.amount,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: items == null || items.isEmpty
                ? Center(
              child: Text(
                title == tr.debitTitle ? 'No debit entries' : 'No credit entries',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.outline,
                ),
              ),
            )
                : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: index.isOdd
                        ? color.primary.withValues(alpha: .02)
                        : Colors.transparent,
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
                        child: Text(
                          item.accName ?? "",
                          style: textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          item.trdAccount.toString(),
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                item.trdAmount?.toAmount() ?? "",
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.trdCcy ?? "",
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Total Row at Bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color.outline.withValues(alpha: .3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.totalTitle,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      total.toAmount(),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      items?.isNotEmpty == true ? items!.first.trdCcy ?? '' : '',
                      style: textTheme.bodySmall,
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
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  String getTitle(BuildContext context, String code) {
    switch (code) {
      case "SLRY": return AppLocalizations.of(context)!.postSalary;
      case "ATAT": return AppLocalizations.of(context)!.accountTransfer;
      case "CRFX": return AppLocalizations.of(context)!.fxTransaction;
      case "PLCL": return AppLocalizations.of(context)!.profitAndLoss;
      default: return "";
    }
  }

  FetchAtatModel? loadedAtat;

  Future<void> _printTransaction() async {
    if (loadedAtat == null) return;

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
    final currencyTotals = _calculateCurrencyTotals(loadedAtat!);

    // Calculate system totals
    final systemTotals = _calculateSystemTotals(loadedAtat!);

    // Prepare print data
    final printData = AtatPrintData(
      reportType: 'single',
      transaction: loadedAtat!,
      currencyTotals: currencyTotals,
      systemTotal: SystemTotal(
        totalDebitSys: systemTotals['debit'] ?? 0,
        totalCreditSys: systemTotals['credit'] ?? 0,
        netAmountSys: systemTotals['net'] ?? 0,
      ),
      baseCcy: baseCcy,
      reportDate: DateTime.now(),
      selectedReference: loadedAtat?.trnReference,
    );

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => PrintPreviewDialog<AtatPrintData>(
          data: printData,
          company: company,
          buildPreview: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return AtatPrintSettings().printPreview(
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
            return AtatPrintSettings().printDocument(
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
            return AtatPrintSettings().createDocument(
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
  }

  Map<String, CurrencyTotals> _calculateCurrencyTotals(FetchAtatModel transaction) {
    final Map<String, CurrencyTotals> totals = {};

    // Process debit items
    if (transaction.debit != null) {
      for (var item in transaction.debit!) {
        final currency = item.trdCcy ?? 'UNKNOWN';
        final amount = double.tryParse(item.trdAmount ?? '0') ?? 0;

        if (!totals.containsKey(currency)) {
          totals[currency] = CurrencyTotals(
            name: item.accName ?? currency,
            totalDebit: 0,
            totalCredit: 0,
            netAmount: 0,
          );
        }

        totals[currency] = CurrencyTotals(
          name: totals[currency]!.name,
          totalDebit: totals[currency]!.totalDebit + amount,
          totalCredit: totals[currency]!.totalCredit,
          netAmount: totals[currency]!.totalDebit + amount - totals[currency]!.totalCredit,
        );
      }
    }

    // Process credit items
    if (transaction.credit != null) {
      for (var item in transaction.credit!) {
        final currency = item.trdCcy ?? 'UNKNOWN';
        final amount = double.tryParse(item.trdAmount ?? '0') ?? 0;

        if (!totals.containsKey(currency)) {
          totals[currency] = CurrencyTotals(
            name: item.accName ?? currency,
            totalDebit: 0,
            totalCredit: 0,
            netAmount: 0,
          );
        }

        totals[currency] = CurrencyTotals(
          name: totals[currency]!.name,
          totalDebit: totals[currency]!.totalDebit,
          totalCredit: totals[currency]!.totalCredit + amount,
          netAmount: totals[currency]!.totalDebit - (totals[currency]!.totalCredit + amount),
        );
      }
    }

    return totals;
  }

  Map<String, double> _calculateSystemTotals(FetchAtatModel transaction) {
    double totalDebitSys = 0;
    double totalCreditSys = 0;

    // You might need to convert to base currency here
    // For now, we'll just sum the amounts (assuming they're already in base currency)
    if (transaction.debit != null) {
      for (var item in transaction.debit!) {
        totalDebitSys += double.tryParse(item.trdAmount ?? '0') ?? 0;
      }
    }

    if (transaction.credit != null) {
      for (var item in transaction.credit!) {
        totalCreditSys += double.tryParse(item.trdAmount ?? '0') ?? 0;
      }
    }

    return {
      'debit': totalDebitSys,
      'credit': totalCreditSys,
      'net': totalDebitSys - totalCreditSys,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);
    textTheme.titleSmall?.copyWith(color: color.surface);
    TextStyle? bodyStyle = textTheme.bodyMedium?.copyWith();
    final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
    final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = auth.loginData;

    return BlocConsumer<FetchAtatBloc, FetchAtatState>(
      listener: (context, state) {
        if (state is FetchATATLoadedState) {
          loadedAtat = state.atat;
        }
      },
      builder: (context, state) {
        if (state is FetchATATLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FetchATATLoadedState) {
          loadedAtat = state.atat;
        }

        if (state is FetchATATErrorState) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Calculate totals
        double totalDebit = 0;
        double totalCredit = 0;

        if (loadedAtat != null) {
          if (loadedAtat!.debit != null) {
            for (var dr in loadedAtat!.debit!) {
              totalDebit += double.tryParse(dr.trdAmount ?? '0') ?? 0;
            }
          }
          if (loadedAtat!.credit != null) {
            for (var cr in loadedAtat!.credit!) {
              totalCredit += double.tryParse(cr.trdAmount ?? '0') ?? 0;
            }
          }
        }

        final bool showAuthorizeButton = loadedAtat?.trnStatus == 0 &&
            login.usrName != loadedAtat?.maker;
        final bool showDeleteButton = loadedAtat?.trnStatus == 0 &&
            loadedAtat?.maker == login.usrName;
        final bool showAnyButton = showAuthorizeButton || showDeleteButton;

        return ZFormDialog(
          width: MediaQuery.of(context).size.width * .6,
          isActionTrue: false,
          padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
          onAction: null,
          icon: Icons.ssid_chart,
          title: getTitle(context, loadedAtat?.trnType ?? ""),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Text(tr.referenceNumber, style: titleStyle),
                          Text(tr.status, style: titleStyle),
                          Text(tr.branch, style: titleStyle),
                          Text(tr.maker, style: titleStyle),
                          if(loadedAtat?.checker != null && loadedAtat!.checker!.isNotEmpty)
                            Text(tr.checker, style: titleStyle),
                          Text(tr.narration, style: titleStyle),
                          Text(tr.date, style: titleStyle),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Text(loadedAtat?.trnReference ?? "", style: bodyStyle),
                        Text(
                            loadedAtat?.trnStatus == 1
                                ? tr.authorizedTransaction
                                : tr.pendingTransactions,
                            style: bodyStyle
                        ),
                        Text(loadedAtat?.trdBranch.toString() ?? "", style: bodyStyle),
                        Text(loadedAtat?.maker ?? "", style: bodyStyle),
                        if(loadedAtat?.checker != null && loadedAtat!.checker!.isNotEmpty)
                          Text(loadedAtat?.checker ?? "", style: bodyStyle),
                        Text(loadedAtat?.trdNarration ?? "", style: bodyStyle),
                        Text(
                          loadedAtat!.trnEntryDate!.toFullDateTime,
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Debit and Credit Tables Row
              SizedBox(
                height: 300, // Fixed height for tables
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Debit Table
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: color.outline.withValues(alpha: .2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Debit Header with Title and Total
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: .1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [

                                      Text(
                                        tr.debitTitle,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,

                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${tr.totalTitle}: ',
                                          style: textTheme.bodySmall?.copyWith(

                                          ),
                                        ),
                                        Text(
                                          totalDebit.toAmount(),
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,

                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Table Headers
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.surface,
                                border: Border(
                                  bottom: BorderSide(color: color.outline.withValues(alpha: .2)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      tr.accountName,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      tr.accountNumber,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      tr.amount,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Debit Items List
                            Expanded(
                              child: loadedAtat?.debit == null || loadedAtat!.debit!.isEmpty
                                  ? Center(
                                child: Text(
                                  'No debit entries',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: color.outline,
                                  ),
                                ),
                              )
                                  : ListView.builder(
                                itemCount: loadedAtat!.debit!.length,
                                itemBuilder: (context, index) {
                                  final dr = loadedAtat!.debit![index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: index.isOdd
                                          ? color.primary.withValues(alpha: .02)
                                          : Colors.transparent,
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
                                          child: Text(
                                            dr.accName ?? "",
                                            style: bodyStyle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            dr.trdAccount.toString(),
                                            style: bodyStyle,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  dr.trdAmount?.toAmount() ?? "",
                                                  style: bodyStyle?.copyWith(
                                                    fontWeight: FontWeight.w500,

                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                dr.trdCcy ?? "",
                                                style: textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Credit Table
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: color.outline.withValues(alpha: .2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Credit Header with Title and Total
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: .1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        tr.creditTitle,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,

                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${tr.totalTitle}: ',
                                        ),
                                        Text(
                                          totalCredit.toAmount(),
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,

                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Table Headers
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.surface,
                                border: Border(
                                  bottom: BorderSide(color: color.outline.withValues(alpha: .2)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      tr.accountName,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      tr.accountNumber,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      tr.amount,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Credit Items List
                            Expanded(
                              child: loadedAtat?.credit == null || loadedAtat!.credit!.isEmpty
                                  ? Center(
                                child: Text(
                                  'No credit entries',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: color.outline,
                                  ),
                                ),
                              )
                                  : ListView.builder(
                                itemCount: loadedAtat!.credit!.length,
                                itemBuilder: (context, index) {
                                  final cr = loadedAtat!.credit![index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: index.isOdd
                                          ? color.primary.withValues(alpha: .02)
                                          : Colors.transparent,
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
                                          child: Text(
                                            cr.accName ?? "",
                                            style: bodyStyle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            cr.trdAccount.toString(),
                                            style: bodyStyle,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  cr.trdAmount?.toAmount() ?? "",
                                                  style: bodyStyle?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.red,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                cr.trdCcy ?? "",
                                                style: textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),



              const SizedBox(height: 8),
              Divider(
                indent: 5,
                endIndent: 5,
                color: color.primary,
                thickness: 1,
              ),
              const SizedBox(height: 2),

              // Action Buttons
              if (showAnyButton)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(

                    children: [
                      if (showAuthorizeButton)
                        ZOutlineButton(
                          onPressed: isAuthorizeLoading ? null : () {
                            context.read<TransactionsBloc>().add(
                              AuthorizeTxnEvent(
                                reference: loadedAtat?.trnReference ?? "",
                                usrName: login.usrName ?? "",
                              ),
                            );
                          },
                          icon: isAuthorizeLoading ? null : Icons.check_box_outlined,
                          isActive: true,
                          label: isAuthorizeLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                              : Text(tr.authorize),
                        ),
                      if (showAuthorizeButton && showDeleteButton)
                        const SizedBox(width: 8),
                      if (showDeleteButton)
                        ZOutlineButton(
                          onPressed: isDeleteLoading ? null : () {
                            context.read<TransactionsBloc>().add(
                              DeletePendingTxnEvent(
                                reference: loadedAtat?.trnReference ?? "",
                                usrName: login.usrName ?? "",
                              ),
                            );
                          },
                          icon: isDeleteLoading ? null : Icons.delete_outline_rounded,
                          isActive: true,
                          backgroundHover: Theme.of(context).colorScheme.error,
                          label: isDeleteLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                              : Text(tr.delete),
                        ),
                      SizedBox(width: 5),
                      ZOutlineButton(
                          onPressed: _printTransaction,
                          isActive: true,
                          icon: Icons.print,
                          label: Text(tr.print))
                    ],
                  ),
                ),
              if (!showAnyButton) const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

}