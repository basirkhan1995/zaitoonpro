import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import '../../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';

class StorageDropDown extends StatefulWidget {
  final String? title;
  final double height;
  final bool disableAction;
  final ValueChanged<StorageModel?>? onChanged;
  final StorageModel? initiallySelected;
  final int? selectedId; // To track external selection

  const StorageDropDown({
    super.key,
    this.onChanged,
    this.height = 40,
    this.disableAction = false,
    this.title,
    this.initiallySelected,
    this.selectedId,
  });

  @override
  State<StorageDropDown> createState() => _StorageDropDownState();
}

class _StorageDropDownState extends State<StorageDropDown> {
  StorageModel? _selectedItem;

  @override
  void initState() {
    super.initState();
    context.read<StorageBloc>().add(LoadStorageEvent());
    _selectedItem = widget.initiallySelected;
  }

  @override
  void didUpdateWidget(StorageDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When external selectedId becomes null (on clear), reset to "All"
    if (widget.selectedId == null && oldWidget.selectedId != null) {
      _selectedItem = null;
    }
    // When external selectedId changes to a new value, find and select it
    else if (widget.selectedId != null && widget.selectedId != oldWidget.selectedId) {
      final state = context.read<StorageBloc>().state;
      if (state is StorageLoadedState) {
        final found = state.storage.firstWhere(
              (s) => s.stgId == widget.selectedId,
          orElse: () => StorageModel(stgId: -1, stgName: 'Not Found'),
        );
        if (found.stgId != -1) {
          _selectedItem = found;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StorageBloc, StorageState>(
      builder: (context, state) {
        final bool isLoading = state is StorageLoadingState;

        Widget buildTitle() {
          if (isLoading) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title ?? AppLocalizations.of(context)!.storage,
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
            widget.title ?? AppLocalizations.of(context)!.storage,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontSize: 12),
          );
        }

        if (state is StorageErrorState) {
          return Text('Error: ${state.error}');
        }

        // Prepare items list with "All" option
        List<StorageModel> items = [];

        // Add "All" option
        final allOption = StorageModel(
          stgId: null,
          stgName: AppLocalizations.of(context)!.all,
        );
        items.add(allOption);

        // Add actual storage items
        if (state is StorageLoadedState) {
          items.addAll(state.storage);
        }

        // Determine selected item
        // If _selectedItem is null, select "All"
        StorageModel? selectedItem = _selectedItem;
        if (selectedItem == null && items.isNotEmpty) {
          selectedItem = items.firstWhere(
                (item) => item.stgId == null,
            orElse: () => items[0],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZDropdown<StorageModel>(
              disableAction: widget.disableAction,
              title: '',
              height: widget.height,
              items: items,
              multiSelect: false,
              selectedItem: selectedItem,
              itemLabel: (storage) => storage.stgName ?? '',
              initialValue: widget.title ?? AppLocalizations.of(context)!.storage,
              onItemSelected: (storage) {
                setState(() => _selectedItem = storage);
                // Pass null when "All" is selected
                widget.onChanged?.call(storage.stgId == null ? null : storage);
              },
              isLoading: isLoading,
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