import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zform_dialog.dart';
import 'package:flutter/services.dart';
import '../../../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../bloc/branch_bloc.dart';
import '../model/branch_model.dart';

class BranchAddEditView extends StatelessWidget {
  final BranchModel? selectedBranch;

  const BranchAddEditView({super.key, this.selectedBranch});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileBranchAddEdit(model: selectedBranch),
      tablet: _TabletBranchAddEdit(model: selectedBranch),
      desktop: _DesktopBranchAddEdit(model: selectedBranch),
    );
  }
}

// Base class to share common functionality
class _BaseBranchAddEdit extends StatefulWidget {
  final BranchModel? model;
  final bool isMobile;
  final bool isTablet;

  const _BaseBranchAddEdit({
    required this.model,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseBranchAddEdit> createState() => _BaseBranchAddEditState();
}

class _BaseBranchAddEditState extends State<_BaseBranchAddEdit> {
  // Controllers
  final TextEditingController branchName = TextEditingController();
  final TextEditingController branchCode = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController province = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController nationalId = TextEditingController();
  final TextEditingController zipCode = TextEditingController();

  int mailingValue = 1;
  bool isMailingAddress = true;

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      branchName.text = m.brcName ?? "";
      branchCode.text = m.brcId.toString();
      city.text = m.addCity ?? "";
      province.text = m.addProvince ?? "";
      country.text = m.addCountry ?? "";
      zipCode.text = m.addZipCode?.toString() ?? "";
      address.text = m.addName ?? "";
      phone.text = m.brcPhone ?? "";
      mailingValue = m.addMailing ?? 1;
      isMailingAddress = mailingValue == 1;
    }
  }

  @override
  void dispose() {
    country.dispose();
    city.dispose();
    zipCode.dispose();
    address.dispose();
    nationalId.dispose();
    province.dispose();
    branchName.dispose();
    branchCode.dispose();
    phone.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = BranchModel(
      brcId: widget.model?.brcId,
      brcName: branchName.text,
      addName: address.text,
      brcPhone: phone.text,
      addMailing: mailingValue,
      addZipCode: zipCode.text,
      addProvince: province.text,
      addCountry: country.text,
      addId: widget.model?.addId,
      addCity: city.text,
    );

    final bloc = context.read<BranchBloc>();

    if (widget.model == null) {
      bloc.add(AddBranchEvent(data));
    } else {
      bloc.add(EditBranchEvent(data));
    }
  }

