import 'package:flutter/material.dart';
import 'package:zaitoon_petroleum/Features/Other/alert_dialog.dart';
import 'package:zaitoon_petroleum/Features/Other/image_helper.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../../../Auth/models/login_model.dart';
import '../../../../../../../PasswordSettings/change_password.dart';

class UserProfileSettingsView extends StatelessWidget {
  const UserProfileSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _Mobile(),
      tablet: const _Tablet(),
      desktop: const _Desktop(),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        elevation: 0,
      ),
      body: const _ProfileContent(),
    );
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        elevation: 0,
      ),
      body: const Center(
        child: SizedBox(
          width: 600,
          child: _ProfileContent(),
        ),
      ),
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Row(
          children: [
            Expanded(
                flex: 5,
                child: _ProfileContent()),
            Expanded(
                flex: 2,
                child: SizedBox())
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthenticatedState) {
          return _ProfileDetails(loginData: state.loginData);
        } else if (state is AuthLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return const Center(
            child: Text('Please login to view profile'),
          );
        }
      },
    );
  }
}

class _ProfileDetails extends StatefulWidget {
  final LoginData loginData;

  const _ProfileDetails({required this.loginData});

  @override
  State<_ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<_ProfileDetails> {
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.loginData.usrFullName ?? '');
    _emailController = TextEditingController(text: widget.loginData.usrEmail ?? '');
    _phoneController = TextEditingController(text: widget.loginData.perPhone ?? '');
  }

  @override
  void didUpdateWidget(_ProfileDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loginData != widget.loginData) {
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
      if (!isEditing) {
        _initializeControllers();
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement save logic with your API
      setState(() {
        isEditing = false;
      });


    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ZAlertDialog(title: AppLocalizations.of(context)!.logout,
            content: "Are you sure wanna logout", onYes: (){
              context.read<AuthBloc>().add(OnLogoutEvent());
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginData = widget.loginData;
    final theme = Theme.of(context);
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [

            // Profile Photo and Basic Info - Aligned to left
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: ImageHelper.stakeholderProfile(
                        imageName: loginData.usrPhoto,
                        size: 100,
                      ),
                    ),
                    if (isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {

                              },
                              customBorder: const CircleBorder(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      
                const SizedBox(width: 20),
      
                // Name and Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loginData.usrFullName ?? 'No Name',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '@${loginData.usrName ?? 'username'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loginData.usrRole ?? 'No Role',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (!isEditing)
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _toggleEdit,
                              borderRadius: BorderRadius.circular(5),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.editProfile,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      
            const SizedBox(height: 15),

            // Edit/Save buttons when in edit mode
            if (isEditing)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ZOutlineButton(
                        onPressed: _toggleEdit,
                        label: Text(AppLocalizations.of(context)!.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ZOutlineButton(
                        isActive: true,
                        onPressed: _saveChanges,
                        label: Text(AppLocalizations.of(context)!.saveChanges),
                      ),
                    ),
                  ],
                ),
              ),
      
            // Personal Information Section
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.personalInfo,
              children: [
                _buildInfoField(
                  context,
                  label: AppLocalizations.of(context)!.fullName,
                  icon: Icons.person_outline,
                  value: loginData.usrFullName ?? '',
                  controller: _nameController,
                  isEditing: isEditing,
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  context,
                  label: AppLocalizations.of(context)!.email,
                  icon: Icons.email_outlined,
                  value: loginData.usrEmail ?? '',
                  controller: _emailController,
                  isEditing: isEditing,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  context,
                  label: AppLocalizations.of(context)!.mobile1,
                  icon: Icons.phone_outlined,
                  value: loginData.perPhone ?? 'Not provided',
                  controller: _phoneController,
                  isEditing: isEditing,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
      
            const SizedBox(height: 8),
      
            // Work Information Section
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.workInformation,
              children: [
                _buildReadOnlyInfo(
                  context: context,
                  label: AppLocalizations.of(context)!.branch,
                  icon: Icons.business_outlined,
                  value: loginData.brcName ?? 'Not assigned',
                ),
                const SizedBox(height: 16),
                if (loginData.usrEntryDate != null)
                  _buildReadOnlyInfo(
                    context: context,
                    label: AppLocalizations.of(context)!.memberSince,
                    icon: Icons.calendar_today_outlined,
                    value: _formatDate(loginData.usrEntryDate!),
                  ),
              ],
            ),
      
            const SizedBox(height: 12),
      
            // Security Section
            if (login.hasPermission(65) ?? false)
            _buildSection(
              context,
              title:AppLocalizations.of(context)!.securityTitle,
              children: [
                _buildActionTile(
                  context,
                  icon: Icons.lock_outline,
                  iconColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  title: AppLocalizations.of(context)!.changePasswordTitle,
                  subtitle: AppLocalizations.of(context)!.passwordChangeHint,
                  onTap: () {
                    showDialog(context: context, builder: (context){
                      return const PasswordSettingsView();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildActionTile(
                  context,
                  icon: Icons.logout_rounded,
                  iconColor: theme.colorScheme.error,
                  backgroundColor: theme.colorScheme.errorContainer,
                  title: AppLocalizations.of(context)!.logout,
                  subtitle: AppLocalizations.of(context)!.logoutHint,
                  onTap: () => _showLogoutDialog(context),
                  showTrailing: false,
                ),
              ],
            ),
      
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required List<Widget> children,
      }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(
      BuildContext context, {
        required String label,
        required IconData icon,
        required String value,
        TextEditingController? controller,
        bool isEditing = false,
        TextInputType? keyboardType,
      }) {
    final theme = Theme.of(context);

    if (!isEditing) {
      return _buildReadOnlyInfo(
        context: context,
        label: label,
        icon: icon,
        value: value,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(150),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ZTextFieldEntitled(
            controller: controller,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            }, title: '',
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyInfo({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(160),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required Color backgroundColor,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        bool showTrailing = true,
      }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor.withAlpha(150),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showTrailing)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
