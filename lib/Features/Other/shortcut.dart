import 'package:flutter/material.dart';


class GlobalShortcuts extends StatelessWidget {
  final Map<ShortcutActivator, VoidCallback> shortcuts;
  final Widget child;

  const GlobalShortcuts({
    super.key,
    required this.shortcuts,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final shortcutMap = <ShortcutActivator, Intent>{};

    for (final entry in shortcuts.entries) {
      shortcutMap[entry.key] = _GlobalIntent(entry.value);
    }

    return Shortcuts(
      shortcuts: shortcutMap,
      child: Actions(
        actions: {
          _GlobalIntent: CallbackAction<_GlobalIntent>(
            onInvoke: (intent) {
              intent.callback();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _GlobalIntent extends Intent {
  final VoidCallback callback;

  const _GlobalIntent(this.callback);
}
