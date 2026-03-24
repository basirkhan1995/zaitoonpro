import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/txn_ref_report_bloc.dart';

class TransactionReferenceDialog extends StatefulWidget {
  final String reference;
  final bool autoLoad;

  const TransactionReferenceDialog({
    super.key,
    required this.reference,
    this.autoLoad = true,
  });

  @override
  State<TransactionReferenceDialog> createState() => _TransactionReferenceDialogState();
}

class _TransactionReferenceDialogState extends State<TransactionReferenceDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTransaction();
      });
    }
  }

  void _loadTransaction() {
    if (widget.reference.isNotEmpty) {
      context.read<TxnRefReportBloc>().add(
        LoadTxnReportByReferenceEvent(widget.reference.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
      color: color.surface,
      fontWeight: FontWeight.w500,
    );

    return BlocBuilder<TxnRefReportBloc, TxnRefReportState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Transaction Summary Card
            if (state is! TxnRefReportLoadingState &&
                state is! TxnRefReportErrorState &&
                state is TxnRefReportLoadedState)
              ZCover(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                radius: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      spacing: 5,
                      children: [
                        Icon(Icons.qr_code_2_outlined),
                        Text(
                          tr.transactionDetails,
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Divider(),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 32,
                      runSpacing: 16,
                      children: [
                        _buildSummaryItem(
                          tr.date,
                          state.txn.trnEntryDate?.toDateTime ?? "-",
                          color,
                        ),
                        _buildSummaryItem(
                          tr.referenceNumber,
                          state.txn.trnReference ?? "-",
                          color,
                        ),
                        _buildSummaryItem(
                          tr.transactionType,
                          state.txn.trntName ?? "-",
                          color,
                        ),
                        _buildSummaryItem(
                          tr.maker,
                          state.txn.maker ?? "-",
                          color,
                        ),
                        _buildSummaryItem(
                          tr.checker,
                          state.txn.checker ?? tr.notAuthorizedYet,
                          color,
                        ),
                        _buildSummaryItem(
                          tr.txnType,
                          state.txn.trnType ?? "-",
                          color,
                        ),
                        _buildSummaryItem(
                          tr.status,
                          state.txn.trnStateText ?? "-",
                          color,
                          isStatus: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Loading State
            if (state is TxnRefReportLoadingState)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Error State
            if (state is TxnRefReportErrorState)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: NoDataWidget(
                  title: tr.noDataFound,
                  message: state.message,
                  onRefresh: _loadTransaction,
                ),
              ),

            // Loaded State with Records
            if (state is TxnRefReportLoadedState &&
                (state.txn.records?.isNotEmpty ?? false))
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Records Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .9),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 170,
                          child: Text(tr.date, style: titleStyle),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(tr.accounts, style: titleStyle),
                        ),
                        SizedBox(
                          width: 150,
                          child: Text(tr.accountName, style: titleStyle),
                        ),
                        Expanded(
                          child: Text(tr.narration, style: titleStyle),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text("CR/DR", style: titleStyle),
                        ),
                        SizedBox(
                          width: 150,
                          child: Text(tr.amount, style: titleStyle),
                        ),
                      ],
                    ),
                  ),

                  // Records List
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.txn.records?.length ?? 0,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: color.outline.withValues(alpha: .1),
                      ),
                      itemBuilder: (context, index) {
                        final record = state.txn.records![index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          color: index.isEven
                              ? color.primary.withValues(alpha: .03)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 170,
                                child: Text(
                                  record.trdEntryDate?.toDateTime ?? "-",
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  record.trdAccount?.toString() ?? "-",
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  record.accName ?? "-",
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              Expanded(
                                child: Tooltip(
                                  message: record.trdNarration ?? "",
                                  child: Text(
                                    record.trdNarration ?? "-",
                                    style: textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  record.debitCredit?.toString() ?? "-",
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  "${record.trdAmount?.toAmount() ?? "0.00"} ${record.trdCcy ?? ""}",
                                  style: textTheme.bodyMedium,
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

            // Initial State or Empty State
            if (state is! TxnRefReportLoadedState &&
                state is! TxnRefReportLoadingState &&
                state is! TxnRefReportErrorState)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: color.outline.withValues(alpha: .3),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr.transactionSummary,
                      style: textTheme.bodyLarge?.copyWith(
                        color: color.outline.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(
      String title,
      String value,
      ColorScheme color, {
        bool isStatus = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: color.outline.withValues(alpha: .7),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}