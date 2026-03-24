import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'bloc/dashboard_stats_bloc.dart';

class DashboardStatsView extends StatelessWidget {
  const DashboardStatsView({super.key});

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
      context.read<DashboardStatsBloc>().add(FetchDashboardStatsEvent());
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
  bool _showLoadingSkeleton = true;

  @override
  void initState() {
    super.initState();
    // Auto-hide loading skeleton after timeout (safety measure)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _showLoadingSkeleton) {
        setState(() {
          _showLoadingSkeleton = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<DashboardStatsBloc, DashboardStatsState>(
      builder: (context, state) {
        // Show loading skeleton only on first load
        if (_showLoadingSkeleton && state is! DashboardStatsLoaded) {
          return _buildLoadingSkeleton(context, theme);
        }

        if (state is DashboardStatsError) {
          // Hide errors on dashboard
          return Container();
        }

        if (state is DashboardStatsLoaded) {
          // Mark first load as complete
          if (_showLoadingSkeleton) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _showLoadingSkeleton = false;
                });
              }
            });
          }

          final stats = state.stats;

          // Don't show if all values are zero or null
          if (!stats.hasData) {
            return Container();
          }

          final data = [
            {
              "title": tr.users,
              "value": stats.usersCount,
              "color": theme.colorScheme.primary,
              "icon": Icons.person,
            },
            {
              "title": tr.employees,
              "value": stats.employeesCount,
              "color": Colors.green,
              "icon": Icons.badge,
            },
            {
              "title": tr.accounts,
              "value": stats.accountsCount,
              "color": Colors.orange,
              "icon": Icons.account_circle,
            },
            {
              "title": tr.stakeholders,
              "value": stats.personalsCount,
              "color": Colors.teal,
              "icon": Icons.people,
            },
          ];

          // Filter out zero values
          final filtered = data.where((e) => (e['value'] as int) > 0).toList();

          if (filtered.isEmpty) {
            return Container();
          }

          return Stack(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  double itemWidth;

                  if (c.maxWidth < 400) {
                    itemWidth = c.maxWidth / 2 - 8;
                  } else if (c.maxWidth < 800) {
                    itemWidth = c.maxWidth / 2 - 8;
                  } else if (c.maxWidth < 1200) {
                    itemWidth = c.maxWidth / 4 - 8;
                  } else {
                    itemWidth = c.maxWidth / filtered.length - 8;
                  }

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: filtered.map((item) {
                      final color = item['color'] as Color;

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
                                      value: item['value'] as int,
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['title'].toString(),
                                  style:
                                  theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
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
        return Container();
      },
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, c) {
        double itemWidth = c.maxWidth / 4 - 8;
        if (c.maxWidth < 1200) itemWidth = c.maxWidth / 2 - 8;
        if (c.maxWidth < 400) itemWidth = c.maxWidth / 2 - 8;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(4, (index) {
            final colors = [
              theme.colorScheme.primary,
              Colors.green,
              Colors.orange,
              Colors.teal,
            ];

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

  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(val.toInt().toString(), style: style);
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