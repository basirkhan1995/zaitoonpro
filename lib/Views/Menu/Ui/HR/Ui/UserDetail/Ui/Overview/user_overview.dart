import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/cover.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/HR/Ui/Users/bloc/users_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/HR/Ui/Users/features/branch_dropdown.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/HR/Ui/Users/model/user_model.dart';
import '../../../../../../../../Features/Other/image_helper.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Settings/Ui/General/Ui/UserRole/features/role_drop.dart';

class UserOverviewView extends StatelessWidget {
  final UsersModel user;
  const UserOverviewView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(user: user),
      tablet: _Tablet(user: user),
      desktop: _Desktop(user),
    );
  }
}

class _Mobile extends StatefulWidget {
  final UsersModel user;
  const _Mobile({required this.user});

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  bool isEditMode = false;
  bool usrFcp = true;
  int? usrStatus;
  int? branchCode;
  int? roleId;

  final formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final usrName = TextEditingController();
  final usrPass = TextEditingController();
  final confirmPass = TextEditingController();

  @override
  void initState() {
    email.text = widget.user.usrEmail ?? "";
    usrName.text = widget.user.usrName ?? "";
    roleId =  widget.user.rolID;
    branchCode = widget.user.usrBranch;
    usrFcp = widget.user.usrFcp == 1;
    usrStatus = widget.user.usrStatus;
    super.initState();
  }

