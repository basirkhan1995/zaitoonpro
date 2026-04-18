import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zform_dialog.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../../../../../Features/Generic/complex_textfield.dart';
import '../../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../../Features/Widgets/textfield_entitled.dart' hide ZTextFieldBorderType;
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../Finance/Ui/Currency/features/currency_drop.dart';

class AccountsAddEditView extends StatelessWidget {
  final AccountsModel? model;
  final int? perId;
  const AccountsAddEditView({super.key, this.model, this.perId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(model: model, perId: perId),
      tablet: _Desktop(model: model, perId: perId),
      desktop: _Desktop(model: model, perId: perId),
    );
  }
}

// Mobile Bottom Sheet Version
class _Mobile extends StatefulWidget {
  final AccountsModel? model;
  final int? perId;

  const _Mobile({this.model, this.perId});

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  // Controllers
  final TextEditingController accName = TextEditingController();
  final TextEditingController accountLimit = TextEditingController();

  bool status = true;
  int statusValue = 0;
  String defaultCcy = "USD";
  CurrenciesModel? ccyCode;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      accName.text = m.accName ?? "";
      accountLimit.text = m.accCreditLimit?.toAmount() ?? "";
      defaultCcy = m.actCurrency ?? "";
      statusValue = m.accStatus ?? 0;
      status = statusValue == 1;
    }
  }

  @override
  void dispose() {
    accName.dispose();
    accountLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context).colorScheme;
    final isEdit = widget.model != null;

    return Scaffold(
      body: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.outline.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        color: theme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? tr.update : tr.newKeyword,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: Form(
                    key: formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Account Name
                        ZTextFieldEntitled(
                          controller: accName,
                          isRequired: true,
                          title: tr.accountName,
                          onSubmit: (_) => onSubmit(),
                          validator: (value) {
                            if (value.isEmpty) {
                              return tr.required(tr.accountName);
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Currency Dropdown
                        CurrencyDropdown(
                          height: 45,
                          disableAction: widget.model != null,
                          title: tr.currencyTitle,
                          isMulti: false,
                          initiallySelectedSingle: CurrenciesModel(ccyCode: defaultCcy),
                          onMultiChanged: (_) {},
                          onSingleChanged: (value) {
                            setState(() {
                              ccyCode = value;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Account Limit
                        ZTextFieldEntitled(
                          onSubmit: (_) => onSubmit(),
                          keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormat: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                            SmartThousandsDecimalFormatter(),
                          ],
                          title: tr.accountLimit,
                          controller: accountLimit,
                        ),

                        const SizedBox(height: 12),

                        // Status Checkbox
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.surfaceContainerHighest.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                visualDensity: VisualDensity.compact,
                                value: status,
                                onChanged: (value) {
                                  setState(() {
                                    status = value ?? false;
                                    statusValue = status ? 1 : 0;
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status ? tr.active : tr.blocked,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: theme.outline.withValues(alpha: .2)),
                                ),
                                child: Text(tr.cancel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BlocBuilder<AccountsBloc, AccountsState>(
                                builder: (context, state) {
                                  return FilledButton(
                                    onPressed: state is AccountLoadingState ? null : onSubmit,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: theme.primary,
                                    ),
                                    child: state is AccountLoadingState
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Text(isEdit ? tr.update : tr.create),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = AccountsModel(
      accName: accName.text,
      actCurrency: ccyCode?.ccyCode ?? "USD",
      accStatus: statusValue,
      accCreditLimit: accountLimit.text.cleanAmount,
      actSignatory: widget.perId,
      accNumber: widget.model?.accNumber,
    );

    final bloc = context.read<AccountsBloc>();

    if (widget.model == null) {
      bloc.add(AddAccountEvent(data));
    } else {
      bloc.add(UpdateAccountEvent(data));
    }
  }
}

// Desktop Dialog Version
class _Desktop extends StatefulWidget {
  final AccountsModel? model;
  final int? perId;

  const _Desktop({this.model, this.perId});

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  // Controllers
  final TextEditingController accName = TextEditingController();
  final TextEditingController accountLimit = TextEditingController();

  bool status = true;
  int statusValue = 0;
  String defaultCcy = "USD";
  CurrenciesModel? ccyCode;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      accName.text = m.accName ?? "";
      accountLimit.text = m.accCreditLimit?.toAmount() ?? "";
      defaultCcy = m.actCurrency ?? "";
      statusValue = m.accStatus ?? 0;
      status = statusValue == 1;
    }
  }

  @override
  void dispose() {
    accName.dispose();
    accountLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context).colorScheme;
    final isEdit = widget.model != null;

    return ZFormDialog(
      icon: Icons.account_circle,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      width: 500,
      title: isEdit ? tr.update.toUpperCase() : tr.newKeyword,
      actionLabel:
      (context.watch<AccountsBloc>().state is AccountLoadingState)
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.surface,
        ),
      )
          : Text(isEdit ? tr.update : tr.create),
      onAction: onSubmit,
      child: Form(
        key: formKey,
        child: BlocConsumer<IndividualsBloc, IndividualsState>(
          listener: (context, state) {
            if (state is IndividualSuccessState) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                ZGenericTextField(
                  controller: accName,
                  title: tr.accountName,
                  hint: "e.g Ahmad",
                  defaultCurrencyCode: widget.model?.actCurrency,
                  fieldType: ZTextFieldType.currency,
                  onCurrencyChanged: (currency) {
                    ccyCode = currency;
                  },
                  showFlag: true,
                  showClearButton: true,
                  showSymbol: false,
                  isRequired: true,
                ),
                ZTextFieldEntitled(
                  onSubmit: (_) => onSubmit(),
                  keyboardInputType:
                  const TextInputType.numberWithOptions(decimal: true),
                  inputFormat: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                    SmartThousandsDecimalFormatter(),
                  ],

                  title: tr.accountLimit,
                  controller: accountLimit,
                ),

                Row(
                  children: [
                    Checkbox(
                      visualDensity: const VisualDensity(horizontal: -4),
                      value: status,
                      onChanged: (value) {
                        setState(() {
                          status = value ?? false;
                          statusValue = status ? 1 : 0;
                        });
                      },
                    ),
                    const SizedBox(width: 5),
                    Text(status ? tr.active : tr.blocked),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = AccountsModel(
      accName: accName.text,
      actCurrency: ccyCode?.ccyCode ?? "USD",
      accStatus: statusValue,
      accCreditLimit: accountLimit.text.cleanAmount,
      actSignatory: widget.perId,
      accNumber: widget.model?.accNumber,
    );

    final bloc = context.read<AccountsBloc>();

    if (widget.model == null) {
      bloc.add(AddAccountEvent(data));
    } else {
      bloc.add(UpdateAccountEvent(data));
    }
  }
}