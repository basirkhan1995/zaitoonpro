import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/total_daily_bloc.dart';

class TotalDailyTxnView extends StatelessWidget {
  final String? fromDate;
  final String? toDate;
  const TotalDailyTxnView({super.key,this.fromDate,this.toDate});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(), desktop: _Desktop(fromDate, toDate),tablet: _Tablet(),);
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}


class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}


class _Desktop extends StatefulWidget {
  final String? fromDate;
  final String? toDate;

  const _Desktop(this.fromDate, this.toDate);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  String fromDate = DateTime.now().toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TotalDailyBloc>().add(
        LoadTotalDailyEvent(
          fromDate: widget.fromDate ?? fromDate,
         toDate:  widget.toDate ?? toDate,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TotalDailyBloc, TotalDailyState>(
      builder: (context, state) {
        if (state is TotalDailyError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (state is TotalDailyLoaded) {
          final data = state.data;

          if (data.isEmpty) {
            return const Center(child: SizedBox());
          }

          return Wrap(
            spacing: 6,
            runSpacing: 10,
            children: data.map((item) {
              // Use percentage only, no isNew
              final percentText = "${item.percentage.toStringAsFixed(1)} %";
              final percentColor = item.isIncrease ? Colors.green : Colors.red;
              final icon = item.isIncrease ? Icons.trending_up : Icons.trending_down;

              return Container(
                width: 190,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: .15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TXN NAME
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.today.txnName ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.outline.withValues(alpha: .5),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // AMOUNT
                    Text(
                      item.today.totalAmount.toAmount(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // PERCENTAGE + ICON + COUNT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: percentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              percentText,
                              style: TextStyle(
                                color: percentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${item.today.totalCount}',
                          style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.outline.withValues(alpha: .5)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}





