import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/txn_status_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/TxnByReference/bloc/txn_reference_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/bloc/transactions_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/model/transaction_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import 'Print/txn_print.dart';
import 'model/txn_ref_model.dart';

class TxnReferenceView extends StatelessWidget {
  final String? txnView;
  const TxnReferenceView({super.key,this.txnView});
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(txnView),
      tablet: _Desktop(txnView),
      desktop: _Desktop(txnView),
    );
  }
}

class _Mobile extends StatelessWidget {
  final String? txnView;
  const _Mobile(this.txnView);

  @override
  Widget build(BuildContext context) {
    return const _MobileTxnReferenceView();
  }
}
class _MobileTxnReferenceView extends StatefulWidget {
  const _MobileTxnReferenceView();

  @override
  State<_MobileTxnReferenceView> createState() => _MobileTxnReferenceViewState();
}

class _MobileTxnReferenceViewState extends State<_MobileTxnReferenceView> {
  final TextEditingController narration = TextEditingController();
  final TextEditingController amount = TextEditingController();
  TxnByReferenceModel? loadedTxn;
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  String? reference;

  @override
  void dispose() {
    narration.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
    final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;
    final isUpdateLoading = context.watch<TransactionsBloc>().state is TxnUpdateLoadingState;
    final isReverseLoading = context.watch<TransactionsBloc>().state is TxnReverseLoadingState;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = auth.loginData;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(locale.txnDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              if (loadedTxn != null) {
                _getPrint(data: loadedTxn!, company: company);
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
        builder: (context, state) {
          if (state is CompanyProfileLoadedState) {
            company.comName = state.company.comName ?? "";
            company.comAddress = state.company.addName ?? "";
            company.compPhone = state.company.comPhone ?? "";
            company.comEmail = state.company.comEmail ?? "";
            company.statementDate = DateTime.now().toFullDateTime;
            final base64Logo = state.company.comLogo;
            if (base64Logo != null && base64Logo.isNotEmpty) {
              try {
                _companyLogo = base64Decode(base64Logo);
                company.comLogo = _companyLogo;
              } catch (e) {
                _companyLogo = Uint8List(0);
              }
            }
          }
          return BlocConsumer<TxnReferenceBloc, TxnReferenceState>(
            listener: (context, state) {
              if (state is TxnReferenceErrorState) {
                Utils.showOverlayMessage(context, message: state.error, isError: true);
              }
            },
            builder: (context, state) {
              if (state is TxnReferenceLoadedState) {
                loadedTxn = state.transaction;
                narration.text = state.transaction.narration ?? "";
                reference = state.transaction.trnReference ?? "";
                amount.text = state.transaction.amount?.toAmount() ?? "";

                final bool isAlreadyReversed = loadedTxn?.trnStatusText == "Reversed";
                final bool isAlreadyDeleted = loadedTxn?.trnStatusText == "Deleted";

                final bool showAuthorizeButton = loadedTxn?.trnStatus == 0 && login.usrName != loadedTxn?.maker;
                final bool showReverseButton = loadedTxn?.trnStatus == 1 && loadedTxn?.maker == login.usrName;
                final bool showUpdateButton = loadedTxn?.trnStatus == 0 && loadedTxn?.maker == login.usrName;
                final bool showDeleteButton = loadedTxn?.trnStatus == 0 && loadedTxn?.maker == login.usrName;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Type and Amount Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.outline.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Utils.getTxnCode(txn: loadedTxn?.trnType ?? "", context: context),
                              style: textTheme.titleLarge?.copyWith(
                                color: color.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${loadedTxn?.amountText.toAmount()} ${loadedTxn?.currencyText}",
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Transaction Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.outline.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  locale.details,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TransactionStatusBadge(status: state.transaction.trnStatusText ?? ""),
                              ],
                            ),
                            const Divider(height: 16),

                            // Transaction Details Grid
                            _buildDetailRow(locale.referenceNumber, state.transaction.trnReferenceText, context),
                            _buildDetailRow(locale.date, state.transaction.trnEntryDate!.toFullDateTime, context),
                            _buildDetailRow(locale.accountNumber, state.transaction.accountText, context),
                            _buildDetailRow(locale.accountName, state.transaction.accNameText, context),
                            _buildDetailRow(locale.branch, state.transaction.branchText, context),
                            _buildDetailRow(locale.maker, state.transaction.makerText, context),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Editable Fields Card
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ZTextFieldEntitled(
                            isRequired: true,
                            keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormat: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                              SmartThousandsDecimalFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return locale.required(locale.exchangeRate);
                              }
                              final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                              final amount = double.tryParse(clean);
                              if (amount == null || amount <= 0.0) {
                                return locale.amountGreaterZero;
                              }
                              return null;
                            },
                            controller: amount,
                            title: locale.amount,
                          ),
                          const SizedBox(height: 12),
                          ZTextFieldEntitled(
                            keyboardInputType: TextInputType.multiline,
                            controller: narration,
                            title: locale.narration,
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Action Buttons
                      if (showAuthorizeButton || showReverseButton || showUpdateButton || showDeleteButton)
                        Column(
                          children: [
                            if (showAuthorizeButton && !isAlreadyDeleted)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ZOutlineButton(
                                    isActive: true,
                                    onPressed: isAuthorizeLoading ? null : () {
                                      context.read<TransactionsBloc>().add(
                                        AuthorizeTxnEvent(
                                          reference: reference ?? "",
                                          usrName: login.usrName ?? "",
                                        ),
                                      );
                                    },
                                    icon: Icons.check_circle_outline ,
                                    label: isAuthorizeLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : Text(locale.authorize),
                                  ),
                                ),
                              ),

                            if (showReverseButton && !isAlreadyReversed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ZOutlineButton(
                                    isActive: true,
                                    onPressed: isReverseLoading ? null : () {
                                      context.read<TransactionsBloc>().add(
                                        ReverseTxnEvent(
                                          reference: reference ?? "",
                                          usrName: login.usrName ?? "",
                                        ),
                                      );
                                    },
                                    icon: Icons.screen_rotation_alt,
                                    label: isReverseLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : Text(locale.reverseTitle),
                                  ),
                                ),
                              ),

                            if (showUpdateButton && !isAlreadyDeleted)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ZOutlineButton(
                                    isActive: true,
                                    onPressed: isUpdateLoading ? null : () {
                                      context.read<TransactionsBloc>().add(
                                        UpdatePendingTransactionEvent(
                                          TransactionsModel(
                                            trnReference: loadedTxn?.trnReference ?? "",
                                            usrName: login.usrName,
                                            trdCcy: loadedTxn?.currency ?? "",
                                            trdNarration: narration.text,
                                            trdAmount: amount.text.cleanAmount,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icons.refresh,
                                    label: isUpdateLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : Text(locale.update),
                                  ),
                                ),
                              ),

                            if (showDeleteButton && !isAlreadyDeleted)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ZOutlineButton(
                                    onPressed: isDeleteLoading ? null : () {
                                      _showDeleteConfirmation(
                                        context,
                                        onConfirm: () {
                                          context.read<TransactionsBloc>().add(
                                            DeletePendingTxnEvent(
                                              reference: loadedTxn?.trnReference ?? "",
                                              usrName: login.usrName ?? "",
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    icon: Icons.delete_outline,
                                    label: isDeleteLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : Text(locale.delete),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: color.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, {required VoidCallback onConfirm}) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("confirmation"),
        content: Text("deleteConfirmation"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color.error,
              foregroundColor: color.surface,
            ),
            child: Text(locale.delete),
          ),
        ],
      ),
    );
  }

  void _getPrint({required TxnByReferenceModel data, required ReportModel company}) {
    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<TxnByReferenceModel>(
        data: data,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return TransactionReferencePrintSettings().printPreview(
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            data: data,
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
          return TransactionReferencePrintSettings().printDocument(
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
            data: data,
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
          return TransactionReferencePrintSettings().createDocument(
            data: data,
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

class _Desktop extends StatefulWidget {
  final String? txnView;
  const _Desktop(this.txnView);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final TextEditingController narration = TextEditingController();
  final TextEditingController amount = TextEditingController();
  TxnByReferenceModel? loadedTxn;
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  String? reference;

  @override
  void dispose() {
    narration.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isLoading = context.watch<TransactionsBloc>().state is TxnLoadingState;
    final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
    final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;
    final isUpdateLoading = context.watch<TransactionsBloc>().state is TxnUpdateLoadingState;
    final isReverseLoading = context.watch<TransactionsBloc>().state is TxnReverseLoadingState;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = auth.loginData;

    return BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
      builder: (context, state) {
        if (state is CompanyProfileLoadedState) {
          company.comName = state.company.comName ?? "";
          company.comAddress = state.company.addName ?? "";
          company.compPhone = state.company.comPhone ?? "";
          company.comEmail = state.company.comEmail ?? "";
          company.statementDate = DateTime.now().toFullDateTime;
          final base64Logo = state.company.comLogo;
          if (base64Logo != null && base64Logo.isNotEmpty) {
            try {
              _companyLogo = base64Decode(base64Logo);
              company.comLogo = _companyLogo;
            } catch (e) {
              _companyLogo = Uint8List(0);
            }
          }
        }
        return ZFormDialog(
          width: 500,
          isActionTrue: false,
          icon: Icons.add_chart_rounded,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          onAction: null,
          actionLabel: isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.surface,
            ),
          )
              : Text(locale.authorize),
          title: locale.txnDetails,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocConsumer<TxnReferenceBloc, TxnReferenceState>(
                  listener: (context, state) {
                    if (state is TxnReferenceErrorState) {
                      Utils.showOverlayMessage(context, message: state.error, isError: true);
                    }
                  },
                  builder: (context, state) {
                    if (state is TxnReferenceLoadedState) {
                      loadedTxn = state.transaction;
                      narration.text = state.transaction.narration ?? "";
                      reference = state.transaction.trnReference ?? "";
                      amount.text = state.transaction.amount?.toAmount() ?? "";

                      final bool isAlreadyReversed = loadedTxn?.trnStatusText == "Reversed";
                      final bool isAlreadyDeleted = loadedTxn?.trnStatusText == "Deleted";

                      final bool showAuthorizeButton = loadedTxn?.trnStatus == 0 && login.usrName != loadedTxn?.maker;
                      final bool showReverseButton = loadedTxn?.trnStatus == 1 && loadedTxn?.maker == login.usrName;
                      final bool showUpdateButton = loadedTxn?.trnStatus == 0 && loadedTxn?.maker == login.usrName;
                      final bool showDeleteButton = loadedTxn?.trnStatus == 0 && loadedTxn?.maker == login.usrName;

                      final bool showAnyButton = showAuthorizeButton || showReverseButton || showUpdateButton || showDeleteButton;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            width: double.infinity,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      Utils.getTxnCode(txn: loadedTxn?.trnType ?? "", context: context),
                                      style: textTheme.titleMedium?.copyWith(
                                        fontSize: 25,
                                        color: color.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${loadedTxn?.amountText.toAmount()} ${loadedTxn?.currencyText}",
                                      style: textTheme.titleMedium?.copyWith(fontSize: 25),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      locale.details,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: color.primary,
                                        fontSize: 15,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _getPrint(data: state.transaction, company: company),
                                      child: Icon(Icons.print, size: 20, color: color.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Divider(thickness: 2, color: color.primary),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 170,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 3,
                                        children: [
                                          Text("${locale.transactionRef}:", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                          Text("${locale.transactionDate}:", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                          Text("${locale.accountNumber}:", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                          Text("${locale.accountName}:", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                          Text("${locale.amount}:", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                          Text("${locale.branch}:", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                          Text("${locale.maker}:", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                          Text("${locale.status}:", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      spacing: 3,
                                      children: [
                                        Text(state.transaction.trnReferenceText, style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                        Text(state.transaction.trnEntryDate!.toFullDateTime, style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                        Text(state.transaction.accountText, style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                        Text(state.transaction.accNameText, style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                        Text("${state.transaction.amountText.toAmount()} ${state.transaction.currencyText}", style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                        Text(state.transaction.branchText, style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                        Text(state.transaction.makerText, style: textTheme.titleSmall?.copyWith(color: color.secondary)),
                                        TransactionStatusBadge(status: state.transaction.trnStatusText ?? ""),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ZTextFieldEntitled(
                                  isRequired: true,
                                  keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormat: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                                    SmartThousandsDecimalFormatter(),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return locale.required(locale.exchangeRate);
                                    }
                                    final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                                    final amount = double.tryParse(clean);
                                    if (amount == null || amount <= 0.0) {
                                      return locale.amountGreaterZero;
                                    }
                                    return null;
                                  },
                                  controller: amount,
                                  title: locale.amount,
                                ),
                                const SizedBox(height: 10),
                                ZTextFieldEntitled(
                                  keyboardInputType: TextInputType.multiline,
                                  controller: narration,
                                  title: locale.narration,
                                ),
                              ],
                            ),
                          ),
                          if (showAnyButton)
                            Column(
                              children: [
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                                  child: Row(
                                    spacing: 8,
                                    children: [
                                      if (showAuthorizeButton && !isAlreadyDeleted)
                                        Expanded(
                                          child: ZOutlineButton(
                                            onPressed: () {
                                              context.read<TransactionsBloc>().add(
                                                AuthorizeTxnEvent(
                                                  reference: reference ?? "",
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
                                                : Text(locale.authorize),
                                          ),
                                        ),
                                      if (showReverseButton && !isAlreadyReversed)
                                        Expanded(
                                          child: ZOutlineButton(
                                            isActive: true,
                                            onPressed: () {
                                              context.read<TransactionsBloc>().add(
                                                ReverseTxnEvent(
                                                  reference: reference ?? "",
                                                  usrName: login.usrName ?? "",
                                                ),
                                              );
                                            },
                                            icon: isReverseLoading ? null : Icons.screen_rotation_alt_rounded,
                                            backgroundHover: Colors.orange,
                                            label: isReverseLoading
                                                ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 3),
                                            )
                                                : Text(locale.reverseTitle),
                                          ),
                                        ),
                                      if (showUpdateButton && !isAlreadyDeleted)
                                        Expanded(
                                          child: ZOutlineButton(
                                            backgroundHover: Colors.green,
                                            isActive: true,
                                            icon: isUpdateLoading ? null : Icons.refresh,
                                            onPressed: () {
                                              context.read<TransactionsBloc>().add(
                                                UpdatePendingTransactionEvent(
                                                  TransactionsModel(
                                                    trnReference: loadedTxn?.trnReference ?? "",
                                                    usrName: login.usrName,
                                                    trdCcy: loadedTxn?.currency ?? "",
                                                    trdNarration: narration.text,
                                                    trdAmount: amount.text.cleanAmount,
                                                  ),
                                                ),
                                              );
                                            },
                                            label: isUpdateLoading
                                                ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 3),
                                            )
                                                : Text(locale.update),
                                          ),
                                        ),
                                      if (showDeleteButton && !isAlreadyDeleted)
                                        Expanded(
                                          child: ZOutlineButton(
                                            icon: isDeleteLoading ? null : Icons.delete_outline_rounded,
                                            isActive: true,
                                            backgroundHover: Theme.of(context).colorScheme.error,
                                            onPressed: () {
                                              context.read<TransactionsBloc>().add(
                                                DeletePendingTxnEvent(
                                                  reference: loadedTxn?.trnReference ?? "",
                                                  usrName: login.usrName ?? "",
                                                ),
                                              );
                                            },
                                            label: isDeleteLoading
                                                ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 3),
                                            )
                                                : Text(locale.delete),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          if (!showAnyButton) const SizedBox(height: 10),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _getPrint({required TxnByReferenceModel data, required ReportModel company}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => PrintPreviewDialog<TxnByReferenceModel>(
          data: data,
          company: company,
          buildPreview: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return TransactionReferencePrintSettings().printPreview(
              company: company,
              language: language,
              orientation: orientation,
              pageFormat: pageFormat,
              data: data,
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
            return TransactionReferencePrintSettings().printDocument(
              company: company,
              language: language,
              orientation: orientation,
              pageFormat: pageFormat,
              selectedPrinter: selectedPrinter,
              data: data,
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
            return TransactionReferencePrintSettings().createDocument(
              data: data,
              company: company,
              language: language,
              orientation: orientation,
              pageFormat: pageFormat,
            );
          },
        ),
      );
    });
  }
}