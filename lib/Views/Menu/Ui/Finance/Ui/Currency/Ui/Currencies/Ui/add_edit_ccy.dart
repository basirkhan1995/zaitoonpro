import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/desktop_form_nav.dart';
import '../../../../../../../../../Features/Other/utils.dart';
import '../../../../../../../../../Features/Other/zform_dialog.dart';
import '../../../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../bloc/currencies_bloc.dart';
import '../model/ccy_model.dart';

class AddEditCurrencyView extends StatefulWidget {
  final CurrenciesModel? currency;
  const AddEditCurrencyView({super.key, this.currency});
  @override
  State<AddEditCurrencyView> createState() => _AddEditCurrencyViewState();
}

class _AddEditCurrencyViewState extends State<AddEditCurrencyView> {
  final TextEditingController ccyCode = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController ccySymbol = TextEditingController();
  final TextEditingController ccyLocalName = TextEditingController();
  final TextEditingController ccyCountryCode = TextEditingController();
  final TextEditingController ccyName = TextEditingController();

  final formKey = GlobalKey<FormState>();
  bool _hasChanges = false;
  Map<String, String> _originalValues = {};

  @override
  void initState() {
    super.initState();
    if (widget.currency != null) {
      ccyCode.text = widget.currency!.ccyCode ?? '';
      ccySymbol.text = widget.currency!.ccySymbol ?? '';
      ccyLocalName.text = widget.currency!.ccyLocalName ?? '';
      country.text = widget.currency?.ccyCountry ??'';
      ccyCountryCode.text = widget.currency!.ccyCountryCode ?? '';
      ccyName.text = widget.currency!.ccyName ?? '';

      // Store original values for comparison
      _originalValues = {
        'ccyCode': widget.currency?.ccyCode ?? '',
        'ccySymbol': widget.currency?.ccySymbol ?? '',
        'ccyLocalName': widget.currency?.ccyLocalName ?? '',
        'ccyCountry': widget.currency?.ccyCountry ?? '',
        'ccyCountryCode': widget.currency?.ccyCountryCode ?? '',
        'ccyName': widget.currency?.ccyName ?? '',
      };
    }

    // Listen to all text fields for changes
    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    void checkForChanges() {
      final currentValues = {
        'ccyCode': ccyCode.text,
        'ccySymbol': ccySymbol.text,
        'ccyLocalName': ccyLocalName.text,
        'ccyCountry': country.text,
        'countryCode': ccyCountryCode.text,
        'ccyName': ccyName.text,
      };

      final hasChanges = currentValues.entries.any(
            (entry) => entry.value != _originalValues[entry.key],
      );

      if (hasChanges != _hasChanges) {
        setState(() {
          _hasChanges = hasChanges;
        });
      }
    }

    ccyCode.addListener(checkForChanges);
    ccySymbol.addListener(checkForChanges);
    ccyLocalName.addListener(checkForChanges);
    ccyCountryCode.addListener(checkForChanges);
    ccyName.addListener(checkForChanges);
  }

  @override
  void dispose() {
    ccyCode.dispose();
    ccySymbol.dispose();
    ccyLocalName.dispose();
    ccyCountryCode.dispose();
    ccyName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isUpdate = widget.currency != null;

    return BlocListener<CurrenciesBloc, CurrenciesState>(
      listener: (context, state) {
        if (state is CurrenciesErrorState) {
          // Handle "no changes" case specifically
          if (state.message.contains('No changes detected')) {
            // Option 1: Show info message instead of error
            Utils.showOverlayMessage(
              context,
              message: 'No changes made to save',
              isError: false, // Use false to show as info instead of error
            );
          } else {
            Utils.showOverlayMessage(context, message: state.message, isError: true);
          }
        } else if (state is CurrenciesSuccessState) {
          // Success case - close dialog
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<CurrenciesBloc, CurrenciesState>(
        builder: (context, state) {
          final isLoading = state is CurrenciesLoadingState;

          return ZFormDialog(
            width: 450,
            isButtonEnabled: _hasChanges ? true : false,
            onAction: _hasChanges || !isUpdate ? () => onSubmit(isUpdate) : null,
            title: isUpdate ? locale.update : locale.newKeyword,
            actionLabel: isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.surface,
              ),
            )
                : Text(isUpdate ? locale.update : locale.create),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: AbsorbPointer(
              absorbing: isLoading,
              child: Opacity(
                opacity: isLoading ? 0.5 : 1,
                child: FormNavigation(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: [
                        ZTextFieldEntitled(
                          title: locale.ccyName,
                          controller: ccyName,
                          isRequired: true,
                          onSubmit: (_) => onSubmit(isUpdate),
                          validator: (value) => value.isEmpty
                              ? locale.required(locale.ccyName)
                              : null,
                        ),
                        Row(
                          spacing: 5,
                          children: [
                            Expanded(
                              child: ZTextFieldEntitled(
                                title: locale.currencyCode,
                                controller: ccyCode,
                                isRequired: true,
                                onSubmit: (_) => onSubmit(isUpdate),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return locale.required(locale.currencyCode);
                                  }
                                  if (value.length > 4) {
                                    return "${locale.currencyCode} not allowed more than 4.";
                                  }
                                  return null;
                                },
                                inputFormat: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ZTextFieldEntitled(
                                title: locale.ccySymbol,
                                controller: ccySymbol,
                                isRequired: true,
                                onSubmit: (_) => onSubmit(isUpdate),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return locale.required(locale.ccySymbol);
                                  }
                                  if (value.length > 3) {
                                    return "${locale.ccySymbol} not allowed more than 3.";
                                  }
                                  return null;
                                },
                                inputFormat: [
                                  LengthLimitingTextInputFormatter(3),
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ZTextFieldEntitled(
                                title: locale.countryCode,
                                controller: ccyCountryCode,
                                isRequired: true,
                                onSubmit: (_) => onSubmit(isUpdate),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return locale.required(locale.countryCode);
                                  }
                                  if (value.length > 4) {
                                    return "${locale.countryCode} not allowed more than 4.";
                                  }
                                  return null;
                                },
                                inputFormat: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ZTextFieldEntitled(
                          title: locale.country,
                          controller: country,
                          isRequired: true,
                          onSubmit: (_) => onSubmit(isUpdate),
                          validator: (value) => value.isEmpty
                              ? locale.required(locale.country)
                              : null,
                        ),
                        ZTextFieldEntitled(
                          title: locale.ccyLocalName,
                          controller: ccyLocalName,
                          isRequired: true,
                          onSubmit: (_) => onSubmit(isUpdate),
                          validator: (value) => value.isEmpty
                              ? locale.required(locale.ccyLocalName)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void onSubmit(bool isUpdate) {
    if (formKey.currentState!.validate() && (_hasChanges || !isUpdate)) {
      final model = CurrenciesModel(
        ccyCode: ccyCode.text,
        ccyCountry: ccyCountryCode.text,
        ccyLocalName: ccyLocalName.text,
        ccyName: ccyName.text,
        ccySymbol: ccySymbol.text,
      );

      final bloc = context.read<CurrenciesBloc>();
      if (isUpdate) {
        bloc.add(UpdateCcyEvent(ccy: model));
      } else {
        bloc.add(AddCcyEvent(ccy: model));
      }
    }
  }
}