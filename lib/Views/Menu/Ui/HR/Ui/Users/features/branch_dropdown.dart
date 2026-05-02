import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

import '../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../Settings/Ui/Company/Branches/bloc/branch_bloc.dart';
import '../../../../Settings/Ui/Company/Branches/model/branch_model.dart';

class BranchDropdown extends StatefulWidget {
  final Function(BranchModel?) onBranchSelected;
  final String title;
  final double? radius;
  final double? height;
  final bool disableAction;
  final int? selectedId;
  final bool showAllOption;

  const BranchDropdown({
    super.key,
    required this.onBranchSelected,
    this.title = "",
    this.radius,
    this.height,
    this.disableAction = false,
    this.selectedId,
    this.showAllOption = false,
  });

  @override
  State<BranchDropdown> createState() => _BranchDropdownState();
}

class _BranchDropdownState extends State<BranchDropdown> {
  BranchModel? _selectedItem;
  bool _hasInitializedSelection = false;

  @override
  void initState() {
    super.initState();
    // Load branches if not already loaded
    final bloc = context.read<BranchBloc>();
    final state = bloc.state;
    if (state is! BranchLoadedState) {
      bloc.add(LoadBranchesEvent());
    }
  }

  @override
  void didUpdateWidget(BranchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset initialization flag when selectedId changes
    if (widget.selectedId != oldWidget.selectedId) {
      _hasInitializedSelection = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BranchBloc, BranchState>(
      builder: (context, state) {
        final bool isLoading = state is BranchLoadingState;

        if (state is BranchErrorState) {
          return Text('Error: ${state.message}');
        }

        // Prepare items list
        List<BranchModel> items = [];

        // Add "All" option only if showAllOption is true
        if (widget.showAllOption) {
          final allOption = BranchModel(
            brcId: null,
            brcName: AppLocalizations.of(context)!.all,
          );
          items.add(allOption);
        }

        // Add actual branch items
        if (state is BranchLoadedState) {
          items.addAll(state.branches);

          // Initialize selection only once when data is loaded
          if (!_hasInitializedSelection && items.isNotEmpty) {
            _hasInitializedSelection = true;

            BranchModel? newSelectedItem;

            // First priority: selectedId from parent
            if (widget.selectedId != null) {
              newSelectedItem = state.branches.firstWhere(
                    (branch) => branch.brcId == widget.selectedId,
                orElse: () => BranchModel(brcId: -1),
              );

              if (newSelectedItem.brcId == -1) {
                newSelectedItem = null;
              }
            }

            // Second priority: "All" option if showAllOption is true
            if (newSelectedItem == null && widget.showAllOption) {
              newSelectedItem = items.firstWhere(
                    (item) => item.brcId == null,
                orElse: () => items[0],
              );
            }

            // Third priority: first branch
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

        return ZDropdown<BranchModel>(
          disableAction: widget.disableAction || isLoading,
          height: widget.height ?? 40,
          items: items,
          multiSelect: false,
          selectedItem: _selectedItem,
          itemLabel: (branch) => branch.brcName ?? '',
          title: widget.title,
          initialValue: widget.title,
          onItemSelected: (branch) {
            setState(() => _selectedItem = branch);
            // Pass null when "All" is selected and showAllOption is true
            if (widget.showAllOption && branch.brcId == null) {
              widget.onBranchSelected(null);
            } else {
              widget.onBranchSelected(branch);
            }
          },
          isLoading: isLoading,
          radius: widget.radius,
        );
      },
    );
  }

}