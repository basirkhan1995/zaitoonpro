import 'package:flutter/material.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';
import '../Widgets/button.dart';
import '../Widgets/outline_button.dart';

class ZAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onYes;
  final IconData? icon;
  final Widget? child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ZAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onYes,
    this.padding,
    this.margin,
    this.width,
    this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 0,vertical: 0),
      child: Container(
        margin: margin ?? EdgeInsets.zero,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 10,vertical: 0),
        width: width ?? 380,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: theme.primary),
                    const SizedBox(width: 8), // Adds spacing between the icon and title
                  ],
                  Row(
                    spacing: 8,
                    children: [
                      Icon(Icons.warning_amber_rounded,color: Theme.of(context).colorScheme.error,),
                      Text(
                          title,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if(content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5),
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              child: child,
            ),

            _buildAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ZButton(
                height: 40,
                width: 100,
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog first
                  onYes(); // Then trigger the callback
                },
                label: Text(AppLocalizations.of(context)!.yes),
              ),
              const SizedBox(width: 7),
              ZOutlineButton(
                height: 40,
                width: 100,
                backgroundHover: color.error,
                onPressed: () => Navigator.of(context).pop(),
                label: Text(AppLocalizations.of(context)!.ignore),
              ),
            ],
          ),
        ],
      ),
    );
  }
}