import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/TxnTypes/bloc/txn_types_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/TxnTypes/model/txn_types_model.dart';
import '../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';

class TxnTypeDropDown extends StatefulWidget {
  final String? title;
  final bool isMulti;
  final double height;
  final bool disableAction;

  final ValueChanged<List<TxnTypeModel>> onMultiChanged;
  final ValueChanged<TxnTypeModel?>? onSingleChanged;

  final List<TxnTypeModel>? initiallySelected;
  final TxnTypeModel? initiallySelectedSingle;

  const TxnTypeDropDown({
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
  State<TxnTypeDropDown> createState() => _TxnTypeDropDownState();
}
class _TxnTypeDropDownState extends State<TxnTypeDropDown> {
  List<TxnTypeModel> _selectedMulti = [];
  TxnTypeModel? _selectedSingle;

  @override
  void initState() {
    super.initState();

    context.read<TxnTypesBloc>().add(LoadTxnTypesEvent());

    if (widget.isMulti) {
      _selectedMulti = widget.initiallySelected ?? [];
    } else {
      _selectedSingle = widget.initiallySelectedSingle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TxnTypesBloc, TxnTypesState>(
      builder: (context, state) {
        final bool isLoading = state is TxnTypeLoadingState;

        Widget buildTitle() {
          if (isLoading) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title ?? AppLocalizations.of(context)!.users,
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
          return Text(
            widget.title ?? AppLocalizations.of(context)!.users,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontSize: 12),
          );
        }

        if (state is TxnTypeErrorState) {
          return Text('Error: ${state.message}');
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZDropdown<TxnTypeModel>(
              disableAction: widget.disableAction,
              title: '',
              height: widget.height,
              items: state is TxnTypesLoadedState ? state.types : [],
              multiSelect: widget.isMulti,
              selectedItems: widget.isMulti ? _selectedMulti : [],
              selectedItem: widget.isMulti ? null : _selectedSingle,
              itemLabel: (user) => user.trntCode ?? '',
              initialValue:
              widget.title ?? AppLocalizations.of(context)!.users,
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
              isLoading: false,
              customTitle: (widget.title != null && widget.title!.isNotEmpty)
                  ? buildTitle()
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