  void toggleEdit() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  String? currentUser() {
    try {
      final companyState = context.read<AuthBloc>().state;
      if (companyState is AuthenticatedState) {
        return companyState.loginData.usrName;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  void saveChanges() {
    final updatedUser = UsersModel(
      usrName: usrName.text,
      usrEmail: email.text,
      usrPass: usrPass.text,
      rolID: roleId,
      usrBranch: branchCode,
      usrFcp: usrFcp ? 1 : 0,
      loggedInUser: currentUser(),
      usrStatus: usrStatus ?? widget.user.usrStatus,
    );

    if (formKey.currentState!.validate()) {
      context.read<UsersBloc>().add(UpdateUserEvent(updatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeCtrl = Theme.of(context);

    TextStyle? myStyle = textTheme.titleSmall?.copyWith(
      color: color.outline.withValues(alpha: .8),
    );
    TextStyle? myStyleBody = textTheme.bodyMedium?.copyWith(
      color: color.onSurface.withValues(alpha: .9),
    );

    final isLoading = context.watch<UsersBloc>().state is UsersLoadingState;

    return Scaffold(
      body: BlocListener<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UserSuccessState) {
            setState(() {
              isEditMode = false;
            });
            Utils.showOverlayMessage(
              context,
              title: tr.successTitle,
              message: tr.successMessage,
              isError: false,
            );
          }
          if (state is UsersErrorState) {
            Utils.showOverlayMessage(
              context,
              title: tr.accessDenied,
              message: state.message,
              isError: true,
            );
          }
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isEditMode
            ? _editView(tr: tr)
            : _overviewView(
          tr: tr,
          myStyle: myStyle,
          myStyleBody: myStyleBody,
          themeCtrl: themeCtrl,
        ),
      ),
    );
  }

  Widget _overviewView({
    required AppLocalizations tr,
    TextStyle? myStyle,
    TextStyle? myStyleBody,
    required ThemeData themeCtrl,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Header
          Center(
            child: Column(
              children: [
                ZCover(
                  radius: 5,
                  child: ListTile(
                    title: Text(
                      widget.user.usrFullName ?? "",
                      style: themeCtrl.textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      widget.user.usrRole ?? "",
                      style: themeCtrl.textTheme.titleSmall?.copyWith(
                        color: themeCtrl.colorScheme.outline.withValues(alpha: .8),
                        fontSize: 12
                      ),
                    ),
                    leading: CircleAvatar(
                      child: ImageHelper.stakeholderProfile(
                        imageName: widget.user.usrPhoto,
                        size: 60,
                      ),
                    ),
                    trailing: (!isEditMode)?  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: toggleEdit,
                    ) : null,
                    visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

              ],
            ),
          ),
          const SizedBox(height: 12),

          // User Information Card
          ZCover(
            radius: 5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: tr.username,
                    value: widget.user.usrName ?? "",
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: tr.email,
                    value: widget.user.usrEmail ?? "",
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: tr.usrRole,
                    value: widget.user.usrRole ?? "",
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.business_outlined,
                    label: tr.branch,
                    value: widget.user.usrBranch.toString(),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: tr.createdAt,
                    value: widget.user.usrEntryDate?.toFullDateTime ?? "",
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.circle,
                    label: tr.status,
                    value: widget.user.usrStatus == 1 ? tr.active : tr.blocked,
                    valueColor: widget.user.usrStatus == 1
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .9),),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editView({required AppLocalizations tr}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Edit Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr.edit,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: toggleEdit,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Read-only fields
            ZTextFieldEntitled(
              title: tr.username,
              controller: usrName,
              isEnabled: false,
              readOnly: true,
            ),
            const SizedBox(height: 12),

            ZTextFieldEntitled(
              title: tr.email,
              controller: email,
              isEnabled: false,
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // Dropdowns
            Text(
              tr.roleAndBranch,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            ZCover(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .01),
              radius: 5,
              child: Column(
                children: [
                  BranchDropdown(
                    selectedId: branchCode,
                    onBranchSelected: (e) {
                      setState(() {
                        branchCode = e?.brcId;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  UserRoleDropdown(
                    selectedId: roleId,
                    onRoleSelected: (e) {
                      setState(() {
                        roleId = e?.rolId;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Password Reset Section
            ZCover(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .01),
              radius: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_reset, size: 20, color: Theme.of(context).colorScheme.outline.withValues(alpha: .9)),
                        const SizedBox(width: 8),
                        Text(
                          tr.resetPassword,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ZTextFieldEntitled(
                      controller: usrPass,
                      isRequired: false,
                      title: tr.newPasswordTitle,
                      securePassword: true,
                    ),
                    const SizedBox(height: 8),
                    ZTextFieldEntitled(
                      controller: confirmPass,
                      title: tr.confirmPassword,
                      securePassword: true,
                      validator: (value) {
                        if (usrPass.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.confirmPassword);
                          }
                          if (usrPass.text != confirmPass.text) {
                            return tr.passwordNotMatch;
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings Section
            ZCover(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .01),
              radius: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Status Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              usrStatus == 1 ? Icons.check_circle : Icons.cancel,
                              color: usrStatus == 1 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              usrStatus == 1 ? tr.active : tr.blocked,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Switch(
                          value: usrStatus == 1,
                          onChanged: (e) {
                            setState(() {
                              usrStatus = e ? 1 : 0;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),

                    // Force Change Password Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_clock, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              tr.forceChangePasswordTitle,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Switch(
                          value: usrFcp,
                          onChanged: (e) {
                            setState(() {
                              usrFcp = e;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ZOutlineButton(
                isActive: true,
                onPressed: saveChanges,
                icon: Icons.save,
                label: Text(tr.saveChanges),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton.icon(
                onPressed: toggleEdit,
                icon: const Icon(Icons.cancel),
                label: Text(tr.cancel),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  final UsersModel user;
  const _Tablet({required this.user});

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  bool isEditMode = false;
  bool usrFcp = true;
  int? usrStatus;
  int? branchCode;
  int? roleId;

  final formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final usrName = TextEditingController();
  final usrPass = TextEditingController();
  final confirmPass = TextEditingController();

  @override
  void initState() {
    email.text = widget.user.usrEmail ?? "";
    usrName.text = widget.user.usrName ?? "";
    roleId = widget.user.rolID;
    branchCode = widget.user.usrBranch;
    usrFcp = widget.user.usrFcp == 1;
    usrStatus = widget.user.usrStatus;
    super.initState();
  }

  void toggleEdit() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  String? currentUser() {
    try {
      final companyState = context.read<AuthBloc>().state;
      if (companyState is AuthenticatedState) {
        return companyState.loginData.usrName;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  void saveChanges() {
    final updatedUser = UsersModel(
      usrName: usrName.text,
      usrEmail: email.text,
      usrPass: usrPass.text,
      rolID: roleId,
      usrBranch: branchCode,
      usrFcp: usrFcp ? 1 : 0,
      loggedInUser: currentUser(),
      usrStatus: usrStatus ?? widget.user.usrStatus,
    );

    if (formKey.currentState!.validate()) {
      context.read<UsersBloc>().add(UpdateUserEvent(updatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeCtrl = Theme.of(context);

    TextStyle? myStyle = textTheme.titleSmall?.copyWith(
      color: color.outline.withValues(alpha: .8),
    );
    TextStyle? myStyleBody = textTheme.bodyMedium?.copyWith(
      color: color.onSurface.withValues(alpha: .9),
    );

    final isLoading = context.watch<UsersBloc>().state is UsersLoadingState;

    return Scaffold(

      body: BlocListener<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UserSuccessState) {
            setState(() {
              isEditMode = false;
            });
          }
          if (state is UsersErrorState) {
            Utils.showOverlayMessage(
              context,
              title: tr.accessDenied,
              message: state.message,
              isError: true,
            );
          }
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 500),
            crossFadeState: isEditMode
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _editView(tr: tr),
            secondChild: _overviewView(
              tr: tr,
              myStyle: myStyle,
              myStyleBody: myStyleBody,
              themeCtrl: themeCtrl,
            ),
          ),
        ),
      ),
    );
  }

  Widget _overviewView({
    required AppLocalizations tr,
    TextStyle? myStyle,
    TextStyle? myStyleBody,
    required ThemeData themeCtrl,
  }) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeCtrl.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeCtrl.colorScheme.outline.withValues(alpha: .4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.userInformation,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: toggleEdit,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Using a more tablet-friendly layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - labels
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelRow(tr.userOwner, myStyle),
                      _buildLabelRow(tr.username, myStyle),
                      _buildLabelRow(tr.usrRole, myStyle),
                      _buildLabelRow(tr.branch, myStyle),
                      _buildLabelRow(tr.createdAt, myStyle),
                      _buildLabelRow(tr.status, myStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right column - values
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildValueRow(widget.user.usrFullName ?? "", myStyleBody),
                      _buildValueRow(widget.user.usrName ?? "", myStyleBody),
                      _buildValueRow(widget.user.usrRole ?? "", myStyleBody),
                      _buildValueRow(widget.user.usrBranch.toString(), myStyleBody),
                      _buildValueRow(
                        widget.user.usrEntryDate!.toFullDateTime,
                        myStyleBody,
                      ),
                      _buildValueRow(
                        widget.user.usrStatus == 1 ? tr.active : tr.blocked,
                        myStyleBody?.copyWith(
                          color: widget.user.usrStatus == 1
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow(String label, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label, style: style),
    );
  }

  Widget _buildValueRow(String value, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(value, style: style),
    );
  }

  Widget _editView({required AppLocalizations tr}) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .4),
          ),
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.edit,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: toggleEdit,
                      ),
                      const SizedBox(width: 8),
                      ZOutlineButton(
                        onPressed: saveChanges,
                        icon: Icons.save,
                        isActive: true,
                        label: Text(tr.saveChanges),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Tablet grid layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        ZTextFieldEntitled(
                          title: tr.username,
                          controller: usrName,
                          isEnabled: false,
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        ZTextFieldEntitled(
                          title: tr.email,
                          controller: email,
                          isEnabled: false,
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        BranchDropdown(
                          selectedId: branchCode,
                          onBranchSelected: (e) {
                            setState(() {
                              branchCode = e?.brcId;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        UserRoleDropdown(
                          selectedId: roleId,
                          onRoleSelected: (e) {
                            setState(() {
                              roleId = e?.rolId;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Password reset section
              Text(
               tr.resetPassword,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      controller: usrPass,
                      isRequired: false,
                      title: tr.newPasswordTitle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ZTextFieldEntitled(
                      controller: confirmPass,
                      title: tr.confirmPassword,
                      validator: (value) {
                        if (usrPass.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.confirmPassword);
                          }
                          if (usrPass.text != confirmPass.text) {
                            return tr.passwordNotMatch;
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Settings section
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Switch(
                          value: usrStatus == 1,
                          onChanged: (e) {
                            setState(() {
                              usrStatus = e ? 1 : 0;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(usrStatus == 1 ? tr.active : tr.blocked),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Switch(
                          value: usrFcp,
                          onChanged: (e) {
                            setState(() {
                              usrFcp = e;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tr.forceChangePasswordTitle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  final UsersModel user;
  const _Desktop(this.user);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  bool isEditMode = false;
  bool usrFcp = true;
  int? usrStatus;
  int? branchCode;
  int? roleId;

  final formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final usrName = TextEditingController();
  final usrPass = TextEditingController();
  final confirmPass = TextEditingController();

  @override
  void initState() {
    email.text = widget.user.usrEmail ?? "";
    usrName.text = widget.user.usrName ?? "";
    roleId = widget.user.rolID;
    branchCode = widget.user.usrBranch;
    usrFcp = widget.user.usrFcp == 1;
    usrStatus = widget.user.usrStatus;
    super.initState();
  }

  void toggleEdit() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  String? currentUser() {
    try {
      final companyState = context.read<AuthBloc>().state;
      if (companyState is AuthenticatedState) {
        return companyState.loginData.usrName;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  void saveChanges() {
    final updatedUser = UsersModel(
      usrName: usrName.text,
      usrEmail: email.text,
      usrPass: usrPass.text,
      rolID: roleId,
      usrBranch: branchCode,
      usrFcp: usrFcp ? 1 : 0,
      loggedInUser: currentUser(),
      usrStatus: usrStatus ?? widget.user.usrStatus,
    );

    if (formKey.currentState!.validate()) {
      context.read<UsersBloc>().add(UpdateUserEvent(updatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeCtrl = Theme.of(context);

    TextStyle? myStyle = textTheme.titleSmall?.copyWith(
      color: color.outline.withValues(alpha: .8),
    );
    TextStyle? myStyleBody = textTheme.bodyMedium?.copyWith(
      color: color.onSurface.withValues(alpha: .9),
    );

    final isLoading = context.watch<UsersBloc>().state is UsersLoadingState;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocListener<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UserSuccessState) {
            setState(() {
              isEditMode = false;
            });
          }
          if (state is UsersErrorState) {
            Utils.showOverlayMessage(
              context,
              title: tr.accessDenied,
              message: state.message,
              isError: true,
            );
          }
        },
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 500),
          crossFadeState: isEditMode
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _editView(locale: tr, isLoading: isLoading),
          secondChild: _overView(
            tr: tr,
            textTheme: themeCtrl,
            myStyle: myStyle,
            myStyleBody: myStyleBody,
            color: themeCtrl,
          ),
        ),
      ),
    );
  }

  Widget _overView({
    required AppLocalizations tr,
    required ThemeData textTheme,
    TextStyle? myStyle,
    TextStyle? myStyleBody,
    required ThemeData color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: color.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.colorScheme.outline.withValues(alpha: .4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr.userInformation,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Material(
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5),
                    hoverColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                    highlightColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                    onTap: toggleEdit,
                    child: const Icon(Icons.edit),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.email, size: 20),
              const SizedBox(width: 5),
              Text(widget.user.usrEmail ?? ""),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(tr.userOwner, style: myStyle),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 120,
                    child: Text(tr.username, style: myStyle),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 120,
                    child: Text(tr.usrRole, style: myStyle),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 120,
                    child: Text(tr.branch, style: myStyle),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 120,
                    child: Text(tr.createdAt, style: myStyle),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 120,
                    child: Text(tr.status, style: myStyle),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.usrFullName ?? "", style: myStyleBody),
                  const SizedBox(height: 5),
                  Text(widget.user.usrName ?? "", style: myStyleBody),
                  const SizedBox(height: 5),
                  Text(widget.user.usrRole ?? "", style: myStyleBody),
                  const SizedBox(height: 5),
                  Text(widget.user.usrBranch.toString(), style: myStyleBody),
                  const SizedBox(height: 5),
                  Text(
                    widget.user.usrEntryDate!.toFullDateTime,
                    style: myStyleBody,
                  ),
                  const SizedBox(height: 5),
                  Text(widget.user.usrStatus == 1 ? tr.active : tr.blocked),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editView({
    required AppLocalizations locale,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.userInformation,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Material(
                  child: Row(
                    spacing: 5,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(5),
                        hoverColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .08),
                        highlightColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .08),
                        onTap: toggleEdit,
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(Icons.clear),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        width: 30,
                        child: Tooltip(
                          message: locale.saveChanges,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(5),
                            hoverColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: .08),
                            highlightColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: .08),
                            onTap: isLoading ? null : saveChanges,
                            child: isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.check),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 5),
            ZTextFieldEntitled(
              title: locale.username,
              controller: usrName,
              isEnabled: false,
              readOnly: true,
            ),
            const SizedBox(height: 5),
            ZTextFieldEntitled(
              isEnabled: false,
              title: locale.email,
              controller: email,
              readOnly: true,
            ),
            const SizedBox(height: 5),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: BranchDropdown(
                    selectedId: branchCode,
                    onBranchSelected: (e) {
                      setState(() {
                        branchCode = e?.brcId;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: UserRoleDropdown(
                    selectedId: roleId,
                    onRoleSelected: (e) {
                      setState(() {
                        roleId = e?.rolId;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
              Row(
              children: [Text(locale.resetPassword.toUpperCase())],
            ),
            Row(
              spacing: 5,
              children: [
                Expanded(
                  child: ZTextFieldEntitled(
                    controller: usrPass,
                    isRequired: false,
                    title: locale.newPasswordTitle,
                  ),
                ),
                Expanded(
                  child: ZTextFieldEntitled(
                    controller: confirmPass,
                    title: locale.confirmPassword,
                    validator: (value) {
                      if (usrPass.text.isNotEmpty) {
                        if (value == null || value.isEmpty) {
                          return locale.required(locale.confirmPassword);
                        }
                        if (usrPass.text != confirmPass.text) {
                          return locale.passwordNotMatch;
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Switch(
                  value: usrStatus == 1,
                  onChanged: (e) {
                    setState(() {
                      usrStatus = e == true ? 1 : 0;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(usrStatus == 1 ? locale.active : locale.blocked),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Switch(
                  value: usrFcp,
                  onChanged: (e) {
                    setState(() {
                      usrFcp = e;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(locale.forceChangePasswordTitle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}