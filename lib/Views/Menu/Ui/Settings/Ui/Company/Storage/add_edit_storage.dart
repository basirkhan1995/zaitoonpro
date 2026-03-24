import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zform_dialog.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import '../../../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';

class StorageAddEditView extends StatelessWidget {
  final StorageModel? selectedStorage;

  const StorageAddEditView({super.key, this.selectedStorage});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileStorageAddEdit(model: selectedStorage),
      tablet: _TabletStorageAddEdit(model: selectedStorage),
      desktop: _DesktopStorageAddEdit(model: selectedStorage),
    );
  }
}

// Base class to share common functionality
class _BaseStorageAddEdit extends StatefulWidget {
  final StorageModel? model;
  final bool isMobile;
  final bool isTablet;

  const _BaseStorageAddEdit({
    required this.model,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseStorageAddEdit> createState() => _BaseStorageAddEditState();
}

class _BaseStorageAddEditState extends State<_BaseStorageAddEdit> {
  // Controllers
  final TextEditingController storageName = TextEditingController();
  final TextEditingController storageDetails = TextEditingController();
  final TextEditingController storageLocation = TextEditingController();

  int statusValue = 1;
  bool isActive = true;

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      storageName.text = m.stgName ?? "";
      storageDetails.text = m.stgDetails ?? "";
      storageLocation.text = m.stgLocation ?? "";
      statusValue = m.stgStatus ?? 1;
      isActive = statusValue == 1;
    }
  }

  @override
  void dispose() {
    storageName.dispose();
    storageDetails.dispose();
    storageLocation.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = StorageModel(
      stgId: widget.model?.stgId,
      stgName: storageName.text,
      stgDetails: storageDetails.text,
      stgLocation: storageLocation.text,
      stgStatus: statusValue,
    );

    final bloc = context.read<StorageBloc>();

    if (widget.model == null) {
      bloc.add(AddStorageEvent(data));
    } else {
      bloc.add(UpdateStorageEvent(data));
    }
  }

