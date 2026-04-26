import 'package:flutter/material.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

class ShortcutsView extends StatelessWidget {
  const ShortcutsView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final shortcuts = [
      _ShortcutItem("Ctrl + Shift + R", tr.referenceTransaction),
      _ShortcutItem("Ctrl + Shift + S", tr.accountStatement),
      _ShortcutItem("Ctrl + Shift + G", tr.glStatement),
      _ShortcutItem("F10", tr.cashBalances),
      _ShortcutItem("F11", tr.trialBalance),
      _ShortcutItem("F12", tr.balanceSheet),
      _ShortcutItem("Ctrl + Shift + X", tr.stockRecord),
      _ShortcutItem("Ctrl + Shift + Z", tr.products),
    ];

    return Scaffold(
      appBar: AppBar(
        title:   Text(tr.shortcuts),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: shortcuts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = shortcuts[index];
          return _ShortcutTile(item: item);
        },
      ),
    );
  }
}

class _ShortcutItem {
  final String keys;
  final String description;

  _ShortcutItem(this.keys, this.description);
}

class _ShortcutTile extends StatelessWidget {
  final _ShortcutItem item;

  const _ShortcutTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.keys.split(" + ").map((key) {
                return _KeyCapsule(label: key);
              }).toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              item.description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyCapsule extends StatelessWidget {
  final String label;

  const _KeyCapsule({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}