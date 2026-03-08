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
      mobile: const _Mobile(),
      tablet: const _Tablet(),
      desktop: _Desktop(model),
    );
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Desktop extends StatefulWidget {
  final UserRoleModel? model;
  const _Desktop(this.model);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final formKey = GlobalKey<FormState>();
  final roleNameController = TextEditingController();
  bool isActive = true;
  String? usrName;

  @override
  void initState() {
    if (widget.model != null) {
      roleNameController.text = widget.model?.rolName ?? "";
      isActive = widget.model?.rolStatus == 1;
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
    final bool isEdit = widget.model != null;

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
              color: color.surface,
              strokeWidth: 2,
            ),
          )
              : Text(isEdit ? tr.update : tr.create),
          title: isEdit ? tr.editRole : tr.newRole,
          child: Form(
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
                const SizedBox(height: 12),
                // Status Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .1)),
                    borderRadius: BorderRadius.circular(4),
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
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: .1)
                                : Colors.red.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(2),
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
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Text(
                        roleState.message,
                        style: TextStyle(color: color.error),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSubmit() {
    if (!formKey.currentState!.validate()) return;
    final bloc = context.read<UserRoleBloc>();

    if (widget.model != null) {
      // Update existing role
      final updatedRole = widget.model!.copyWith(
        rolName: roleNameController.text,
        rolStatus: isActive ? 1 : 0,
      );
      bloc.add(UpdateUserRoleEvent(newRole: updatedRole));
    } else {
      // Add new role
      bloc.add(
        AddUserRoleEvent(
          usrName: usrName ?? "",
          roleName: roleNameController.text,
        ),
      );
    }
  }
}