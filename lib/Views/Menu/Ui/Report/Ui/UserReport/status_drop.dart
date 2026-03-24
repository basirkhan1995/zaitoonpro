import 'package:flutter/material.dart';

import '../../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';

class StatusDropdown extends StatelessWidget {
  final int? value;
  final List<StatusItem>? items;
  final ValueChanged<int?> onChanged;
  final double? height;
  final bool disable;

  const StatusDropdown({
    super.key,
    required this.onChanged,
    this.items,
    this.value,
    this.height,
    this.disable = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final dropdownItems = items ?? [
      StatusItem(null, l10n.all),
      StatusItem(1, l10n.active),
      StatusItem(0, l10n.inactive),
    ];

    StatusItem? selectedItem = dropdownItems.firstWhere(
          (e) => e.value == value,
      orElse: () => dropdownItems.first,
    );

    return ZDropdown<StatusItem>(
      title: l10n.status,
      items: dropdownItems,
      selectedItem: selectedItem,
      customTitle: Text(AppLocalizations.of(context)!.status,style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),),
      initialValue: selectedItem.label,
      disableAction: disable,
      itemLabel: (item) => item.label,
      onItemSelected: (item) => onChanged(item.value),
    );
  }
}

class StatusItem {
  final int? value;
  final String label;
  const StatusItem(this.value, this.label);
}