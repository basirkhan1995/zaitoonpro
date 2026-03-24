import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:zaitoonpro/Features/Widgets/zcard_mobile.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

import '../Other/image_helper.dart';

/// Mobile-optimized card for displaying account information
class MobileAccountCard extends StatelessWidget {
  final String? bankLogoUrl;
  final String accountName;
  final String accountNumber;
  final String currencyCode;
  final MobileStatus? status;
  final double availableBalance;
  final double currentBalance;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? accentColor;
  final bool showActions;
  final bool showBalanceDetails;
  final String? actionLabel;

  const MobileAccountCard({
    super.key,
    this.bankLogoUrl,
    required this.accountName,
    required this.accountNumber,
    required this.currencyCode,
    this.status,
    required this.availableBalance,
    required this.currentBalance,
    this.onTap,
    this.onLongPress,
    this.accentColor,
    this.showActions = false,
    this.showBalanceDetails = true,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final accent = accentColor ?? color.primary;

    // Check if balances are equal
    final bool balancesAreEqual = (availableBalance - currentBalance).abs() < 0.01;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 2,
      shadowColor: color.shadow.withValues(alpha: .1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: color.outline.withValues(alpha: .05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Bank Logo and Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank Logo Section with Gradient Background
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: .2),
                          accent.withValues(alpha: .05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: accent.withValues(alpha: .2),
                        width: 1,
                      ),
                    ),
                    child: bankLogoUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ImageHelper.stakeholderProfile(
                        imageName: bankLogoUrl,
                        size: 50,
                      ),
                    )
                        : Icon(
                      FontAwesomeIcons.buildingColumns,
                      size: 24,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Account Name and Number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Currency Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currencyCode,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Account Number with masking (showing last 4 digits)
                            Expanded(
                              child: Text(
                                _formatAccountNumber(accountNumber),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: color.onSurface.withValues(alpha: .7),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Badge with enhanced design
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status!.backgroundColor ??
                            status!.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: status!.color.withValues(alpha: .3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: status!.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status!.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: status!.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // Balance Information
              if (showBalanceDetails) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerHighest.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: accent.withValues(alpha: .1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Available Balance (always shown)
                      _buildBalanceRow(
                        context,
                        label: AppLocalizations.of(context)!.availableBalance,
                        amount: availableBalance,
                        currencyCode: currencyCode,
                        isMainBalance: true,
                      ),

                      // Show current balance only if different from available
                      if (!balancesAreEqual) ...[
                        const SizedBox(height: 4),

                        // Divider
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: color.outline.withValues(alpha: .1),
                        ),

                        const SizedBox(height: 4),

                        // Current Balance (Unauthorized)
                        _buildBalanceRow(
                          context,
                          label: AppLocalizations.of(context)!.currentBalance,
                          amount: currentBalance,
                          currencyCode: currencyCode,
                          isMainBalance: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Action Buttons (only if explicitly enabled)
              if (showActions && onTap != null) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: onTap,
                        icon: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: accent,
                        ),
                        label: Text(
                          actionLabel ?? 'View Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceRow(
      BuildContext context, {
        required String label,
        required double amount,
        required String currencyCode,
        required bool isMainBalance,
      }) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurface.withValues(alpha: .6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(amount, currencyCode),
              style: isMainBalance
                  ? theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color.primary,
                fontSize: 15,
              )
                  : theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: color.onSurface.withValues(alpha: .8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.length >= 4) {
      // Show last 4 digits only with dots prefix
      return '•••• ${accountNumber.substring(accountNumber.length - 4)}';
    }
    return accountNumber;
  }

  String _formatCurrency(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _getCurrencySymbol(String currencyCode) {
    // Map common currency codes to symbols
    const symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CHF': 'Fr',
      'HKD': 'HK\$',
      'SGD': 'S\$',
      'KRW': '₩',
      'AFN': '؋', // Afghani symbol
    };
    return symbols[currencyCode] ?? currencyCode;
  }
}