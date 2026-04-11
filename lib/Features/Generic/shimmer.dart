// universal_shimmer.dart - Using YOUR better colors
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UniversalShimmer {
  // ==================== ACCOUNT LIST SHIMMER (YOUR DESIGN WITH YOUR COLORS) ====================

  /// Account list shimmer - matches your exact account list design
  static Widget accountList({
    int itemCount = 6,
    bool useAlternatingColors = true,
  }) {
    return _AccountListShimmerContent(
      itemCount: itemCount,
      useAlternatingColors: useAlternatingColors,
    );
  }

  // ==================== OTHER STATIC METHODS USING YOUR COLORS ====================

  /// Simple text-only list
  static Widget textList({
    int count = 6,
    EdgeInsetsGeometry? padding,
  }) {
    return _ShimmerListView(
      itemCount: count,
      useAlternatingColors: false,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 20, width: double.infinity, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 14, width: 200, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// Avatar + text list (like contacts, users)
  static Widget avatarWithText({
    int count = 6,
    double avatarRadius = 22,
    double spacing = 12,
    EdgeInsetsGeometry? padding,
  }) {
    return _ShimmerListView(
      itemCount: count,
      useAlternatingColors: true,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(radius: avatarRadius, backgroundColor: Colors.white),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: 120, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 180, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Two lines text with trailing content
  static Widget twoLinesWithTrailing({
    int count = 6,
    bool showAvatar = true,
    double avatarRadius = 22,
    EdgeInsetsGeometry? padding,
  }) {
    return _ShimmerListView(
      itemCount: count,
      useAlternatingColors: true,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            if (showAvatar) ...[
              CircleAvatar(radius: avatarRadius, backgroundColor: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: 140, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 200, color: Colors.white),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(height: 14, width: 60, color: Colors.white),
                const SizedBox(height: 4),
                Container(height: 18, width: 80, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Grid view shimmer
  static Widget gridView({
    int count = 4,
    int crossAxisCount = 2,
    double height = 150,
    double crossAxisSpacing = 12,
    double mainAxisSpacing = 12,
    double borderRadius = 12,
  }) {
    return _ShimmerGrid(
      itemCount: count,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Horizontal list shimmer
  static Widget horizontalList({
    int count = 5,
    double itemWidth = 150,
    double itemHeight = 100,
    double spacing = 12,
    double borderRadius = 12,
    EdgeInsetsGeometry? padding,
  }) {
    return _ShimmerHorizontalList(
      itemCount: count,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      spacing: spacing,
      borderRadius: borderRadius,
      padding: padding,
    );
  }

  /// Profile header shimmer
  static Widget profileHeader({
    double avatarRadius = 40,
    bool showStats = true,
  }) {
    return Column(
      children: [
        CircleAvatar(radius: avatarRadius, backgroundColor: Colors.white),
        const SizedBox(height: 12),
        Container(height: 24, width: 200, color: Colors.white),
        const SizedBox(height: 8),
        Container(height: 16, width: 150, color: Colors.white),
        if (showStats) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(),
              _buildStatItem(),
              _buildStatItem(),
            ],
          ),
        ],
      ],
    );
  }

  /// Card shimmer
  static Widget card({
    double height = 120,
    double borderRadius = 12,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // ==================== PRIVATE HELPERS ====================

  static Widget _buildStatItem() {
    return Column(
      children: [
        Container(height: 20, width: 50, color: Colors.white),
        const SizedBox(height: 4),
        Container(height: 14, width: 40, color: Colors.white),
      ],
    );
  }
}

// ==================== PRIVATE WIDGETS USING YOUR COLORS ====================

class _ShimmerListView extends StatelessWidget {
  final int itemCount;
  final Widget child;
  final bool useAlternatingColors;

  const _ShimmerListView({
    required this.itemCount,
    required this.child,
    required this.useAlternatingColors,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // USING YOUR BETTER COLORS
    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1200),
          child: Container(
            decoration: BoxDecoration(
              color: useAlternatingColors && index.isOdd
                  ? colorScheme.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _AccountListShimmerContent extends StatelessWidget {
  final int itemCount;
  final bool useAlternatingColors;

  const _AccountListShimmerContent({
    required this.itemCount,
    required this.useAlternatingColors,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // USING YOUR BETTER COLORS
    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1200),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
            decoration: BoxDecoration(
              color: useAlternatingColors && index.isOdd
                  ? colorScheme.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colorScheme.primaryContainer,
                    child: const SizedBox(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 180,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        height: 14,
                        width: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 18,
                        width: 80,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Widget child;

  const _ShimmerGrid({
    required this.itemCount,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // USING YOUR BETTER COLORS
    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: 0.8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1200),
          child: child,
        );
      },
    );
  }
}

class _ShimmerHorizontalList extends StatelessWidget {
  final int itemCount;
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const _ShimmerHorizontalList({
    required this.itemCount,
    required this.itemWidth,
    required this.itemHeight,
    required this.spacing,
    required this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // USING YOUR BETTER COLORS
    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            period: const Duration(milliseconds: 1200),
            child: Container(
              width: itemWidth,
              margin: EdgeInsets.only(right: spacing),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          );
        },
      ),
    );
  }
}