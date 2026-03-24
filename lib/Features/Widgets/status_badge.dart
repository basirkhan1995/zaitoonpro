import 'package:flutter/material.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
class StatusBadge extends StatelessWidget {
  final int status;
  final String? trueValue;
  final String? falseValue;

  const StatusBadge({
    super.key,
    required this.status,
     this.trueValue,
     this.falseValue
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final bool isCompleted = status == 1;

    final Color bgColor =
    isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    final Color textColor =
    isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00);

    final IconData icon =
    isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: textColor.withValues(alpha: .4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            isCompleted ? trueValue ?? tr.completedTitle : falseValue ?? tr.pendingTitle,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}