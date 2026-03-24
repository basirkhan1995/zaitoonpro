import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/General/Ui/UserProfileSettings/bloc/user_profile_settings_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/General/Ui/UserProfileSettings/model/usr_profile_model.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../Features/Other/image_helper.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../PasswordSettings/change_password.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ColorScheme _colors;
  final double _expandedHeight = 300;
  final ScrollController _scrollController = ScrollController();

  // Track if header is collapsed
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Add scroll listener to detect header collapse
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthenticatedState) {
        context.read<UserProfileSettingsBloc>().add(
          LoadProfileSettingsEvent(auth.loginData.usrName ?? ""),
        );
      }
    });
  }

  void _onScroll() {
    // Update collapse state based on scroll offset
    final bool isCollapsed = _scrollController.offset > _expandedHeight - kToolbarHeight - 50;
    if (_isHeaderCollapsed != isCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _colors.surface,
      body: BlocBuilder<UserProfileSettingsBloc, UserProfileSettingsState>(
        builder: (context, state) {
          if (state is UserProfileSettingsLoadingState) {
            return _buildLoadingState();
          } else if (state is UserProfileSettingsErrorState) {
            return _buildErrorState(state.message);
          } else if (state is UserProfileSettingsLoadedState) {
            return _buildProfileContent(state.profile);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    final tr = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_colors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            tr.loading,
            style: TextStyle(
              color: _colors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: _colors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: _colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final auth = context.read<AuthBloc>().state;
                if (auth is AuthenticatedState) {
                  context.read<UserProfileSettingsBloc>().add(
                    RefreshProfileEvent(auth.loginData.usrName ?? ""),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _colors.primary,
                foregroundColor: _colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(UsrProfileModel profile) {
    final tr = AppLocalizations.of(context)!;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Main SliverAppBar with flexible space
        SliverAppBar(
          expandedHeight: _expandedHeight,
          pinned: true,
          floating: false,
          snap: false,
          backgroundColor: _colors.surface,
          elevation: _isHeaderCollapsed ? 0.5 : 0,
          automaticallyImplyLeading: false,

          // Title that appears on collapse
          title: _buildAnimatedTitle(profile),

          // Flexible space with the header content
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _buildHeader(profile),
          ),

          // Bottom with TabBar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: _colors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: _colors.primary,
                unselectedLabelColor: _colors.onSurfaceVariant,
                indicatorColor: _colors.primary,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                tabs: [
                  Tab(text: tr.personalInfo),
                  Tab(text: tr.accounts),
                  Tab(text: tr.employement),
                  Tab(text: tr.settings),
                ],
              ),
            ),
          ),
        ),

        // TabBarView content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalInfo(profile),
              _buildAccountsInfo(profile),
              _buildEmploymentInfo(profile),
              _buildSettingsInfo(profile),
            ],
          ),
        ),
      ],
    );
  }

  // Animated title that appears on collapse
  Widget _buildAnimatedTitle(UsrProfileModel profile) {
    return AnimatedOpacity(
      opacity: _isHeaderCollapsed ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Row(
          children: [
            // Small circular avatar
            ClipOval(
              child: SizedBox(
                width: 32,
                height: 32,
                child: ImageHelper.stakeholderProfile(
                  imageName: profile.perPhoto,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${profile.perName ?? ''} ${profile.perLastName ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.user?.usrEmail != null)
                    Text(
                      profile.user!.usrEmail!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UsrProfileModel profile) {
    return Container(
      color: _colors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Profile Avatar
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: ImageHelper.stakeholderProfile(
                    imageName: profile.perPhoto,
                    size: 100,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
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
            const SizedBox(height: 12),
            // Profile Name
            Text(
              '${profile.perName ?? ''} ${profile.perLastName ?? ''}'.trim(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _colors.onSurface,
              ),
            ),
            Text(
              profile.user?.usrEmail ?? '',
              style: TextStyle(
                color: _colors.outline,
              ),
            ),

            // Position/Title
            if (profile.employment?.empPosition != null &&
                profile.employment!.empPosition!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  profile.employment?.empPosition ??
                      (profile.employment == null ? 'Not an Employee' : 'No Position'),
                  style: TextStyle(
                    fontSize: 13,
                    color: _colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            SizedBox(height: 15),
             ],

        ),
      ),
    );
  }

  Widget _buildPersonalInfo(UsrProfileModel profile) {
    final tr = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          title: tr.basicInformation,
          children: [
            _buildInfoTile(
              label: tr.fullName,
              value: '${profile.perName ?? ''} ${profile.perLastName ?? ''}'.trim(),
              icon: Icons.person_outline,
            ),
            _buildInfoTile(
              label: tr.gender,
              value: profile.perGender ?? 'Not specified',
              icon: Icons.wc_outlined,
            ),
            _buildInfoTile(
              label: tr.dob,
              value: profile.perDoB != null
                  ? DateFormat('MMMM dd, yyyy').format(profile.perDoB!)
                  : 'Not specified',
              icon: Icons.cake_outlined,
            ),
            _buildInfoTile(
              label: tr.nationalId,
              value: profile.perEnidNo?.isNotEmpty == true
                  ? profile.perEnidNo!
                  : 'Not provided',
              icon: Icons.credit_card_outlined,
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: tr.contactInfo,
          children: [
            _buildInfoTile(
              label: tr.phoneNumber,
              value: profile.perPhone ?? 'Not provided',
              icon: Icons.phone_outlined,
            ),
            _buildInfoTile(
              label: tr.email,
              value: profile.perEmail ?? 'Not provided',
              icon: Icons.email_outlined,
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: tr.address,
          children: [
            _buildInfoTile(
              label: tr.address,
              value: _buildFullAddress(profile.address),
              icon: Icons.home_outlined,
              isMultiLine: true,
            ),

          ],
        ),
      ],
    );
  }

  Widget _buildAccountsInfo(UsrProfileModel profile) {
    if (profile.accounts == null || profile.accounts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: _colors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noAccountFound,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: profile.accounts!.length,
      itemBuilder: (context, index) {
        final account = profile.accounts![index];
        return ZCover(
          radius: 12,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        account.ccyName?.substring(0, 1) ?? '',
                        style: TextStyle(
                          color: _colors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.accName ?? '',
                            style: TextStyle(
                              color: _colors.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '#${account.accNumber ?? 'N/A'}',
                            style: TextStyle(
                              color: _colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: account.accStatus == 'Active'
                            ? _colors.primaryContainer
                            : _colors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        account.accStatus ?? 'Unknown',
                        style: TextStyle(
                          color: account.accStatus == 'Active'
                              ? _colors.primary
                              : _colors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.balance,
                            style: TextStyle(
                              fontSize: 12,
                              color: _colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${account.balance.toAmount()} ${account.actCurrency ?? 'USD'}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.accountLimit,
                            style: TextStyle(
                              fontSize: 12,
                              color: _colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${account.accLimit.toAmount()} ${account.actCurrency ?? 'USD'}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmploymentInfo(UsrProfileModel profile) {
    if (profile.employment == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_off_outlined,
                size: 32,
                color: _colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Not an Employee',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No employment records available',
              style: TextStyle(
                fontSize: 14,
                color: _colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final employment = profile.employment!;
    final tr = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          title: tr.employementDetails,
          children: [
            _buildInfoTile(
              label: tr.department,
              value: employment.empDepartment ?? 'Not specified',
              icon: Icons.business_center_outlined,
            ),
            _buildInfoTile(
              label: tr.positionTitle,
              value: employment.empPosition ?? 'Not specified',
              icon: Icons.work_history_outlined,
            ),
            _buildInfoTile(
              label: tr.hireDate,
              value: employment.empHireDate != null
                  ? DateFormat('MMMM dd, yyyy').format(employment.empHireDate!)
                  : 'Not specified',
              icon: Icons.calendar_today_outlined,
            ),
            _buildInfoTile(
              label: tr.salaryCalculation,
              value: employment.empSalCalcBase ?? 'Not specified',
              icon: Icons.calculate_outlined,
            ),
            _buildInfoTile(
              label: tr.paymentMethod,
              value: employment.empPmntMethod ?? 'Not specified',
              icon: Icons.payment_outlined,
            ),
            _buildInfoTile(
              label: tr.salary,
              value: employment.empSalary ?? '0.00',
              icon: Icons.attach_money_outlined,
            ),
            _buildInfoTile(
              label: tr.status,
              value: employment.empStatus ?? 'Unknown',
              icon: Icons.circle_outlined,
              valueColor: employment.empStatus == 'Hired'
                  ? _colors.primary
                  : _colors.error,
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsInfo(UsrProfileModel profile) {
    final auth = context.read<AuthBloc>().state;
    final hasPasswordPermission = auth is AuthenticatedState && (auth.loginData.hasPermission(65) ?? false);
    final tr = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          title: tr.userSettings,
          children: [
            _buildInfoTile(
              label: tr.username,
              value: profile.user?.usrName ?? 'Not specified',
              icon: Icons.person_outline,
            ),
            _buildInfoTile(
              label: tr.email,
              value: profile.user?.usrEmail ?? 'Not specified',
              icon: Icons.email_outlined,
            ),
            _buildInfoTile(
              label: tr.branchName,
              value: profile.user?.brcName ?? 'Not specified',
              icon: Icons.store_outlined,
            ),
            _buildInfoTile(
              label: tr.branchId,
              value: profile.user?.brcId?.toString() ?? 'Not specified',
              icon: Icons.numbers_outlined,
            ),
            _buildInfoTile(
              label: tr.status,
              value: profile.user?.usrVerify ?? 'Unknown',
              icon: Icons.verified_outlined,
              valueColor: profile.user?.usrVerify == 'verified'
                  ? _colors.primary
                  : _colors.error,
            ),
            _buildInfoTile(
              label: tr.entryDate,
              value: profile.user?.usrEntryDate != null
                  ? DateFormat('MMMM dd, yyyy').format(profile.user!.usrEntryDate!)
                  : 'Not specified',
              icon: Icons.login_outlined,
            ),
            _buildInfoTile(
              label: tr.fcp,
              value: profile.user?.usrFcp?.toString() ?? '0',
              icon: Icons.trending_up_outlined,
              isLast: true,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Security Section
        _buildSection(
          title: tr.securityTitle,
          children: [
            // Change Password
            _buildActionTile(
              icon: Icons.lock_outline,
              iconColor: _colors.primary,
              backgroundColor: _colors.primaryContainer,
              title: tr.changePasswordTitle,
              subtitle: tr.passwordChangeHint,
              onTap: hasPasswordPermission ? () {
                showDialog(
                  context: context,
                  builder: (context) => const PasswordSettingsView(),
                );
              } : null,
            ),

            const SizedBox(height: 8),

            // Logout
            _buildActionTile(
              icon: Icons.logout_rounded,
              iconColor: _colors.error,
              backgroundColor: _colors.errorContainer,
              title: tr.logout,
              subtitle: tr.logoutHint,
              onTap: () => _showLogoutDialog(context),
              showTrailing: false,
            ),
          ],
        ),
      ],
    );
  }

// Helper method for action tiles
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool showTrailing = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _colors.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: _colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showTrailing && onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: _colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

// Logout dialog method
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(OnLogoutEvent());
              },
              style: TextButton.styleFrom(
                foregroundColor: _colors.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return ZCover(
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _colors.primary,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    bool isMultiLine = false,
    Color? valueColor,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
          bottom: BorderSide(
            color: _colors.outlineVariant,
            width: 0.5,
          ),
        )
            : null,
      ),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: _colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: _colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? _colors.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _buildFullAddress(UsrAddress? address) {
    if (address == null) return 'No address provided';

    List<String> parts = [];
    if (address.addName?.isNotEmpty == true) parts.add(address.addName!);
    if (address.addCity?.isNotEmpty == true) parts.add(address.addCity!);
    if (address.addProvince?.isNotEmpty == true) parts.add(address.addProvince!);
    if (address.addCountry?.isNotEmpty == true) parts.add(address.addCountry!);
    if (address.addZipCode?.isNotEmpty == true) parts.add(address.addZipCode!);

    return parts.isNotEmpty ? parts.join(', ') : 'No address provided';
  }
}