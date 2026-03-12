import 'package:flutter/material.dart';
import '../../../../../../../../Features/Other/extensions.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../model/cardx_model.dart';

class StockMovementSummary extends StatelessWidget {
  final List<StockRecordModel> records;
  final String baseCurrency;

  const StockMovementSummary({
    super.key,
    required this.records,
    required this.baseCurrency,
  });

  // Calculate totals
  Map<String, double> _calculateTotals() {
    double totalIn = 0;
    double totalOut = 0;

    for (var record in records) {
      final quantity = double.tryParse(record.quantity ?? '0') ?? 0;
      if (record.entryType == 'IN') {
        totalIn += quantity;
      } else if (record.entryType == 'OUT') {
        totalOut += quantity;
      }
    }

    return {
      'in': totalIn,
      'out': totalOut,
    };
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.surface,
        border: Border(
          top: BorderSide(color: color.outline.withValues(alpha: 0.2)),
          bottom: BorderSide(color: color.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryItem(
            label: tr.totalIn,
            value: totals['in']!,
            currency: baseCurrency,
            color: Colors.green,
          ),
          Container(
            height: 30,
            width: 1,
            color: color.outline.withValues(alpha: 0.2),
          ),
          _SummaryItem(
            label: tr.totalOut,
            value: totals['out']!,
            currency: baseCurrency,
            color: color.error,
          ),
          Container(
            height: 30,
            width: 1,
            color: color.outline.withValues(alpha: 0.2),
          ),
          _SummaryItem(
            label: tr.balance,
            value: totals['in']! - totals['out']!,
            currency: baseCurrency,
            color: color.primary,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final Color color;
  final bool isBold;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toAmount(decimal: 4),
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}