import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../bloc/users_bloc.dart';
import '../model/user_model.dart';

class UserDropdown extends StatefulWidget {
  final String? title;
  final bool isMulti;
  final double height;
  final bool disableAction;

  final ValueChanged<List<UsersModel>> onMultiChanged;
  final ValueChanged<UsersModel?>? onSingleChanged;

  final List<UsersModel>? initiallySelected;
  final UsersModel? initiallySelectedSingle;

  const UserDropdown({
    super.key,
    required this.isMulti,
    required this.onMultiChanged,
    this.onSingleChanged,
    this.height = 40,
    this.disableAction = false,
    this.title,
    this.initiallySelected,
    this.initiallySelectedSingle,
  });

  @override
  State<UserDropdown> createState() => _UserDropdownState();
}
class _UserDropdownState extends State<UserDropdown> {
  List<UsersModel> _selectedMulti = [];
  UsersModel? _selectedSingle;

  @override
  void initState() {
    super.initState();

    context.read<UsersBloc>().add(
      LoadUsersEvent(),
    );

    if (widget.isMulti) {
      _selectedMulti = widget.initiallySelected ?? [];
    } else {
      _selectedSingle = widget.initiallySelectedSingle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final bool isLoading = state is UsersLoadingState;

        if (state is UsersErrorState) {
          return Text('Error: ${state.message}');
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZDropdown<UsersModel>(
              disableAction: widget.disableAction,
              title: AppLocalizations.of(context)!.users,
              height: widget.height,
              items: state is UsersLoadedState ? state.users : [],
              multiSelect: widget.isMulti,
              selectedItems: widget.isMulti ? _selectedMulti : [],
              selectedItem: widget.isMulti ? null : _selectedSingle,
              itemLabel: (user) => user.usrName ?? '',
              initialValue: widget.title ?? AppLocalizations.of(context)!.users,

              onMultiSelectChanged: widget.isMulti
                  ? (selected) {
                setState(() => _selectedMulti = selected);
                widget.onMultiChanged(selected);
              } : null,

              onItemSelected: widget.isMulti
                  ? (_) {}
                  : (user) {
                setState(() => _selectedSingle = user);
                widget.onSingleChanged?.call(user);
              },

              isLoading: isLoading,

            ),
          ],
        );
      },
    );
  }
}
