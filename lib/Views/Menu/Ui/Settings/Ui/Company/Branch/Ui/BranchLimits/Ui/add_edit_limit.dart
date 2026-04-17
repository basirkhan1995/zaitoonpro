import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zform_dialog.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/Ui/BranchLimits/bloc/branch_limit_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/Ui/BranchLimits/model/limit_model.dart';
import '../../../../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';

class BranchLimitAddEditView extends StatelessWidget {
  final BranchLimitModel? branchLimit;
  final int? branchCode;

  const BranchLimitAddEditView({super.key, this.branchLimit, this.branchCode});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileBranchLimitAddEdit(model: branchLimit, branchCode: branchCode),
      tablet: _TabletBranchLimitAddEdit(model: branchLimit, branchCode: branchCode),
      desktop: _DesktopBranchLimitAddEdit(model: branchLimit, branchCode: branchCode),
    );
  }
}

// Base class to share common functionality
class _BaseBranchLimitAddEdit extends StatefulWidget {
  final BranchLimitModel? model;
  final int? branchCode;
  final bool isMobile;
  final bool isTablet;

  const _BaseBranchLimitAddEdit({
    required this.model,
    required this.branchCode,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseBranchLimitAddEdit> createState() => _BaseBranchLimitAddEditState();
}

class _BaseBranchLimitAddEditState extends State<_BaseBranchLimitAddEdit> {
  // Controllers
  final TextEditingController amountLimit = TextEditingController();
  String currencyCode = "";
  bool isUnlimited = false;
  String unlimitedAmount = "9999999999999";
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      amountLimit.text = m.balLimitAmount!.toAmount();
      currencyCode = m.balCurrency ?? "";
    }
  }

  @override
  void dispose() {
    amountLimit.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    // Clean formatted number
    final raw = amountLimit.text.replaceAll(RegExp(r'[^\d.]'), '');
    final parsedAmount = double.tryParse(raw) ?? 0;

    final data = BranchLimitModel(
      balBranch: widget.branchCode ?? widget.model?.balBranch,
      balCurrency: currencyCode,
      balLimitAmount: parsedAmount.toString(),
    );

    final bloc = context.read<BranchLimitBloc>();

    if (widget.model == null) {
      bloc.add(AddBranchLimitEvent(data));
    } else {
      bloc.add(EditBranchLimitEvent(data));
    }
  }

