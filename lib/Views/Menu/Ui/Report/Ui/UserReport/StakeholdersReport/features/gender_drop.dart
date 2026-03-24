import 'package:flutter/material.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../../../Features/Generic/zaitoon_drop.dart';

class GenderModel {
  final String? value;
  final String label;

  GenderModel({this.value, required this.label});
}

class GenderDropdown extends StatefulWidget {
  final Function(String?) onSelected;
  final String title;
  final double? radius;
  final double? height;
  final bool disableAction;
  final bool showAllOption;
  final String? selectedValue;

  const GenderDropdown({
    super.key,
    required this.onSelected,
    this.title = "",
    this.radius,
    this.height,
    this.disableAction = false,
    this.showAllOption = true,
    this.selectedValue,
  });

  @override
  State<GenderDropdown> createState() => _GenderDropdownState();
}

class _GenderDropdownState extends State<GenderDropdown> {
  GenderModel? selectedItem;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialize();
  }

  void _initialize() {
    final t = AppLocalizations.of(context)!;

    List<GenderModel> items = [];

    if (widget.showAllOption) {
      items.add(GenderModel(value: null, label: t.all));
    }

    items.addAll([
      GenderModel(value: "M", label: t.male),
      GenderModel(value: "F", label: t.female),
    ]);

    if (widget.selectedValue != null) {
      selectedItem = items.firstWhere(
            (e) => e.value == widget.selectedValue,
        orElse: () => items.first,
      );
    } else {
      selectedItem = items.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    List<GenderModel> items = [];

    if (widget.showAllOption) {
      items.add(GenderModel(value: null, label: t.all));
    }

    items.addAll([
      GenderModel(value: "M", label: t.male),
      GenderModel(value: "F", label: t.female),
    ]);

    return ZDropdown<GenderModel>(
      disableAction: widget.disableAction,
      height: widget.height ?? 40,
      items: items,
      multiSelect: false,
      selectedItem: selectedItem,
      itemLabel: (g) => g.label,
      initialValue: widget.title,
      radius: widget.radius,
      onItemSelected: (gender) {
        setState(() => selectedItem = gender);
        widget.onSelected(gender.value);
      },
      customTitle: widget.title.isEmpty
          ? null
          : Text(
        widget.title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontSize: 12),
      ),
    );
  }
}