import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/zForm_dialog.dart';
import 'package:zaitoon_petroleum/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/TxnTypes/bloc/txn_types_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/TxnTypes/model/txn_types_model.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';

class AddEditTxnTypesView extends StatelessWidget {
  final TxnTypeModel? model;
  const AddEditTxnTypesView({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Desktop(model),
      tablet: _Desktop(model),
      desktop: _Desktop(model),
    );
  }
}


class _Desktop extends StatefulWidget {
  final TxnTypeModel? model;
  const _Desktop(this.model);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final formKey = GlobalKey<FormState>();
  final trnCode = TextEditingController();
  final trnName = TextEditingController();
  final trnDetails = TextEditingController();

  String? usrName;

  @override
  void initState() {
    if (widget.model != null) {
      trnCode.text = widget.model?.trntCode ?? "";
      trnName.text = widget.model?.trntName ?? "";
      trnDetails.text = widget.model?.trntDetails??"";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    final color = Theme.of(context).colorScheme;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    usrName = login.usrName ?? "";
    bool isEdit = widget.model != null;

    return BlocBuilder<TxnTypesBloc, TxnTypesState>(
  builder: (context, txnState) {
    return ZFormDialog(
      onAction: onSubmit,
      padding: EdgeInsets.symmetric(vertical: 15,horizontal: 15),
      actionLabel: txnState is TxnTypeLoadingState? SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          color: color.surface,
          strokeWidth: 2,
        ),
      ) : Text(isEdit? tr.update : tr.create),
      title: isEdit? tr.edit : tr.newKeyword,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ZTextFieldEntitled(
              title: tr.txnType,
              controller: trnName,
              isRequired: true,
              validator: (value) {
                if (value.isEmpty) {
                  return tr.required(tr.txnType);
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            ZTextFieldEntitled(
              title: "Code",
              controller: trnCode,
              isRequired: true,
              validator: (value) {
                if (value.isEmpty) {
                  return tr.required("code");
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            ZTextFieldEntitled(
              title: tr.details,
              controller: trnDetails,
              keyboardInputType: TextInputType.multiline,
              isRequired: true,
              validator: (value) {
                if (value.isEmpty) {
                  return tr.required(tr.details);
                }
                return null;
              },
            ),

            if(state is TxnTypeErrorState)
              SizedBox(height: 15),
            if(txnState is TxnTypeErrorState)
              Row(
                children: [
                  Text(txnState.message, style: TextStyle(color: Theme.of(context).colorScheme.error),)
                ],
              ),
          ],
        )
      ),
    );
  },
);
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
    final bloc = context.read<TxnTypesBloc>();

    final data = TxnTypeModel(
      trntCode: trnCode.text,
      trntName: trnName.text,
      trntDetails: trnDetails.text,
    );
    if (widget.model != null) {
      bloc.add(UpdateTxnTypeEvent(data));
    } else {
      bloc.add(AddTxnTypeEvent(data));
    }

  }
}