  // Build action button based on screen size and state
  Widget _buildActionButton(AppLocalizations locale, ColorScheme theme, bool isEdit) {
    if (widget.isMobile) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (context.watch<BranchBloc>().state is BranchLoadingState)
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
          child: (context.watch<BranchBloc>().state is BranchLoadingState)
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
      return (context.watch<BranchBloc>().state is BranchLoadingState)
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 3,
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
      // Mobile Dialog - Full screen without Scaffold
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          margin: EdgeInsets.zero,
          color: theme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.max,
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
                    child: BlocConsumer<BranchBloc, BranchState>(
                      listener: (context, state) {
                        if (state is BranchSuccessState) {
                          Navigator.of(context).pop();
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Branch Name Field
                            Container(
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
                              child: ZTextFieldEntitled(
                                controller: branchName,
                                isRequired: true,
                                title: locale.branchName,
                                onSubmit: (_) => onSubmit(),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return locale.required(locale.branchName);
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Phone and Zip Code Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
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
                                    child: ZTextFieldEntitled(
                                      controller: phone,
                                      title: locale.mobile1,
                                      inputFormat: [FilteringTextInputFormatter.digitsOnly],
                                      onSubmit: (_) => onSubmit(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Container(
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
                                    child: ZTextFieldEntitled(
                                      controller: zipCode,
                                      title: locale.zipCode,
                                      inputFormat: [FilteringTextInputFormatter.digitsOnly],
                                      onSubmit: (_) => onSubmit(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // City, Province, Country
                            Column(
                              children: [
                                Container(
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
                                  child: ZTextFieldEntitled(
                                    controller: city,
                                    title: locale.city,
                                    onSubmit: (_) => onSubmit(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
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
                                  child: ZTextFieldEntitled(
                                    controller: province,
                                    title: locale.province,
                                    onSubmit: (_) => onSubmit(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
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
                                  child: ZTextFieldEntitled(
                                    controller: country,
                                    title: locale.country,
                                    onSubmit: (_) => onSubmit(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Address Field
                            Container(
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
                              child: ZTextFieldEntitled(
                                controller: address,
                                keyboardInputType: TextInputType.multiline,
                                maxLength: 100,
                                title: locale.address,
                                onSubmit: (_) => onSubmit(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Mailing Address Checkbox
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
                                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                    value: isMailingAddress,
                                    onChanged: (value) {
                                      setState(() {
                                        isMailingAddress = value ?? true;
                                        mailingValue = isMailingAddress ? 1 : 0;
                                      });
                                    },
                                    activeColor: theme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      locale.isMilling,
                                      style: textTheme.bodyLarge,
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
        width: 600,
        title: isEdit ? locale.update : locale.newKeyword,
        actionLabel: _buildActionButton(locale, theme, isEdit),
        onAction: onSubmit,
        child: Form(
          key: formKey,
          child: BlocConsumer<BranchBloc, BranchState>(
            listener: (context, state) {
              if (state is BranchSuccessState) {
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ZTextFieldEntitled(
                      controller: branchName,
                      isRequired: true,
                      title: locale.branchName,
                      onSubmit: (_) => onSubmit(),
                      validator: (value) {
                        if (value.isEmpty) {
                          return locale.required(locale.branchName);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ZTextFieldEntitled(
                            controller: phone,
                            title: locale.mobile1,
                            inputFormat: [FilteringTextInputFormatter.digitsOnly],
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: ZTextFieldEntitled(
                            controller: zipCode,
                            title: locale.zipCode,
                            inputFormat: [FilteringTextInputFormatter.digitsOnly],
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: city,
                            title: locale.city,
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: province,
                            title: locale.province,
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: country,
                            title: locale.country,
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ZTextFieldEntitled(
                      controller: address,
                      keyboardInputType: TextInputType.multiline,
                      maxLength: 100,
                      title: locale.address,
                      onSubmit: (_) => onSubmit(),
                    ),
                    const SizedBox(height: 16),

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
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            value: isMailingAddress,
                            onChanged: (value) {
                              setState(() {
                                isMailingAddress = value ?? true;
                                mailingValue = isMailingAddress ? 1 : 0;
                              });
                            },
                            activeColor: theme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            locale.isMilling,
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Desktop dialog
      return ZFormDialog(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        width: 550,
        title: isEdit ? locale.update : locale.newKeyword,
        actionLabel: _buildActionButton(locale, theme, isEdit),
        onAction: onSubmit,
        child: Form(
          key: formKey,
          child: BlocConsumer<BranchBloc, BranchState>(
            listener: (context, state) {
              if (state is BranchSuccessState) {
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ZTextFieldEntitled(
                    controller: branchName,
                    isRequired: true,
                    title: locale.branchName,
                    onSubmit: (_) => onSubmit(),
                    validator: (value) {
                      if (value.isEmpty) {
                        return locale.required(locale.branchName);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  Row(
                    spacing: 5,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ZTextFieldEntitled(
                          controller: phone,
                          title: locale.mobile1,
                          inputFormat: [FilteringTextInputFormatter.digitsOnly],
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ZTextFieldEntitled(
                          controller: zipCode,
                          title: locale.zipCode,
                          inputFormat: [FilteringTextInputFormatter.digitsOnly],
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    spacing: 5,
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: city,
                          title: locale.city,
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: province,
                          title: locale.province,
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: country,
                          title: locale.country,
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ZTextFieldEntitled(
                    controller: address,
                    keyboardInputType: TextInputType.multiline,
                    maxLength: 100,
                    title: locale.address,
                    onSubmit: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    spacing: 8,
                    children: [
                      Checkbox(
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        value: isMailingAddress,
                        onChanged: (value) {
                          setState(() {
                            isMailingAddress = value ?? true;
                            mailingValue = isMailingAddress ? 1 : 0;
                          });
                        },
                      ),
                      Text(locale.isMilling),
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
class _MobileBranchAddEdit extends StatelessWidget {
  final BranchModel? model;

  const _MobileBranchAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchAddEdit(
      model: model,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletBranchAddEdit extends StatelessWidget {
  final BranchModel? model;

  const _TabletBranchAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchAddEdit(
      model: model,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopBranchAddEdit extends StatelessWidget {
  final BranchModel? model;

  const _DesktopBranchAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchAddEdit(
      model: model,
      isMobile: false,
      isTablet: false,
    );
  }
}