import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'bloc/project_stats_bloc.dart';

class ProjectStatsView extends StatelessWidget {
  const ProjectStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

/* ------------------ RESPONSIVE WRAPPERS ------------------ */

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(8),
    child: _StatsContent(),
  );
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(8),
    child: _StatsContent(),
  );
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectStatsBloc>().add(FetchProjectStatsEvent());
    });
  }

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    child: _StatsContent(),
  );
}

/* ------------------ MAIN CONTENT ------------------ */

class _StatsContent extends StatefulWidget {
  const _StatsContent();

  @override
  State<_StatsContent> createState() => _StatsContentState();
}

class _StatsContentState extends State<_StatsContent> {
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<ProjectStatsBloc, ProjectStatsState>(
      builder: (context, state) {
        // ✅ Show loading skeleton only on FIRST load
        if (_isFirstLoad && state is! ProjectStatsLoaded) {
          return _buildLoadingSkeleton(context, theme);
        }

        // ✅ ERROR: Just show nothing
        if (state is ProjectStatsError) {
          _isFirstLoad = false;
          return const SizedBox.shrink();
        }

        if (state is ProjectStatsLoaded) {
          // ✅ Mark first load as complete
          if (_isFirstLoad) {
            _isFirstLoad = false;
          }

          final stats = state.stats;

          // ✅ ONLY 6 ITEMS - Completed Projects Only
          final data = [
            // 📊 Project Counts
            {
              "title": tr.active,
              "value": stats.activeProjects,
              "color": theme.colorScheme.primary,
              "icon": Icons.play_circle_outline,
              "subtitle": tr.inProgress,
              "isCurrency": false,
            },
            {
              "title": tr.completed,
              "value": stats.completedProjects,
              "color": Colors.green,
              "icon": Icons.check_circle_outline,
              "subtitle": tr.finished,
              "isCurrency": false,
            },
            {
              "title": tr.totalTitle,
              "value": stats.allProjects,
              "color": Colors.purple,
              "icon": Icons.folder_outlined,
              "subtitle": tr.allProjects,
              "isCurrency": false,
            },

            // 💰 COMPLETED Projects Financials
            {
              "title": tr.income,
              "value": stats.totalIncome,
              "color": Colors.teal,
              "icon": Icons.check_circle,
              "subtitle": tr.fromCompleted,
              "isCurrency": true,
            },
            {
              "title": tr.expenses,
              "value": stats.totalExpense,
              "color": Colors.red,
              "icon": Icons.remove_circle,
              "subtitle": tr.fromCompleted,
              "isCurrency": true,
            },
            {
              "title": tr.netProfit,
              "value": stats.netProfit,
              "color": Colors.amber,
              "icon": Icons.trending_up,
              "subtitle": tr.distributable,
              "isCurrency": true,
            },
          ];

          // ✅ Show ALL items - NO FILTERING!
          final allItems = data;

          return Stack(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  double itemWidth;

                  if (c.maxWidth < 400) {
                    itemWidth = c.maxWidth / 2 - 8;
                  } else if (c.maxWidth < 600) {
                    itemWidth = c.maxWidth / 2 - 8;
                  } else if (c.maxWidth < 900) {
                    itemWidth = c.maxWidth / 3 - 8;
                  } else if (c.maxWidth < 1200) {
                    itemWidth = c.maxWidth / 4 - 8;
                  } else {
                    itemWidth = c.maxWidth / allItems.length - 8;
                  }

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: allItems.map((item) {
                      final color = item['color'] as Color;
                      final value = item['value'];
                      final isCurrency = item['isCurrency'] == true;

                      // ✅ Use your extension to convert value to int safely
                      int displayValue;
                      if (value is int) {
                        displayValue = value;
                      } else if (value is double) {
                        displayValue = value.toInt();
                      } else if (value is String) {
                        displayValue = value.toDoubleAmount().toInt();
                      } else {
                        displayValue = 0;
                      }

                      return SizedBox(
                        width: itemWidth,
                        child: HoverCard(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: color.withValues(alpha: .3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: .05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      item['icon'] as IconData,
                                      size: 26,
                                      color: color.withValues(alpha: .5),
                                    ),
                                    AnimatedCount(
                                      value: displayValue,
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                      prefix: isCurrency ? '؋ ' : '',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['title'].toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item['subtitle'] != null)
                                  Text(
                                    item['subtitle'].toString(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: .6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // Subtle refresh indicator in top-right corner
              if (state.isRefreshing)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          );
        }

        // For all other states after first load - return empty container
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, c) {
        double itemWidth = c.maxWidth / 4 - 8;
        if (c.maxWidth < 1200) itemWidth = c.maxWidth / 3 - 8;
        if (c.maxWidth < 600) itemWidth = c.maxWidth / 2 - 8;
        if (c.maxWidth < 400) itemWidth = c.maxWidth / 2 - 8;

        final colors = [
          theme.colorScheme.primary,
          Colors.green,
          Colors.purple,
          Colors.teal,
          Colors.red,
          Colors.amber,
        ];

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(6, (index) {
            final color = colors[index % colors.length];

            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: color.withValues(alpha: .3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .5),
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: .05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/* ------------------ ANIMATED COUNTER ------------------ */

class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  final String prefix;
  final String suffix;
  final bool showDecimals;

  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.prefix = '',
    this.suffix = '',
    this.showDecimals = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        // ✅ Use your extension to format the number with commas
        final formattedValue = showDecimals
            ? val.toAmount(decimal: 2)
            : val.toAmountInt();

        return Text(
          '$prefix$formattedValue$suffix',
          style: style,
        );
      },
    );
  }
}

/* ------------------ DESKTOP HOVER EFFECT ------------------ */

class HoverCard extends StatefulWidget {
  final Widget child;

  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: isHover
            ? (Matrix4.identity()..translateByDouble(0.0, -4.0, 0.0, 1.0))
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}