import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import '../../../../../../../Features/Other/zForm_dialog.dart';
import '../bloc/txn_ref_report_bloc.dart';
import '../txn_ref_auto.dart';

class TransactionDialogHelper {
  static void showTransactionReferenceDialog({
    required BuildContext context,
    required String reference,
    bool autoLoad = true,
  }) {
    // Create a new bloc instance for the dialog
    final bloc = TxnRefReportBloc(context.read<Repositories>());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: ZFormDialog(
            title: AppLocalizations.of(context)!.transactionByRef,
            isActionTrue: false, // This hides the action buttons
            backgroundColor: Theme.of(context).colorScheme.surface,
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.zero,
            onAction: null,
            child: TransactionReferenceDialog(
              reference: reference,
              autoLoad: autoLoad,
            ),
          ),
        );
      },
    ).then((_) {
      // Clean up the bloc when dialog is closed
      bloc.close();
    });
  }
}