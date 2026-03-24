import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../bloc/user_role_bloc.dart';
import '../model/role_model.dart';

class UserRoleDropdown extends StatefulWidget {
  final Function(UserRoleModel?) onRoleSelected;
  final String title;
  final double? radius;
  final double? height;
  final bool disableAction;
  final int? selectedId;
  final bool showAllOption;

  const UserRoleDropdown({
    super.key,
    required this.onRoleSelected,
    this.title = "",
    this.radius,
    this.height,
    this.disableAction = false,
    this.selectedId,
    this.showAllOption = false,
  });

  @override
  State<UserRoleDropdown> createState() => _UserRoleDropdownState();
}

class _UserRoleDropdownState extends State<UserRoleDropdown> {
  UserRoleModel? _selectedItem;
  bool _hasInitializedSelection = false;

  @override
  void initState() {
    super.initState();
    // Load roles if not already loaded
    final bloc = context.read<UserRoleBloc>();
    final state = bloc.state;
    if (state is! UserRoleLoadedState) {
      bloc.add(LoadUserRolesEvent());
    }
  }

  @override
  void didUpdateWidget(UserRoleDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset initialization flag when selectedId changes
    if (widget.selectedId != oldWidget.selectedId) {
      _hasInitializedSelection = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserRoleBloc, UserRoleState>(
      builder: (context, state) {
        final bool isLoading = state is UserRoleLoadingState;

        if (state is UserRoleErrorState) {
          return Text('Error: ${state.message}');
        }

        // Prepare items list
        List<UserRoleModel> items = [];

        // Add "All" option only if showAllOption is true
        if (widget.showAllOption) {
          final allOption = UserRoleModel(
            rolId: null,
            rolName: AppLocalizations.of(context)!.all,
          );
          items.add(allOption);
        }

        // Add actual role items
        if (state is UserRoleLoadedState) {
          // Sort roles by rolId or rolName for consistent display
          final sortedRoles = List<UserRoleModel>.from(state.roles)
            ..sort((a, b) => (a.rolName ?? '').compareTo(b.rolName ?? ''));

          items.addAll(sortedRoles);

          // Initialize selection only once when data is loaded
          if (!_hasInitializedSelection && items.isNotEmpty) {
            _hasInitializedSelection = true;

            UserRoleModel? newSelectedItem;

            // First priority: selectedId from parent
            if (widget.selectedId != null) {
              newSelectedItem = state.roles.firstWhere(
                    (role) => role.rolId == widget.selectedId,
                orElse: () => UserRoleModel(rolId: -1),
              );

              if (newSelectedItem.rolId == -1) {
                newSelectedItem = null;
              }
            }

            // Second priority: "All" option if showAllOption is true
            if (newSelectedItem == null && widget.showAllOption) {
              newSelectedItem = items.firstWhere(
                    (item) => item.rolId == null,
                orElse: () => items[0],
              );
            }

            // Third priority: first role
            newSelectedItem ??= items.isNotEmpty ? items[0] : null;

            if (newSelectedItem != _selectedItem) {
              // Use post frame callback to avoid build issues
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedItem = newSelectedItem;
                  });
                }
              });
            }
          }
        }

        return ZDropdown<UserRoleModel>(
          disableAction: widget.disableAction || isLoading,
          height: widget.height ?? 40,
          items: items,
          multiSelect: false,
          selectedItem: _selectedItem,
          itemLabel: (role) => role.rolName ?? '',
          initialValue: widget.title,
          onItemSelected: (role) {
            setState(() => _selectedItem = role);
            // Pass null when "All" is selected and showAllOption is true
            if (widget.showAllOption && role.rolId == null) {
              widget.onRoleSelected(null);
            } else {
              widget.onRoleSelected(role);
            }
          },
          isLoading: isLoading,
          customTitle: _buildTitle(context, isLoading),
          radius: widget.radius,
        );
      },
    );
  }

  // Helper method to build title with loading indicator
  Widget? _buildTitle(BuildContext context, bool isLoading) {
    // If loading, always show loading indicator (with or without title)
    if (isLoading) {
      // If title is empty, show only the loading indicator
      if (widget.title.isEmpty) {
        return const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      // If title is not empty, show title with loading indicator
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontSize: 12),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }

    // If not loading and title is empty, return null (no custom title)
    if (widget.title.isEmpty) {
      return null;
    }

    // If not loading and title is not empty, show title text
    return Text(
      widget.title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
    );
  }
}