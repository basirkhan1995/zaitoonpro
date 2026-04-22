import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';

class AmountDisplay extends StatelessWidget {
  final String? title;

  final double baseAmount;
  final String baseCurrency;

  final double? convertedAmount;
  final String? convertedCurrency;

  /// 🔹 Optional sign prefix (+ or -)
  final bool showSign;
  final bool isPositive; // true for +, false for -

  /// 🔹 Optional styling
  final Color? baseColor;
  final Color? convertedColor;
  final double fontSize;
  final Color? signColor;

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
    this.showSign = false,
    this.isPositive = true,
    this.signColor,
  });

  String _getFormattedAmountWithSign(double amount) {
    final formattedAmount = amount.toAmount();
    if (!showSign) return formattedAmount;

    final sign = isPositive ? '+' : '-';
    return '$sign$formattedAmount';
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    final hasConversion =
        convertedAmount != null && convertedAmount! > 0;

    final baseTextColor = baseColor ?? color.onSurface;
    final convertedTextColor = convertedColor ?? color.outline;
    final effectiveSignColor = signColor ??
        (isPositive ? Colors.green : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 🔹 Title
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: fontSize,
                color: color.onSurface,
              ),
            ),

          /// 🔹 Values
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    if (showSign)
                      TextSpan(
                        text: _getFormattedAmountWithSign(baseAmount),
                        style: TextStyle(
                          color: effectiveSignColor,
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                      )
                    else
                      TextSpan(
                        text: _getFormattedAmountWithSign(baseAmount),
                        style: TextStyle(
                          color: baseTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                      ),
                    TextSpan(
                      text: ' $baseCurrency',
                      style: TextStyle(
                        color: baseTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
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

                RichText(
                  text: TextSpan(
                    children: [
                      if (showSign)
                        TextSpan(
                          text: _getFormattedAmountWithSign(convertedAmount!),
                          style: TextStyle(
                            color: effectiveSignColor,
                            fontSize: fontSize,
                          ),
                        )
                      else
                        TextSpan(
                          text: _getFormattedAmountWithSign(convertedAmount!),
                          style: TextStyle(
                            color: convertedTextColor,
                            fontSize: fontSize,
                          ),
                        ),
                      TextSpan(
                        text: ' $convertedCurrency',
                        style: TextStyle(
                          color: convertedTextColor,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
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