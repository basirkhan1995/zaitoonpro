import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/zForm_dialog.dart';
import 'package:zaitoon_petroleum/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import 'bloc/user_role_bloc.dart';
import 'model/role_model.dart';

class AddEditUserRoleSettingsView extends StatelessWidget {
  final UserRoleModel? model;
  const AddEditUserRoleSettingsView({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(model: model),
      tablet: _Tablet(model: model),
      desktop: _Desktop(model),
    );
  }
}

// Mobile Version - Full screen dialog
class _Mobile extends StatelessWidget {
  final UserRoleModel? model;
  const _Mobile({this.model});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        child: _AddEditForm(model: model),
      ),
    );
  }
}

// Tablet Version - Medium sized dialog
class _Tablet extends StatelessWidget {
  final UserRoleModel? model;
  const _Tablet({this.model});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 500,
        child: _AddEditForm(model: model),
      ),
    );
  }
}

// Desktop Version - Using ZFormDialog
class _Desktop extends StatelessWidget {
  final UserRoleModel? model;
  const _Desktop(this.model);

  @override
  Widget build(BuildContext context) {
    return _AddEditForm(model: model, isDesktop: true);
  }
}

// Shared Form Widget
class _AddEditForm extends StatefulWidget {
  final UserRoleModel? model;
  final bool isDesktop;

  const _AddEditForm({
    this.model,
    this.isDesktop = false,
  });

  @override
  State<_AddEditForm> createState() => _AddEditFormState();
}

class _AddEditFormState extends State<_AddEditForm> {
  final formKey = GlobalKey<FormState>();
  final roleNameController = TextEditingController();
  bool isActive = true;
  String? usrName;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    if (widget.model != null) {
      roleNameController.text = widget.model?.rolName ?? "";
      isActive = widget.model?.rolStatus == 1;
    }
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      setState(() {
        usrName = authState.loginData.usrName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isEdit = widget.model != null;

    // For desktop, use ZFormDialog
    if (widget.isDesktop) {
      return BlocBuilder<UserRoleBloc, UserRoleState>(
        builder: (context, roleState) {
          return ZFormDialog(
            onAction: _onSubmit,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            actionLabel: roleState is UserRoleLoadingState
                ? SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: colorScheme.surface,
                strokeWidth: 2,
              ),
            )
                : Text(isEdit ? tr.update : tr.create),
            title: isEdit ? tr.editRole : tr.newRole,
            child: _buildFormContent(context, roleState),
          );
        },
      );
    }

    // For mobile and tablet, use regular dialog with custom buttons
    return BlocBuilder<UserRoleBloc, UserRoleState>(
      builder: (context, roleState) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? tr.editRole : tr.newRole,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Content
              _buildFormContent(context, roleState),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: .3),
                          ),
                        ),
                      ),
                      child: Text(
                        tr.cancel,
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: roleState is UserRoleLoadingState
                          ? null
                          : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: roleState is UserRoleLoadingState
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: colorScheme.surface,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(isEdit ? tr.update : tr.create),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Shared form content
  Widget _buildFormContent(BuildContext context, UserRoleState roleState) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZTextFieldEntitled(
            title: tr.roleName,
            controller: roleNameController,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr.required(tr.roleName);
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Status Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: .2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr.status,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isActive = !isActive;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withValues(alpha: .1)
                          : Colors.red.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isActive ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.cancel,
                          color: isActive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? tr.active : tr.inactive,
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (roleState is UserRoleErrorState) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: .3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      roleState.message,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 13,
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
  }

  void _onSubmit() async {
    if (!formKey.currentState!.validate()) return;

    // Get fresh username from AuthBloc
    String? userName;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      userName = authState.loginData.usrName;
    }

    if (userName == null || userName.isEmpty) {
      // Show error if username is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final bloc = context.read<UserRoleBloc>();

    if (widget.model != null) {
      // Update existing role
      final updatedRole = UserRoleModel(
        usrName: userName,
        rolId: widget.model?.rolId,
        rolName: roleNameController.text,
        rolStatus: isActive ? 1 : 0,
      );
      bloc.add(UpdateUserRoleEvent(newRole: updatedRole));
    } else {
      // Add new role
      bloc.add(
        AddUserRoleEvent(
          usrName: userName,
          roleName: roleNameController.text,
        ),
      );
    }
  }

  @override
  void dispose() {
    roleNameController.dispose();
    super.dispose();
  }
}