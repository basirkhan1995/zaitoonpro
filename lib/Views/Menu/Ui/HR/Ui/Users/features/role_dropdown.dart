// import 'package:flutter/material.dart';
// import '../../../../../../../Features/Generic/zaitoon_drop.dart';
// import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
//
// enum UserRole {
//   ceo,
//   manager,
//   deputy,
//   admin,
//   authorizer,
//   cashier,
//   officer,
//   customerService,
//   customer;
//
//   String toDatabaseValue() {
//     switch (this) {
//       case UserRole.ceo: return 'ceo';
//       case UserRole.manager: return 'manager';
//       case UserRole.deputy: return 'deputy';
//       case UserRole.admin: return 'admin';
//       case UserRole.authorizer: return 'authorizer';
//       case UserRole.cashier: return 'cashier';
//       case UserRole.officer: return 'officer';
//       case UserRole.customerService: return 'customer service';
//       case UserRole.customer: return 'customer';
//     }
//   }
//
//   static UserRole? fromDatabaseValue(String? value) {
//     if (value == null) return null;
//
//     switch (value.toLowerCase().trim()) {
//       case 'ceo': return UserRole.ceo;
//       case 'manager': return UserRole.manager;
//       case 'deputy': return UserRole.deputy;
//       case 'admin': return UserRole.admin;
//       case 'authorizer': return UserRole.authorizer;
//       case 'cashier': return UserRole.cashier;
//       case 'officer': return UserRole.officer;
//       case 'customer service': return UserRole.customerService;
//       case 'customer': return UserRole.customer;
//       default: return null;
//     }
//   }
//
// }
//
// // Extension to add an "All" pseudo-role
// extension UserRoleAllExtension on UserRole {
//   static const String allDatabaseValue = '__ALL__';
//
//   static bool isAllValue(String? value) {
//     return value == allDatabaseValue;
//   }
// }
//
// class RoleTranslator {
//   static String getTranslatedRole(BuildContext context, UserRole? role) {
//     if (role == null) {
//       return AppLocalizations.of(context)!.all;
//     }
//
//     final localizations = AppLocalizations.of(context)!;
//
//     switch (role) {
//       case UserRole.ceo: return localizations.ceo;
//       case UserRole.manager: return localizations.manager;
//       case UserRole.deputy: return localizations.deputy;
//       case UserRole.admin: return localizations.admin;
//       case UserRole.authorizer: return localizations.authoriser;
//       case UserRole.cashier: return localizations.cashier;
//       case UserRole.officer: return localizations.officer;
//       case UserRole.customerService: return localizations.customerService;
//       case UserRole.customer: return localizations.customer;
//     }
//   }
//
//   static String getTranslatedRoleFromDatabaseValue(BuildContext context, String? databaseValue) {
//     if (databaseValue == null || UserRoleAllExtension.isAllValue(databaseValue)) {
//       return AppLocalizations.of(context)!.all;
//     }
//
//     final role = UserRole.fromDatabaseValue(databaseValue);
//     return getTranslatedRole(context, role);
//   }
//
//   // Get all roles as translated list for dropdown, optionally with "All" option
//   static List<Map<String, dynamic>> getTranslatedRoleList(BuildContext context, {bool includeAllOption = false}) {
//     List<Map<String, dynamic>> roles = [];
//
//     if (includeAllOption) {
//       roles.add({
//         'role': null, // null represents "All"
//         'translatedName': AppLocalizations.of(context)!.all,
//         'databaseValue': UserRoleAllExtension.allDatabaseValue,
//       });
//     }
//
//     roles.addAll(
//         UserRole.values.map((role) {
//           return {
//             'role': role,
//             'translatedName': getTranslatedRole(context, role),
//             'databaseValue': role.toDatabaseValue(),
//           };
//         }).toList()
//     );
//
//     return roles;
//   }
// }
//
// class UserRoleDropdown extends StatefulWidget {
//   /// Optional: pass the selected role as UserRole OR as database string
//   final UserRole? selectedRole;
//   final String? selectedDatabaseValue;
//   final Function(UserRole?) onRoleSelected; // Changed to nullable
//   final bool showAllOption; // New parameter
//   final String? title;
//
//   const UserRoleDropdown({
//     super.key,
//     this.selectedRole,
//     this.selectedDatabaseValue,
//     required this.onRoleSelected,
//     this.showAllOption = false, // Default to false
//     this.title,
//   });
//
//   @override
//   State<UserRoleDropdown> createState() => _UserRoleDropdownState();
// }
//
// class _UserRoleDropdownState extends State<UserRoleDropdown> {
//   late UserRole? _selectedRole;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Determine the initial selected role
//     if (widget.selectedRole != null) {
//       _selectedRole = widget.selectedRole;
//     } else if (widget.selectedDatabaseValue != null) {
//       if (UserRoleAllExtension.isAllValue(widget.selectedDatabaseValue)) {
//         _selectedRole = null; // null represents "All"
//       } else {
//         _selectedRole = UserRole.fromDatabaseValue(widget.selectedDatabaseValue!);
//       }
//     } else {
//       // Default to first role or "All" if showAllOption is true
//       _selectedRole = widget.showAllOption ? null : UserRole.values.first;
//     }
//
//     // Notify parent about initial selection
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       widget.onRoleSelected(_selectedRole);
//     });
//   }
//
//   @override
//   void didUpdateWidget(covariant UserRoleDropdown oldWidget) {
//     super.didUpdateWidget(oldWidget);
//
//     UserRole? newRole;
//
//     if (widget.selectedRole != null) {
//       newRole = widget.selectedRole;
//     } else if (widget.selectedDatabaseValue != null) {
//       if (UserRoleAllExtension.isAllValue(widget.selectedDatabaseValue)) {
//         newRole = null;
//       } else {
//         newRole = UserRole.fromDatabaseValue(widget.selectedDatabaseValue!);
//       }
//     }
//
//     if (newRole != _selectedRole) {
//       setState(() => _selectedRole = newRole);
//     }
//   }
//
//   void _handleRoleSelected(UserRole? role) {
//     setState(() {
//       _selectedRole = role;
//     });
//     widget.onRoleSelected(role);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Prepare items list
//     final List<UserRole?> items = widget.showAllOption
//         ? [null, ...UserRole.values] // null represents "All"
//         : UserRole.values;
//
//     // Ensure _selectedRole is in the items list
//     UserRole? selectedItem = _selectedRole;
//     if (selectedItem != null && !items.contains(selectedItem)) {
//       // If selected role is not in items (shouldn't happen), default appropriately
//       selectedItem = widget.showAllOption ? null : items.firstWhere(
//             (item) => item != null,
//         orElse: () => null,
//       );
//     }
//
//     return ZDropdown<UserRole?>(
//       title: widget.title ?? AppLocalizations.of(context)!.selectRole,
//       items: items,
//       itemLabel: (role) => RoleTranslator.getTranslatedRole(context, role),
//       selectedItem: selectedItem,
//       onItemSelected: _handleRoleSelected,
//       leadingBuilder: (role) => _getRoleIcon(role),
//       // Ensure we have a proper initial value to display
//       initialValue: selectedItem != null
//           ? RoleTranslator.getTranslatedRole(context, selectedItem)
//           : (widget.showAllOption
//           ? AppLocalizations.of(context)!.all
//           : RoleTranslator.getTranslatedRole(context, UserRole.values.first)),
//     );
//   }
//
//   Widget _getRoleIcon(UserRole? role) {
//     if (role == null) {
//       // Icon for "All" option
//       return const Icon(Icons.all_inclusive_rounded, size: 20);
//     }
//
//     final icon = switch (role) {
//       UserRole.ceo => Icons.business_center_outlined,
//       UserRole.manager => Icons.manage_accounts_rounded,
//       UserRole.deputy => Icons.assistant_rounded,
//       UserRole.admin => Icons.admin_panel_settings_rounded,
//       UserRole.authorizer => Icons.verified_user_rounded,
//       UserRole.cashier => Icons.monetization_on_rounded,
//       UserRole.officer => Icons.security_rounded,
//       UserRole.customerService => Icons.support_agent_rounded,
//       UserRole.customer => Icons.person_rounded,
//     };
//
//     return Icon(icon, size: 20);
//   }
// }