  // Build action button based on screen size and state
  Widget _buildActionButton(AppLocalizations locale, ColorScheme theme, bool isEdit) {
    if (widget.isMobile) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (context.watch<BranchLimitBloc>().state is BranchLimitLoadingState)
              ? null
              : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: theme.surface,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: (context.watch<BranchLimitBloc>().state is BranchLimitLoadingState)
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.surface,
            ),
          )
              : Text(
            isEdit ? locale.update : locale.create,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return (context.watch<BranchLimitBloc>().state is BranchLimitLoadingState)
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          color: theme.surface,
        ),
      )
          : Text(isEdit ? locale.update : locale.create);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.model != null;

    if (widget.isMobile) {
      // Mobile full-screen dialog
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          margin: EdgeInsets.zero,
          color: theme.surface,
          child: Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primary,
                      theme.primary.withValues(alpha: .8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? locale.update : locale.newKeyword,
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEdit ? locale.edit : locale.newKeyword,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: .8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: formKey,
                    child: BlocConsumer<BranchLimitBloc, BranchLimitState>(
                      listener: (context, state) {
                        if (state is BranchLimitSuccessState) {
                          Navigator.of(context).pop();
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Amount and Currency in vertical layout for mobile
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  ZTextFieldEntitled(
                                    isRequired: true,
                                    onSubmit: (_) => onSubmit(),
                                    keyboardInputType: TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormat: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,]*'),
                                      ),
                                      SmartThousandsDecimalFormatter(),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return locale.required(locale.amount);
                                      }
                                      return null;
                                    },
                                    controller: amountLimit,
                                    title: locale.amount,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: theme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.outline.withValues(alpha: .2),
                                      ),
                                    ),
                                    child: CurrencyDropdown(
                                      height: 50,
                                      initiallySelected: [],
                                      isMulti: false,
                                      onMultiChanged: (_) {},
                                      onSingleChanged: (value) {
                                        setState(() {
                                          currencyCode = value?.ccyCode ?? "";
                                        });
                                      },
                                      title: locale.currencyTitle,
                                      initiallySelectedSingle: CurrenciesModel(ccyCode: currencyCode),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Unlimited checkbox card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.outline.withValues(alpha: .2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isUnlimited,
                                    onChanged: (value) {
                                      setState(() {
                                        isUnlimited = value ?? false;
                                        amountLimit.text = isUnlimited ? unlimitedAmount : "";
                                      });
                                    },
                                    activeColor: theme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      locale.unlimited,
                                      style: textTheme.bodyLarge,
                                    ),
                                  ),
                                  if (isUnlimited)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        "∞",
                                        style: textTheme.titleMedium?.copyWith(
                                          color: theme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Action Button
                            _buildActionButton(locale, theme, isEdit),

                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (widget.isTablet) {
      // Tablet dialog
      return ZFormDialog(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        width: 550,
        title: isEdit ? locale.update : locale.newKeyword,
        actionLabel: _buildActionButton(locale, theme, isEdit),
        onAction: onSubmit,
        child: Form(
          key: formKey,
          child: BlocConsumer<BranchLimitBloc, BranchLimitState>(
            listener: (context, state) {
              if (state is BranchLimitSuccessState) {
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Amount and Currency in row for tablet
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          isRequired: true,
                          onSubmit: (_) => onSubmit(),
                          keyboardInputType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormat: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]*'),
                            ),
                            SmartThousandsDecimalFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return locale.required(locale.amount);
                            }
                            return null;
                          },
                          controller: amountLimit,
                          title: locale.amount,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.outline.withValues(alpha: .2),
                            ),
                          ),
                          child: CurrencyDropdown(
                            height: 45,
                            initiallySelected: [],
                            isMulti: false,
                            onMultiChanged: (_) {},
                            onSingleChanged: (value) {
                              setState(() {
                                currencyCode = value?.ccyCode ?? "";
                              });
                            },
                            title: locale.currencyTitle,
                            initiallySelectedSingle: CurrenciesModel(ccyCode: currencyCode),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Unlimited checkbox with better styling
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.outline.withValues(alpha: .2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isUnlimited,
                          onChanged: (value) {
                            setState(() {
                              isUnlimited = value ?? false;
                              amountLimit.text = isUnlimited ? unlimitedAmount : "";
                            });
                          },
                          activeColor: theme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locale.unlimited,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                        if (isUnlimited)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              "∞",
                              style: textTheme.titleMedium?.copyWith(
                                color: theme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ),
      );
    } else {
      // Desktop dialog (existing)
      return ZFormDialog(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        width: 550,
        title: isEdit ? locale.update : locale.newKeyword,
        actionLabel: _buildActionButton(locale, theme, isEdit),
        onAction: onSubmit,
        child: Form(
          key: formKey,
          child: BlocConsumer<BranchLimitBloc, BranchLimitState>(
            listener: (context, state) {
              if (state is BranchLimitSuccessState) {
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    spacing: 5,
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          isRequired: true,
                          onSubmit: (_) => onSubmit(),
                          keyboardInputType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormat: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]*'),
                            ),
                            SmartThousandsDecimalFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return locale.required(locale.amount);
                            }
                            return null;
                          },
                          controller: amountLimit,
                          title: locale.amount,
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: CurrencyDropdown(
                          height: 40,
                          initiallySelected: [],
                          isMulti: false,
                          onMultiChanged: (_) {},
                          onSingleChanged: (value) {
                            setState(() {
                              currencyCode = value?.ccyCode ?? "";
                            });
                          },
                          title: locale.currencyTitle,
                          initiallySelectedSingle: CurrenciesModel(ccyCode: currencyCode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      CheckboxMenuButton(
                        value: isUnlimited,
                        onChanged: (_) {
                          setState(() {
                            isUnlimited = !isUnlimited;
                            amountLimit.text = isUnlimited ? unlimitedAmount : "";
                          });
                        },
                        style: ButtonStyle(
                          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 5)),
                          backgroundColor: WidgetStatePropertyAll(theme.surface),
                          overlayColor: WidgetStatePropertyAll(theme.primary.withValues(alpha: .05)),
                        ),
                        child: Text(locale.unlimited),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ),
      );
    }
  }
}

// Mobile View
class _MobileBranchLimitAddEdit extends StatelessWidget {
  final BranchLimitModel? model;
  final int? branchCode;

  const _MobileBranchLimitAddEdit({this.model, this.branchCode});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchLimitAddEdit(
      model: model,
      branchCode: branchCode,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletBranchLimitAddEdit extends StatelessWidget {
  final BranchLimitModel? model;
  final int? branchCode;

  const _TabletBranchLimitAddEdit({this.model, this.branchCode});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchLimitAddEdit(
      model: model,
      branchCode: branchCode,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopBranchLimitAddEdit extends StatelessWidget {
  final BranchLimitModel? model;
  final int? branchCode;

  const _DesktopBranchLimitAddEdit({this.model, this.branchCode});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchLimitAddEdit(
      model: model,
      branchCode: branchCode,
      isMobile: false,
      isTablet: false,
    );
  }
}