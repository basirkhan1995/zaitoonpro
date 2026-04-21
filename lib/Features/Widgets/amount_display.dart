import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';

class AmountDisplay extends StatelessWidget {
  final String? title;

  final double baseAmount;
  final String baseCurrency;

  final double? convertedAmount;
  final String? convertedCurrency;

  /// 🔹 Optional styling
  final Color? baseColor;
  final Color? convertedColor;
  final double fontSize;

  const AmountDisplay({
    super.key,
    this.title,
    required this.baseAmount,
    required this.baseCurrency,
    this.convertedAmount,
    this.convertedCurrency,
    this.baseColor,
    this.convertedColor,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    final hasConversion =
        convertedAmount != null && convertedAmount! > 0;

    final baseTextColor = baseColor ?? color.primary;
    final convertedTextColor = convertedColor ?? color.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 🔹 Title
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: fontSize,
                color: color.outline,
              ),
            ),

          /// 🔹 Values
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${baseAmount.toAmount()} $baseCurrency",
                style: TextStyle(
                  color: baseTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),

              if (hasConversion) ...[
                const SizedBox(width: 6),

                Icon(
                  Icons.swap_horiz,
                  size: fontSize + 2,
                  color: color.outline,
                ),

                const SizedBox(width: 6),

                Text(
                  "${convertedAmount!.toAmount()} $convertedCurrency",
                  style: TextStyle(
                    color: convertedTextColor,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}