import 'package:flutter/material.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

/// ===============================
/// 1️⃣ Transaction Status Enum
/// ===============================
enum TransactionStatus {
  deleted,
  pending,
  authorized,
  reversed,
}

/// ===============================
/// 2️⃣ API String → Enum Mapper
/// ===============================
TransactionStatus transactionStatusFromApi(String? value) {
  switch (value?.toLowerCase()) {
    case 'deleted':
      return TransactionStatus.deleted;
    case 'authorized':
      return TransactionStatus.authorized;
    case 'reversed':
      return TransactionStatus.reversed;
    case 'pending':
    default:
      return TransactionStatus.pending;
  }
}

/// ===============================
/// 3️⃣ Status Config Model
/// ===============================
class TransactionStatusConfig {
  final Color bgColor;
  final Color textColor;
  final IconData icon;
  final String title;

  const TransactionStatusConfig({
    required this.bgColor,
    required this.textColor,
    required this.icon,
    required this.title,
  });

  static TransactionStatusConfig fromStatus(
      TransactionStatus status,
      AppLocalizations tr,
      ) {
    switch (status) {
      case TransactionStatus.deleted:
        return TransactionStatusConfig(
          bgColor: const Color(0xFFFDECEA),
          textColor: const Color(0xFFD32F2F),
          icon: Icons.delete_rounded,
          title: tr.deletedTitle,
        );

      case TransactionStatus.pending:
        return TransactionStatusConfig(
          bgColor: const Color(0xFFFFF8E1),
          textColor: const Color(0xFFF9A825),
          icon: Icons.schedule_rounded,
          title: tr.pendingTitle,
        );

      case TransactionStatus.authorized:
        return TransactionStatusConfig(
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
          title: tr.authorizedTitle,
        );

      case TransactionStatus.reversed:
        return TransactionStatusConfig(
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFEF6C00),
          icon: Icons.undo_rounded,
          title: tr.reversedTitle,
        );
    }
  }
}

/// ===============================
/// 4️⃣ Transaction Status Badge UI
/// ===============================
class TransactionStatusBadge extends StatelessWidget {
  /// API value like: "Deleted", "Pending", "Authorized", "Reversed"
  final String status;
  final bool enableLabel;

  const TransactionStatusBadge({
    super.key,
    required this.status,
    this.enableLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    final TransactionStatus enumStatus =
    transactionStatusFromApi(status);

    final config =
    TransactionStatusConfig.fromStatus(enumStatus, tr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: config.textColor.withValues(alpha: .4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 14,
            color: config.textColor,
          ),
          if(enableLabel)...[
            const SizedBox(width: 6),
            Text(
              config.title,
              style: TextStyle(
                color: config.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
