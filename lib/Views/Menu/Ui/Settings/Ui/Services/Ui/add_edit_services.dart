import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zform_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/bloc/services_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/model/services_model.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';


class AddEditServiceView extends StatelessWidget {
  final ServicesModel? model;
  const AddEditServiceView({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileServiceAddEdit(model: model),
      tablet: _TabletServiceAddEdit(model: model),
      desktop: _DesktopServiceAddEdit(model: model),
    );
  }
}

// Base class to share common functionality
class _BaseServiceAddEdit extends StatefulWidget {
  final ServicesModel? model;
  final bool isMobile;
  final bool isTablet;

  const _BaseServiceAddEdit({
    required this.model,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseServiceAddEdit> createState() => _BaseServiceAddEditState();
}

class _BaseServiceAddEditState extends State<_BaseServiceAddEdit> {
  final formKey = GlobalKey<FormState>();
  final serviceName = TextEditingController();
  int status = 1;
  String? usrName;

  @override
  void initState() {
    super.initState();
    if (widget.model != null) {
      serviceName.text = widget.model?.srvName ?? "";
      status = widget.model?.srvStatus ?? 1;
    }
  }

  @override
  void dispose() {
    serviceName.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
    final bloc = context.read<ServicesBloc>();

    final data = ServicesModel(
      srvId: widget.model?.srvId,
      srvName: serviceName.text,
      srvStatus: status,
    );

    if (widget.model != null) {
      bloc.add(UpdateServicesEvent(data));
    } else {
      bloc.add(AddServicesEvent(data));
    }
  }

  // Build action button based on screen size and state
  Widget _buildActionButton(AppLocalizations tr, ColorScheme color, bool isEdit) {
    if (widget.isMobile) {
      return SizedBox(
        width: double.infinity,
        child: ZOutlineButton(
          onPressed: (context.watch<ServicesBloc>().state is ServicesLoadingState)
              ? null
              : onSubmit,
          isActive: true,
          label: (context.watch<ServicesBloc>().state is ServicesLoadingState)
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: color.surface,
            ),
          )
              : Text(
            isEdit ? tr.update : tr.create,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return (context.watch<ServicesBloc>().state is ServicesLoadingState)
          ? SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          color: color.surface,
          strokeWidth: 2,
        ),
      )
          : Text(isEdit ? tr.update : tr.create);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    usrName = login.usrName ?? "";

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
          color: color.surface,
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
                      color.primary,
                      color.primary.withValues(alpha: .8),
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
                            isEdit ? 'Edit Service' : 'New Service',
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEdit ? 'Update service information' : 'Create a new service',
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
                    child: BlocBuilder<ServicesBloc, ServicesState>(
                      builder: (context, serviceState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Service Name Field
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.surface,
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
                                title: 'Service Name',
                                controller: serviceName,
                                isRequired: true,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Service name is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Status Switch (only for edit mode)
                            if (isEdit) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: color.outline.withValues(alpha: .2),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr.status,
                                      style: textTheme.bodyLarge,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          status == 1 ? tr.active : tr.inactive,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: status == 1 ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Switch(
                                          value: status == 1,
                                          onChanged: (e) {
                                            setState(() {
                                              status = e ? 1 : 0;
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
                            ],

                            // Error Message
                            if (serviceState is ServicesErrorState) ...[
                              const SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.error.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: color.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        serviceState.message,
                                        style: TextStyle(
                                          color: color.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Action Button
                            _buildActionButton(tr, color, isEdit),

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
        onAction: onSubmit,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        width: 500,
        actionLabel: _buildActionButton(tr, color, isEdit),
        title: isEdit ? 'Edit Service' : 'New Service',
        child: Form(
          key: formKey,
          child: BlocBuilder<ServicesBloc, ServicesState>(
            builder: (context, serviceState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ZTextFieldEntitled(
                      title: 'Service Name',
                      controller: serviceName,
                      isRequired: true,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Service name is required';
                        }
                        return null;
                      },
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.outline.withValues(alpha: .2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr.status,
                              style: textTheme.bodyLarge,
                            ),
                            Row(
                              children: [
                                Text(
                                  status == 1 ? tr.active : tr.inactive,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: status == 1 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: status == 1,
                                  onChanged: (e) {
                                    setState(() {
                                      status = e ? 1 : 0;
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
                    ],
                    if (serviceState is ServicesErrorState) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.error.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: color.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                serviceState.message,
                                style: TextStyle(
                                  color: color.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Desktop dialog
      return BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, serviceState) {
          return ZFormDialog(
            onAction: onSubmit,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            actionLabel: serviceState is ServicesLoadingState
                ? SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: color.surface,
                strokeWidth: 2,
              ),
            )
                : Text(isEdit ? tr.update : tr.create),
            title: isEdit ? 'Edit Service' : 'New Service',
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ZTextFieldEntitled(
                    title: 'Service Name',
                    controller: serviceName,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Service name is required';
                      }
                      return null;
                    },
                  ),
                  if (isEdit) const SizedBox(height: 12),
                  if (isEdit)
                    Row(
                      children: [
                        Switch(
                          value: status == 1,
                          onChanged: (e) {
                            setState(() {
                              status = e ? 1 : 0;
                            });
                          },
                          activeTrackColor: Colors.green,
                          activeThumbColor: Colors.white,
                          inactiveTrackColor: Colors.red.withValues(alpha: .5),
                          inactiveThumbColor: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status == 1 ? tr.active : tr.inactive,
                          style: TextStyle(
                            color: status == 1 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (serviceState is ServicesErrorState) const SizedBox(height: 15),
                  if (serviceState is ServicesErrorState)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.error.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: color.error,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              serviceState.message,
                              style: TextStyle(
                                color: color.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}

// Mobile View
class _MobileServiceAddEdit extends StatelessWidget {
  final ServicesModel? model;

  const _MobileServiceAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseServiceAddEdit(
      model: model,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletServiceAddEdit extends StatelessWidget {
  final ServicesModel? model;

  const _TabletServiceAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseServiceAddEdit(
      model: model,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopServiceAddEdit extends StatelessWidget {
  final ServicesModel? model;

  const _DesktopServiceAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseServiceAddEdit(
      model: model,
      isMobile: false,
      isTablet: false,
    );
  }
}