import 'package:flutter/material.dart';
import '../../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';

enum StockMovementType {
  all,
  in_,
  out,
}

extension StockMovementTypeExtension on StockMovementType {
  String getDisplayName(BuildContext context) {
    switch (this) {
      case StockMovementType.all:
        return AppLocalizations.of(context)!.all;
      case StockMovementType.in_:
        return AppLocalizations.of(context)!.inTitle;
      case StockMovementType.out:
        return AppLocalizations.of(context)!.outTitle;
    }
  }

  String? get value {
    switch (this) {
      case StockMovementType.all:
        return null;
      case StockMovementType.in_:
        return 'IN';
      case StockMovementType.out:
        return 'OUT';
    }
  }
}

class StockMovementDropDown extends StatefulWidget {
  final String? title;
  final double height;
  final bool disableAction;
  final ValueChanged<String?>? onChanged; // Returns 'IN', 'OUT', or null for both
  final StockMovementType? initiallySelected;

  const StockMovementDropDown({
    super.key,
    this.onChanged,
    this.height = 40,
    this.disableAction = false,
    this.title,
    this.initiallySelected,
  });

  @override
  State<StockMovementDropDown> createState() => _StockMovementDropDownState();
}

class _StockMovementDropDownState extends State<StockMovementDropDown> {
  StockMovementType? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initiallySelected ?? StockMovementType.all;
  }

  @override
  void didUpdateWidget(StockMovementDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallySelected != oldWidget.initiallySelected) {
      _selectedItem = widget.initiallySelected ?? StockMovementType.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create items list
    final items = StockMovementType.values;

    // Determine selected item
    StockMovementType selectedItem = _selectedItem ?? StockMovementType.all;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZDropdown<StockMovementType>(
          disableAction: widget.disableAction,
          title: '',
          height: widget.height,
          items: items,
          multiSelect: false,
          selectedItem: selectedItem,
          itemLabel: (type) => type.getDisplayName(context),
          initialValue: widget.title ?? AppLocalizations.of(context)!.typeTitle,
          onItemSelected: (type) {
            setState(() => _selectedItem = type);
            // Pass the value: 'IN', 'OUT', or null for both
            widget.onChanged?.call(type.value);
          },
          isLoading: false,
          customTitle: (widget.title != null && widget.title!.isNotEmpty)
              ? Text(
            widget.title!,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontSize: 12),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}