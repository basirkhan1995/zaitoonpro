import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/alert_dialog.dart';
import 'package:zaitoon_petroleum/Features/Other/cover.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/thousand_separator.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Other/zForm_dialog.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Features/Widgets/txn_status_widget.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/ProjectTxn/bloc/project_txn_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/ProjectTxn/model/project_txn_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/bloc/transactions_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/model/transaction_model.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'Print/print.dart';

class ProjectTxnView extends StatelessWidget {
  final String? reference;
  const ProjectTxnView({super.key, this.reference});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(reference),
      tablet: _Desktop(reference),
      desktop: _Desktop(reference),
    );
  }
}

class _Mobile extends StatelessWidget {
  final String? reference;
  const _Mobile(this.reference);

  @override
  Widget build(BuildContext context) {
    return _MobileProjectTxnView(reference: reference);
  }
}

class _MobileProjectTxnView extends StatefulWidget {
  final String? reference;
  const _MobileProjectTxnView({this.reference});

  @override
  State<_MobileProjectTxnView> createState() => _MobileProjectTxnViewState();
}

class _MobileProjectTxnViewState extends State<_MobileProjectTxnView> {
  final TextEditingController narration = TextEditingController();
  final TextEditingController amount = TextEditingController();
  ProjectTxnModel? loadedTxn;
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
        title: Text(locale.projectTxnDetails),
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
          return BlocConsumer<ProjectTxnBloc, ProjectTxnState>(
            listener: (context, state) {
              if (state is ProjectTxnErrorState) {
                Utils.showOverlayMessage(context, message: state.message, isError: true);
              }
            },
            builder: (context, state) {
              if (state is ProjectTxnLoadedState) {
                loadedTxn = state.txn;
                narration.text = state.txn.transaction?.narration ?? "";
                reference = state.txn.transaction?.trnReference ?? "";
                amount.text = state.txn.transaction?.amount?.toAmount() ?? "";

                final bool isAlreadyReversed = state.txn.transaction?.trnStateText == "Reversed";
                final bool isAlreadyDeleted = state.txn.transaction?.trnStateText == "Deleted";

                final bool showAuthorizeButton = state.txn.transaction?.trnStatus == 0 &&
                    login.usrName != state.txn.transaction?.maker;
                final bool showReverseButton = state.txn.transaction?.trnStatus == 1 &&
                    state.txn.transaction?.maker == login.usrName;
                final bool showUpdateButton = state.txn.transaction?.trnStatus == 0 &&
                    state.txn.transaction?.maker == login.usrName;
                final bool showDeleteButton = state.txn.transaction?.trnStatus == 0 &&
                    state.txn.transaction?.maker == login.usrName;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Header
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
                              state.txn.prjName ?? "",
                              style: textTheme.titleLarge?.copyWith(
                                color: color.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${locale.projectId}: ${state.txn.prjId}",
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${state.txn.transaction?.amount?.toAmount()} ${state.txn.transaction?.currency}",
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Project Details Card
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
                                  locale.projectDetails,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TransactionStatusBadge(status: state.txn.transaction?.trnStateText ?? ""),
                              ],
                            ),
                            const Divider(height: 16),

                            // Project Details
                            _buildDetailRow(locale.customerName, state.txn.customerName ?? "", context),
                            _buildDetailRow(locale.location, state.txn.prjLocation ?? "", context),
                            _buildDetailRow(locale.projectDetails, state.txn.prjDetails ?? "", context),
                            _buildDetailRow(locale.deadline, state.txn.prjDateLine?.toFormattedDate() ?? "", context),
                            _buildDetailRow(locale.paymentType, state.txn.prpType ?? "", context),

                            const SizedBox(height: 12),
                            Text(
                              locale.transactionDetails,
                              style: textTheme.titleSmall?.copyWith(
                                color: color.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 8),

                            // Transaction Details
                            _buildDetailRow(locale.referenceNumber, state.txn.transaction?.trnReference ?? "", context),
                            _buildDetailRow(locale.maker, state.txn.transaction?.maker ?? "", context),
                            _buildDetailRow(locale.checker, state.txn.transaction?.checker ?? "", context),
                            _buildDetailRow(locale.debitAccount, state.txn.transaction?.debitAccount.toString() ?? "", context),
                            _buildDetailRow(locale.creditAccount, state.txn.transaction?.creditAccount.toString() ?? "", context),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Editable Fields Card
                      if (showUpdateButton)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color.outline.withValues(alpha: 0.1)),
                              ),
                              child: Column(
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
                                        return locale.required(locale.amount);
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
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),

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
                                      _showAuthorizeConfirmation(
                                        context,
                                        onConfirm: () {
                                          context.read<TransactionsBloc>().add(
                                            AuthorizeTxnEvent(
                                              reference: reference ?? "",
                                              usrName: login.usrName ?? "",
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    icon: Icons.check_circle_outline,
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
                                      _showReverseConfirmation(
                                        context,
                                        onConfirm: () {
                                          context.read<TransactionsBloc>().add(
                                            ReverseTxnEvent(
                                              reference: reference ?? "",
                                              usrName: login.usrName ?? "",
                                            ),
                                          );
                                        },
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
                                      _showUpdateConfirmation(
                                        context,
                                        onConfirm: () {
                                          context.read<TransactionsBloc>().add(
                                            UpdatePendingTransactionEvent(
                                              TransactionsModel(
                                                trnReference: loadedTxn?.transaction?.trnReference ?? "",
                                                usrName: login.usrName,
                                                trdCcy: loadedTxn?.transaction?.currency ?? "",
                                                trdNarration: narration.text,
                                                trdAmount: amount.text.cleanAmount,
                                              ),
                                            ),
                                          );
                                        },
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
                                              reference: loadedTxn?.transaction?.trnReference ?? "",
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
              if (state is ProjectTxnLoadingState) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Center(
                child: Text(locale.noDataFound),
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

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: locale.areYouSure,
        content: "Do you wanna delete this transaction?",
        onYes: onConfirm,
      ),
    );
  }

  void _showAuthorizeConfirmation(BuildContext context, {required VoidCallback onConfirm}) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: locale.areYouSure,
        content: "Do you wanna authorize this transaction?",
        onYes: onConfirm,
      ),
    );
  }

  void _showReverseConfirmation(BuildContext context, {required VoidCallback onConfirm}) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: locale.areYouSure,
        content: "Do you wanna reverse this transaction?",
        onYes: onConfirm,
      ),
    );
  }

  void _showUpdateConfirmation(BuildContext context, {required VoidCallback onConfirm}) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: locale.areYouSure,
        content: "Do you wanna update this transaction?",
        onYes: onConfirm,
      ),
    );
  }

  void _getPrint({required ProjectTxnModel data, required ReportModel company}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: PrintPreviewDialog<ProjectTxnModel>(
            data: data,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return ProjectTxnPrintSettings().printPreview(
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
              return ProjectTxnPrintSettings().printDocument(
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
              return ProjectTxnPrintSettings().createDocument(
                data: data,
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  final String? reference;
  const _Desktop(this.reference);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final TextEditingController narration = TextEditingController();
  final TextEditingController amount = TextEditingController();
  ProjectTxnModel? loadedTxn;
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
          width: 650,
          isActionTrue: false,
          icon: Icons.assignment,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          onAction: null,
          title: locale.projectTxnDetails,
          child: BlocConsumer<ProjectTxnBloc, ProjectTxnState>(
            listener: (context, state) {
              if (state is ProjectTxnErrorState) {
                Utils.showOverlayMessage(context, message: state.message, isError: true);
              }
            },
            builder: (context, state) {
              if (state is ProjectTxnLoadedState) {
                loadedTxn = state.txn;
                narration.text = state.txn.transaction?.narration ?? "";
                reference = state.txn.transaction?.trnReference ?? "";
                amount.text = state.txn.transaction?.amount?.toAmount() ?? "";

                final bool isAlreadyReversed = state.txn.transaction?.trnStateText == "Reversed";
                final bool isAlreadyDeleted = state.txn.transaction?.trnStateText == "Deleted";

                final bool showAuthorizeButton = state.txn.transaction?.trnStatus == 0 &&
                    login.usrName != state.txn.transaction?.maker;
                final bool showReverseButton = state.txn.transaction?.trnStatus == 1 &&
                    state.txn.transaction?.maker == login.usrName;
                final bool showUpdateButton = state.txn.transaction?.trnStatus == 0 &&
                    state.txn.transaction?.maker == login.usrName;
                final bool showDeleteButton = state.txn.transaction?.trnStatus == 0 &&
                    state.txn.transaction?.maker == login.usrName;

                final bool showAnyButton = showAuthorizeButton || showReverseButton ||
                    showUpdateButton || showDeleteButton;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with Print
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.txn.prjName ?? "",
                                    style: textTheme.titleLarge?.copyWith(
                                      color: color.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${locale.projectId}: ${state.txn.prjId}",
                                    style: textTheme.bodyMedium?.copyWith(color: color.outline),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.print, color: color.primary),
                              onPressed: () => _getPrint(data: state.txn, company: company),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Amount Display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${state.txn.transaction?.amount?.toAmount()} ${state.txn.transaction?.currency}",
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           // Project Details Section
                           ZCover(
                             padding: const EdgeInsets.all(16),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 // Title for Project Details
                                 Text(
                                   locale.projectDetails,
                                   style: textTheme.titleMedium?.copyWith(
                                     color: color.primary,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 const SizedBox(height: 5),

                                 // Project Details Content
                                 _buildDetailColumn(
                                   [
                                     _DetailItem(locale.customerName, state.txn.customerName ?? ""),
                                     _DetailItem(locale.deadline, state.txn.prjDateLine?.toFormattedDate() ?? ""),
                                     _DetailItem(locale.txnType, state.txn.prpType ?? ""),
                                     _DetailItem(locale.location, state.txn.prjLocation ?? ""),
                                     _DetailItem(locale.projectDetails, state.txn.prjDetails ?? ""),
                                   ],
                                   context,
                                 ),
                               ],
                             ),
                           ),

                           const SizedBox(height: 5),

                          // Transaction Details Section
                           ZCover(
                             padding: const EdgeInsets.all(16),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 // Title for Transaction Details
                                 Text(
                                   locale.transactionDetails,
                                   style: textTheme.titleMedium?.copyWith(
                                     color: color.primary,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 const Divider(height: 16),
                                 const SizedBox(height: 5),

                                 // Transaction Details Content
                                 _buildDetailColumn(
                                   [
                                     _DetailItem(locale.referenceNumber, state.txn.transaction?.trnReference ?? ""),
                                     _DetailItem(locale.maker, state.txn.transaction?.maker ?? ""),
                                     _DetailItem(locale.checker, state.txn.transaction?.checker ?? ""),
                                     _DetailItem(locale.debitAccount, state.txn.transaction?.debitAccount.toString() ?? ""),
                                     _DetailItem(locale.creditAccount, state.txn.transaction?.creditAccount.toString() ?? ""),
                                     _DetailItem(locale.status, "", isStatus: true, status: state.txn.transaction?.trnStateText ?? ""),
                                   ],
                                   context,
                                 ),
                               ],
                             ),
                           ),
                         ],
                       ),

                        const SizedBox(height: 20),

                        // Editable Fields
                        if (showUpdateButton)
                          Column(
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
                                    return locale.required(locale.amount);
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

                        if (showAnyButton) const SizedBox(height: 20),

                        // Action Buttons
                        if (showAnyButton)
                          Row(
                            spacing: 8,
                            children: [
                              if (showAuthorizeButton && !isAlreadyDeleted)
                                ZOutlineButton(
                                  isActive: true,
                                  onPressed: isAuthorizeLoading ? null : () {
                                    _showAuthorizeConfirmation(
                                      context,
                                      onConfirm: () {
                                        context.read<TransactionsBloc>().add(
                                          AuthorizeTxnEvent(
                                            reference: reference ?? "",
                                            usrName: login.usrName ?? "",
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  icon: Icons.check_circle_outline,
                                  label: isAuthorizeLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : Text(locale.authorize),
                                ),

                              if (showReverseButton && !isAlreadyReversed)
                                ZOutlineButton(
                                  isActive: true,
                                  onPressed: isReverseLoading ? null : () {
                                    _showReverseConfirmation(
                                      context,
                                      onConfirm: () {
                                        context.read<TransactionsBloc>().add(
                                          ReverseTxnEvent(
                                            reference: reference ?? "",
                                            usrName: login.usrName ?? "",
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  icon: Icons.screen_rotation_alt,
                                  backgroundHover: Colors.orange,
                                  label: isReverseLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : Text(locale.reverseTitle),
                                ),

                              if (showUpdateButton && !isAlreadyDeleted)
                                ZOutlineButton(
                                  backgroundHover: Colors.green,
                                  isActive: true,
                                  icon: isUpdateLoading ? null : Icons.refresh,
                                  onPressed: isUpdateLoading ? null : () {
                                    _showUpdateConfirmation(
                                      context,
                                      onConfirm: () {
                                        context.read<TransactionsBloc>().add(
                                          UpdatePendingTransactionEvent(
                                            TransactionsModel(
                                              trnReference: loadedTxn?.transaction?.trnReference ?? "",
                                              usrName: login.usrName,
                                              trdCcy: loadedTxn?.transaction?.currency ?? "",
                                              trdNarration: narration.text,
                                              trdAmount: amount.text.cleanAmount,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  label: isUpdateLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : Text(locale.update),
                                ),

                              if (showDeleteButton && !isAlreadyDeleted)
                                ZOutlineButton(
                                  icon: isDeleteLoading ? null : Icons.delete_outline_rounded,
                                  isActive: true,
                                  backgroundHover: Theme.of(context).colorScheme.error,
                                  onPressed: isDeleteLoading ? null : () {
                                    _showDeleteConfirmation(
                                      context,
                                      onConfirm: () {
                                        context.read<TransactionsBloc>().add(
                                          DeletePendingTxnEvent(
                                            reference: loadedTxn?.transaction?.trnReference ?? "",
                                            usrName: login.usrName ?? "",
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  label: isDeleteLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : Text(locale.delete),
                                ),
                            ],
                          ),

                      ],
                    ),
                  ),
                );
              }
              if (state is ProjectTxnLoadingState) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(locale.noDataFound),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailColumn(List<_DetailItem> items, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  "${item.label}:",
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: item.isStatus
                    ? TransactionStatusBadge(status: item.status)
                    : Text(
                  item.value,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, {required VoidCallback onConfirm}) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: locale.areYouSure,
        content: "Do you wanna delete this transaction?",
        onYes: onConfirm,
      ),
    );
  }

  void _showAuthorizeConfirmation(BuildContext context, {required VoidCallback onConfirm}) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: locale.areYouSure,
        content: "Do you wanna Authorize this transaction?",
        onYes: onConfirm,
      ),
    );
  }

  void _showReverseConfirmation(BuildContext context, {required VoidCallback onConfirm}) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: locale.areYouSure,
        content: "Do you wanna reverse this transaction?",
        onYes: onConfirm,
      ),
    );
  }

  void _showUpdateConfirmation(BuildContext context, {required VoidCallback onConfirm}) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: locale.areYouSure,
        content: "Do you wanna update this transaction?",
        onYes: onConfirm,
      ),
    );
  }

  void _getPrint({required ProjectTxnModel data, required ReportModel company}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => PrintPreviewDialog<ProjectTxnModel>(
          data: data,
          company: company,
          buildPreview: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return ProjectTxnPrintSettings().printPreview(
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
            return ProjectTxnPrintSettings().printDocument(
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
            return ProjectTxnPrintSettings().createDocument(
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

class _DetailItem {
  final String label;
  final String value;
  final bool isStatus;
  final String status;

  _DetailItem(this.label, this.value, {this.isStatus = false, this.status = ""});
}