  // Build action button based on screen size and state
  Widget _buildActionButton(AppLocalizations locale, ColorScheme theme, bool isEdit) {
    if (widget.isMobile) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (context.watch<StorageBloc>().state is StorageLoadingState)
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
          child: (context.watch<StorageBloc>().state is StorageLoadingState)
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
      return (context.watch<StorageBloc>().state is StorageLoadingState)
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
    final titleStyle = textTheme.titleSmall?.copyWith();
    final isEdit = widget.model != null;

    if (widget.isMobile) {
      // Mobile Dialog - Full screen dialog without Scaffold
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
              // Header with gradient background
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
                    child: BlocConsumer<StorageBloc, StorageState>(
                      listener: (context, state) {
                        if (state is StorageSuccessState) {
                          Navigator.of(context).pop();
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Storage Name Field
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
                                controller: storageName,
                                isRequired: true,
                                title: locale.storage,
                                onSubmit: (_) => onSubmit(),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return locale.required(locale.storage);
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Location Field
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
                                controller: storageLocation,
                                isRequired: true,
                                title: locale.location,
                                onSubmit: (_) => onSubmit(),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return locale.required(locale.location);
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Details Field
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
                                controller: storageDetails,
                                keyboardInputType: TextInputType.multiline,
                                maxLength: 100,
                                title: locale.details,
                                onSubmit: (_) => onSubmit(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Status Card
                            Container(
                              padding: const EdgeInsets.all(16),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale.status,
                                    style: titleStyle?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isActive ? locale.active : locale.inactive,
                                        style: textTheme.titleMedium?.copyWith(
                                          color: isActive ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Switch.adaptive(
                                        value: statusValue == 1,
                                        onChanged: (value) {
                                          setState(() {
                                            isActive = value;
                                            statusValue = isActive ? 1 : 0;
                                          });
                                        },
                                        activeTrackColor: Colors.green,
                                        activeThumbColor: Colors.white,
                                        inactiveTrackColor: Colors.red.withValues(alpha: .5),
                                        inactiveThumbColor: Colors.white,
                                      ),
                                    ],
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
        width: 500,
        title: isEdit ? locale.update : locale.newKeyword,
        actionLabel: _buildActionButton(locale, theme, isEdit),
        onAction: onSubmit,
        child: Form(
          key: formKey,
          child: BlocConsumer<StorageBloc, StorageState>(
            listener: (context, state) {
              if (state is StorageSuccessState) {
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ZTextFieldEntitled(
                    controller: storageName,
                    isRequired: true,
                    title: locale.storage,
                    onSubmit: (_) => onSubmit(),
                    validator: (value) {
                      if (value.isEmpty) {
                        return locale.required(locale.storage);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ZTextFieldEntitled(
                    controller: storageLocation,
                    isRequired: true,
                    title: locale.location,
                    onSubmit: (_) => onSubmit(),
                    validator: (value) {
                      if (value.isEmpty) {
                        return locale.required(locale.location);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ZTextFieldEntitled(
                    controller: storageDetails,
                    keyboardInputType: TextInputType.multiline,
                    maxLength: 100,
                    title: locale.details,
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
                        Expanded(
                          child: Text(
                            locale.status,
                            style: titleStyle,
                          ),
                        ),
                        Row(
                          children: [
                            Switch.adaptive(
                              value: statusValue == 1,
                              onChanged: (value) {
                                setState(() {
                                  isActive = value;
                                  statusValue = isActive ? 1 : 0;
                                });
                              },
                              activeTrackColor: Colors.green,
                              activeThumbColor: Colors.white,
                              inactiveTrackColor: Colors.red.withValues(alpha: .5),
                              inactiveThumbColor: Colors.white,
                            ),
                            Text(
                              isActive ? locale.active : locale.inactive,
                              style: textTheme.bodyMedium?.copyWith(
                                color: isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
      // Desktop dialog
      return ZFormDialog(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        width: 550,
        title: isEdit ? locale.update : locale.newKeyword,
        actionLabel: _buildActionButton(locale, theme, isEdit),
        onAction: onSubmit,
        child: Form(
          key: formKey,
          child: BlocConsumer<StorageBloc, StorageState>(
            listener: (context, state) {
              if (state is StorageSuccessState) {
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ZTextFieldEntitled(
                    controller: storageName,
                    isRequired: true,
                    title: locale.storage,
                    onSubmit: (_) => onSubmit(),
                    validator: (value) {
                      if (value.isEmpty) {
                        return locale.required(locale.storage);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ZTextFieldEntitled(
                    controller: storageLocation,
                    isRequired: true,
                    title: locale.location,
                    onSubmit: (_) => onSubmit(),
                    validator: (value) {
                      if (value.isEmpty) {
                        return locale.required(locale.location);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ZTextFieldEntitled(
                    controller: storageDetails,
                    keyboardInputType: TextInputType.multiline,
                    maxLength: 100,
                    title: locale.details,
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
                        Expanded(
                          child: Text(
                            locale.status,
                            style: titleStyle,
                          ),
                        ),
                        Row(
                          children: [
                            Switch.adaptive(
                              value: statusValue == 1,
                              onChanged: (value) {
                                setState(() {
                                  isActive = value;
                                  statusValue = isActive ? 1 : 0;
                                });
                              },
                              activeTrackColor: Colors.green,
                              activeThumbColor: Colors.white,
                              inactiveTrackColor: Colors.red.withValues(alpha: .5),
                              inactiveThumbColor: Colors.white,
                            ),
                            Text(
                              isActive ? locale.active : locale.inactive,
                              style: textTheme.bodyMedium?.copyWith(
                                color: isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
    }
  }
}

// Mobile View
class _MobileStorageAddEdit extends StatelessWidget {
  final StorageModel? model;

  const _MobileStorageAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseStorageAddEdit(
      model: model,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletStorageAddEdit extends StatelessWidget {
  final StorageModel? model;

  const _TabletStorageAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseStorageAddEdit(
      model: model,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopStorageAddEdit extends StatelessWidget {
  final StorageModel? model;

  const _DesktopStorageAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseStorageAddEdit(
      model: model,
      isMobile: false,
      isTablet: false,
    );
  }
}