import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Features/Other/utils.dart';
import 'bloc/txn_ref_report_bloc.dart';
import 'model/txn_report_model.dart';

class TransactionByReferenceView extends StatelessWidget {
  const TransactionByReferenceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _Mobile(),
      tablet: const _Tablet(),
      desktop: const _Desktop(),
    );
  }
}
class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final ref = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TxnRefReportBloc>().add(ResetTxnReportByReferenceEvent());
  }

  @override
  void dispose() {
    ref.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (ref.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<TxnRefReportBloc>().add(LoadTxnReportByReferenceEvent(ref.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.transactionDetails),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ZTextFieldEntitled(
                    compactMode: true,
                    controller: ref,
                    icon: Icons.search_rounded,
                    title: '',
                    isRequired: true,
                    hint: tr.referenceNumber,
                    onSubmit: (e)=> onSubmit,
                  ),
                ),
                const SizedBox(width: 5),
                ZOutlineButton(
                  width: 100,
                  height: 47,
                  isActive: true,
                  onPressed: onSubmit,
                  label: Text(tr.submit),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<TxnRefReportBloc, TxnRefReportState>(
              builder: (context, state) {
                if (state is TxnRefReportLoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is TxnRefReportErrorState) {
                  return NoDataWidget(
                    title: tr.noDataFound,
                    message: state.message,
                    enableAction: false,
                  );
                }

                if (state is TxnRefReportLoadedState) {
                  final txn = state.txn;
                  final records = txn.records ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Transaction Summary Card
                        _buildMobileSummaryCard(txn, color, textTheme, tr),

                        const SizedBox(height: 16),

                        // Records
                        if (records.isNotEmpty) ...[
                          Text(
                            'Transaction Lines',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...records.asMap().entries.map((entry) {
                            final index = entry.key;
                            final record = entry.value;
                            return _buildMobileRecordCard(record, index, color, textTheme, tr);
                          }),
                        ],
                      ],
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: color.outline.withValues(alpha: .3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr.transactionSummary,
                        style: textTheme.bodyLarge?.copyWith(
                          color: color.outline.withValues(alpha: .6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter a reference number to view details',
                        style: textTheme.bodyMedium?.copyWith(
                          color: color.outline.withValues(alpha: .5),
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
    );
  }

  Widget _buildMobileSummaryCard(
      TxnReportByRefModel txn,
      ColorScheme color,
      TextTheme textTheme,
      AppLocalizations tr,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.primary.withValues(alpha: .2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt,
                  color: color.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.transactionDetails,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      txn.trnReference ?? "-",
                      style: textTheme.bodySmall?.copyWith(
                        color: color.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: txn.trnStateText?.toLowerCase() == 'approved'
                      ? Colors.green.withValues(alpha: .1)
                      : color.error.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  txn.trnStateText ?? "-",
                  style: TextStyle(
                    color: txn.trnStateText?.toLowerCase() == 'approved'
                        ? Colors.green
                        : color.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info Grid
          _buildInfoRow(Icons.calendar_today, tr.date, txn.trnEntryDate != null
              ? txn.trnEntryDate.toFormattedDate()
              : "-", color),
          _buildInfoRow(Icons.category, tr.transactionType, txn.trntName ?? "-", color),
          _buildInfoRow(Icons.person, tr.maker, txn.maker ?? "-", color),
          _buildInfoRow(Icons.person_outline, tr.checker, txn.checker ?? tr.notAuthorizedYet, color),
          _buildInfoRow(Icons.type_specimen, 'Type Code', txn.trnType ?? "-", color),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color.outline,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRecordCard(
      Record record,
      int index,
      ColorScheme color,
      TextTheme textTheme,
      AppLocalizations tr,
      ) {
    final isDebit = record.debitCredit?.toLowerCase() == 'debit';
    final amount = double.tryParse(record.trdAmount ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: index.isOdd ? color.primary.withValues(alpha: .02) : color.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.outline.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Info
          Row(
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
                  record.trdAccount?.toString() ?? "-",
                  style: TextStyle(
                    fontSize: 12,
                    color: color.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.accName ?? "-",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date and Type
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12,
                color: color.outline,
              ),
              const SizedBox(width: 4),
              Text(
                record.trdEntryDate != null
                    ? record.trdEntryDate.toFormattedDate()
                    : "-",
                style: TextStyle(
                  fontSize: 12,
                  color: color.outline,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDebit
                      ? Colors.blue.withValues(alpha: .1)
                      : Colors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  record.debitCredit ?? "-",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDebit ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Narration
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.outline.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              record.trdNarration ?? "-",
              style: TextStyle(
                fontSize: 12,
                color: color.outline,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr.amount,
                style: TextStyle(
                  fontSize: 13,
                  color: color.outline,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount.toAmount(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record.trdCcy ?? "",
                      style: TextStyle(
                        fontSize: 11,
                        color: Utils.currencyColors(record.trdCcy ?? ""),
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
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  final ref = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TxnRefReportBloc>().add(ResetTxnReportByReferenceEvent());
  }

  @override
  void dispose() {
    ref.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (ref.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<TxnRefReportBloc>().add(LoadTxnReportByReferenceEvent(ref.text.trim()));
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

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.transactionDetails),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 270,
                  child: ZTextFieldEntitled(
                    controller: ref,
                    icon: Icons.code,
                    title: '',
                    isRequired: true,
                    hint: tr.referenceNumber,
                    onSubmit: (e)=> onSubmit,
                  ),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  width: 100,
                  onPressed: onSubmit,
                  icon: Icons.search,
                  isActive: true,
                  label: Text(tr.apply),
                ),
              ],
            ),
          ),
        ],
      ),
      body: BlocBuilder<TxnRefReportBloc, TxnRefReportState>(
        builder: (context, state) {
          if (state is TxnRefReportLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TxnRefReportErrorState) {
            return NoDataWidget(
              title: tr.noDataFound,
              message: state.message,
              enableAction: false,
            );
          }

          if (state is TxnRefReportLoadedState) {
            final txn = state.txn;
            final records = txn.records ?? [];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.primary.withValues(alpha: .2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.primary.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.receipt,
                                    color: color.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr.transactionDetails,
                                      style: textTheme.titleLarge,
                                    ),
                                    Text(
                                      txn.trnReference ?? "-",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: color.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: txn.trnStateText?.toLowerCase() == 'approved'
                                    ? Colors.green.withValues(alpha: .1)
                                    : color.error.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                txn.trnStateText ?? "-",
                                style: TextStyle(
                                  color: txn.trnStateText?.toLowerCase() == 'approved'
                                      ? Colors.green
                                      : color.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Info Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          childAspectRatio: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 16,
                          children: [
                            _buildTabletSummaryItem(
                                tr.date,
                                txn.trnEntryDate != null
                                    ? txn.trnEntryDate.toFormattedDate()
                                    : "-",
                                Icons.calendar_today,
                                color
                            ),
                            _buildTabletSummaryItem(
                                tr.transactionType,
                                txn.trntName ?? "-",
                                Icons.category,
                                color
                            ),
                            _buildTabletSummaryItem(
                                tr.maker,
                                txn.maker ?? "-",
                                Icons.person,
                                color
                            ),
                            _buildTabletSummaryItem(
                                tr.checker,
                                txn.checker ?? tr.notAuthorizedYet,
                                Icons.person_outline,
                                color
                            ),
                            _buildTabletSummaryItem(
                                'Type Code',
                                txn.trnType ?? "-",
                                Icons.type_specimen,
                                color
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Records Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(tr.date, style: titleStyle),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(tr.accounts, style: titleStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(tr.accountName, style: titleStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(tr.narration, style: titleStyle),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text("CR/DR", style: titleStyle),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(tr.amount, style: titleStyle, textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),

                  // Records List
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: color.outline.withValues(alpha: .1)),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: color.outline.withValues(alpha: .1),
                        ),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final isDebit = record.debitCredit?.toLowerCase() == 'debit';
                          final amount = double.tryParse(record.trdAmount ?? '0') ?? 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            color: index.isOdd
                                ? color.primary.withValues(alpha: .02)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                // Date
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    record.trdEntryDate != null
                                        ? record.trdEntryDate.toFormattedDate()
                                        : "-",
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                // Account Number
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    record.trdAccount?.toString() ?? "-",
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                // Account Name
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    record.accName ?? "-",
                                    style: textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Narration
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    message: record.trdNarration ?? "",
                                    child: Text(
                                      record.trdNarration ?? "-",
                                      style: textTheme.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                // Debit/Credit
                                SizedBox(
                                  width: 70,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDebit
                                          ? Colors.blue.withValues(alpha: .1)
                                          : Colors.green.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      record.debitCredit ?? "-",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDebit ? Colors.blue : Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                // Amount
                                SizedBox(
                                  width: 120,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          amount.toAmount(),
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        record.trdCcy ?? "",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Utils.currencyColors(record.trdCcy ?? ""),
                                        ),
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
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: color.outline.withValues(alpha: .3),
                ),
                const SizedBox(height: 16),
                Text(
                  tr.transactionSummary,
                  style: textTheme.headlineSmall?.copyWith(
                    color: color.outline.withValues(alpha: .6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabletSummaryItem(String label, String value, IconData icon, ColorScheme color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.outline,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final ref = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TxnRefReportBloc>().add(ResetTxnReportByReferenceEvent());
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.transactionDetails),
        titleSpacing: 0,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ZTextFieldEntitled(
                    controller: ref,
                    icon: Icons.search_rounded,
                    title: '',
                    isRequired: true,
                    hint: tr.referenceNumber,
                    onSubmit: (_) => onSubmit(),
                  ),
                ),
                const SizedBox(width: 5),
                ZOutlineButton(
                  width: 120,
                  onPressed: onSubmit,
                  isActive: true,
                  icon: Icons.refresh,
                  label: Text(tr.submit.toUpperCase()),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<TxnRefReportBloc, TxnRefReportState>(
              builder: (context, state) {
                if (state is TxnRefReportLoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is TxnRefReportErrorState) {
                  return NoDataWidget(
                    title: tr.noDataFound,
                    message: state.message,
                  );
                }

                if (state is TxnRefReportLoadedState) {
                  final txn = state.txn;
                  final records = txn.records ?? [];

                  return Column(
                    children: [
                      // Transaction Summary Card
                      ZCover(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        radius: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              spacing:5,
                              children: [
                                Icon(Icons.qr_code_2_outlined),
                                Text(
                                  tr.transactionDetails,
                                  style: textTheme.titleMedium
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
                                  txn.trnEntryDate?.toDateTime ?? "-",
                                  color,
                                ),
                                _buildSummaryItem(
                                  tr.referenceNumber,
                                  txn.trnReference ?? "-",
                                  color,
                                ),
                                _buildSummaryItem(
                                  tr.transactionType,
                                  txn.trntName ?? "-",
                                  color,
                                ),
                                _buildSummaryItem(
                                  tr.maker,
                                  txn.maker ?? "-",
                                  color,
                                ),
                                _buildSummaryItem(
                                  tr.checker,
                                  txn.checker ?? tr.notAuthorizedYet,
                                  color,
                                ),
                                _buildSummaryItem(
                                  tr.txnType,
                                  txn.trnType ?? "-",
                                  color,
                                ),
                                _buildSummaryItem(
                                  tr.status,
                                  txn.trnStateText ?? "-",
                                  color,
                                  isStatus: true,
                                ),

                              ],
                            ),
                          ],
                        ),
                      ),

                      // Records Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .9),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 170,
                              child: Text(
                                tr.date,
                                  style: titleStyle
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                tr.accounts,
                                  style: titleStyle
                              ),
                            ),
                            SizedBox(
                             width: 150,
                              child: Text(
                                tr.accountName,
                                  style: titleStyle
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tr.narration,
                                style: titleStyle
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                "CR/DR",
                                  style: titleStyle
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: Text(
                                tr.amount,
                                  style: titleStyle
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Records List
                      Expanded(
                        child: ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: color.outline.withValues(alpha: .1),
                          ),
                          itemBuilder: (context, index) {
                            final record = records[index];

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              color: index.isOdd
                                  ? color.primary.withValues(alpha: .05)
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
                                        style: textTheme.titleSmall
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
                                      style: textTheme.titleMedium
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
                );
              },
            ),
          ),
        ],
      ),
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

  void onSubmit() {
    if (ref.text.trim().isEmpty) return;
    context
        .read<TxnRefReportBloc>()
        .add(LoadTxnReportByReferenceEvent(ref.text.trim()));
  }
}