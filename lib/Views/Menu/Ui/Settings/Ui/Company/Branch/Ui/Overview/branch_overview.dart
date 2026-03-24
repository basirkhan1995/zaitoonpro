import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:flutter/services.dart';
import '../../../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../Branches/bloc/branch_bloc.dart';
import '../../../Branches/model/branch_model.dart';

class BranchOverviewView extends StatelessWidget {
  final BranchModel? selectedBranch;

  const BranchOverviewView({super.key, this.selectedBranch});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileBranchOverview(model: selectedBranch),
      tablet: _TabletBranchOverview(model: selectedBranch),
      desktop: _DesktopBranchOverview(model: selectedBranch),
    );
  }
}

// Base class to share common functionality
class _BaseBranchOverview extends StatefulWidget {
  final BranchModel? model;
  final bool isMobile;
  final bool isTablet;

  const _BaseBranchOverview({
    required this.model,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseBranchOverview> createState() => _BaseBranchOverviewState();
}

class _BaseBranchOverviewState extends State<_BaseBranchOverview> {
  final TextEditingController branchName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController province = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController nationalId = TextEditingController();
  final TextEditingController zipCode = TextEditingController();

  int mailingValue = 1;
  int? addId;
  bool isMailingAddress = true;
  int? branchCode;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      branchName.text = m.brcName ?? "";
      branchCode = m.brcId;
      city.text = m.addCity ?? "";
      phone.text = m.brcPhone ?? "";
      province.text = m.addProvince ?? "";
      country.text = m.addCountry ?? "";
      zipCode.text = m.addZipCode?.toString() ?? "";
      address.text = m.addName ?? "";
      mailingValue = m.addMailing ?? 0;
      addId = m.addId;
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
    phone.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = BranchModel(
      brcId: branchCode,
      addCity: city.text,
      addId: addId,
      addCountry: country.text,
      brcName: branchName.text,
      addName: address.text,
      brcPhone: phone.text,
      addMailing: mailingValue,
      addProvince: province.text,
      addZipCode: zipCode.text,
    );

    final bloc = context.read<BranchBloc>();
    bloc.add(EditBranchEvent(data));
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: formKey,
      child: BlocConsumer<BranchBloc, BranchState>(
        listener: (context, state) {
          if (state is BranchSuccessState) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (widget.isMobile) {
            // Mobile layout
            return Container(
              color: theme.surface,
              child: Column(
                children: [
                  // Mobile Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: .05),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.outline.withValues(alpha: .1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            locale.overview,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "ID: ${branchCode ?? ''}",
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Branch Name
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

                          // Phone and Zip Code
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                  controller: phone,
                                  title: locale.mobile1,
                                  inputFormat: [FilteringTextInputFormatter.digitsOnly],
                                  onSubmit: (_) => onSubmit(),
                                ),
                                const SizedBox(height: 12),
                                ZTextFieldEntitled(
                                  controller: zipCode,
                                  title: locale.zipCode,
                                  inputFormat: [FilteringTextInputFormatter.digitsOnly],
                                  onSubmit: (_) => onSubmit(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Location Fields
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                  controller: city,
                                  title: locale.city,
                                  onSubmit: (_) => onSubmit(),
                                ),
                                const SizedBox(height: 12),
                                ZTextFieldEntitled(
                                  controller: province,
                                  title: locale.province,
                                  onSubmit: (_) => onSubmit(),
                                ),
                                const SizedBox(height: 12),
                                ZTextFieldEntitled(
                                  controller: country,
                                  title: locale.country,
                                  onSubmit: (_) => onSubmit(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Address
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

                          // Mailing Checkbox
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(12),
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

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ZOutlineButton(
                                  backgroundHover: theme.error,
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Icons.close,
                                  label: Text(locale.cancel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ZOutlineButton(
                                  isActive: true,
                                  icon: (state is BranchLoadingState) ? null : Icons.refresh,
                                  label: (state is BranchLoadingState)
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: theme.surface,
                                    ),
                                  )
                                      : Text(locale.update),
                                  onPressed: onSubmit,
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
          } else if (widget.isTablet) {
            // Tablet layout
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tablet Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.overview,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                branchName.text.isEmpty
                                    ? locale.branchName
                                    : branchName.text,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: theme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "ID: ${branchCode ?? ''}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
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
                          const SizedBox(height: 16),

                          Row(
                            spacing: 12,
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
                          const SizedBox(height: 16),

                          Row(
                            spacing: 12,
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
                          const SizedBox(height: 16),

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

                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: 12,
                            children: [
                              ZOutlineButton(
                                width: 100,
                                backgroundHover: theme.error,
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icons.close,
                                label: Text(locale.cancel),
                              ),
                              ZOutlineButton(
                                width: 110,
                                isActive: true,
                                icon: (state is BranchLoadingState) ? null : Icons.refresh,
                                label: (state is BranchLoadingState)
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: theme.surface,
                                  ),
                                )
                                    : Text(locale.update),
                                onPressed: onSubmit,
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
          } else {
            // Desktop layout (existing)
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
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

                            const SizedBox(height: 20),

                            const Spacer(),
                            Row(
                              spacing: 8,
                              children: [
                                ZOutlineButton(
                                  width: 100,
                                  backgroundHover: theme.error,
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Icons.close,
                                  label: Text(locale.cancel),
                                ),
                                ZOutlineButton(
                                  width: 110,
                                  isActive: true,
                                  icon: (state is BranchLoadingState) ? null : Icons.refresh,
                                  label: (state is BranchLoadingState)
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: theme.surface,
                                    ),
                                  )
                                      : Text(locale.update),
                                  onPressed: onSubmit,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// Mobile View
class _MobileBranchOverview extends StatelessWidget {
  final BranchModel? model;

  const _MobileBranchOverview({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchOverview(
      model: model,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletBranchOverview extends StatelessWidget {
  final BranchModel? model;

  const _TabletBranchOverview({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchOverview(
      model: model,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopBranchOverview extends StatelessWidget {
  final BranchModel? model;

  const _DesktopBranchOverview({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchOverview(
      model: model,
      isMobile: false,
      isTablet: false,
    );
  }
}