// universal_shimmer.dart - Using YOUR better colors
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../Localizations/l10n/translations/app_localizations.dart';

class UniversalShimmer {
  // ==================== ACCOUNT LIST SHIMMER (YOUR DESIGN WITH YOUR COLORS) ====================

  static Widget invoiceLoading() {
    return _InvoiceShimmerContent();
  }

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

  /// Profile details shimmer - Perfect for stakeholder/individual profile pages
  /// Features: Profile image, name, contact info, and detailed information sections
  static Widget profileDetails({
    bool showImage = true,
    bool showName = true,
    bool showContact = true,
    bool showInfoSections = true,
    int numberOfInfoSections = 4,
    double imageSize = 120,
  }) {
    return _ProfileDetailsShimmerContent(
      showImage: showImage,
      showName: showName,
      showContact: showContact,
      showInfoSections: showInfoSections,
      numberOfInfoSections: numberOfInfoSections,
      imageSize: imageSize,
    );
  }

  /// Compact profile card shimmer (for sidebars or quick views)
  static Widget profileCard({
    bool showImage = true,
    bool showStats = false,
    double imageSize = 80,
  }) {
    return _ProfileCardShimmerContent(
      showImage: showImage,
      showStats: showStats,
      imageSize: imageSize,
    );
  }

  // ==================== DATA LIST SHIMMER (NEW) ====================

  /// Data list shimmer - Perfect for orders, invoices, transactions, etc.
  /// Features: 3-5 columns of data with proper spacing
  static Widget dataList({
    int itemCount = 6,
    int numberOfColumns = 3,
    bool showAvatar = false,
    bool showCheckbox = false,
    bool showActions = true,
    double avatarRadius = 20,
    EdgeInsetsGeometry? padding,
    List<double>? columnWidths, // Custom widths for each column
  }) {
    return _DataListShimmerContent(
      itemCount: itemCount,
      numberOfColumns: numberOfColumns,
      showAvatar: showAvatar,
      showCheckbox: showCheckbox,
      showActions: showActions,
      avatarRadius: avatarRadius,
      padding: padding,
      columnWidths: columnWidths,
    );
  }

  /// Order/Transaction list shimmer (specialized data list)
  static Widget orderList({
    int itemCount = 6,
    bool showDate = true,
    bool showReference = true,
    bool showAmount = true,
    bool showStatus = true,
  }) {
    return _OrderListShimmerContent(
      itemCount: itemCount,
      showDate: showDate,
      showReference: showReference,
      showAmount: showAmount,
      showStatus: showStatus,
    );
  }

  /// Product list shimmer (with image placeholder)
  static Widget productList({
    int itemCount = 6,
    bool showImage = true,
    bool showPrice = true,
    bool showRating = false,
  }) {
    return _ProductListShimmerContent(
      itemCount: itemCount,
      showImage: showImage,
      showPrice: showPrice,
      showRating: showRating,
    );
  }

  /// Table/Grid data list shimmer
  static Widget tableDataList({
    int rowCount = 5,
    int columnCount = 4,
    bool showHeader = true,
  }) {
    return _TableDataShimmerContent(
      rowCount: rowCount,
      columnCount: columnCount,
      showHeader: showHeader,
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

// ==================== DATA LIST SHIMMER (NEW) ====================

class _DataListShimmerContent extends StatelessWidget {
  final int itemCount;
  final int numberOfColumns;
  final bool showAvatar;
  final bool showCheckbox;
  final bool showActions;
  final double avatarRadius;
  final EdgeInsetsGeometry? padding;
  final List<double>? columnWidths;

  const _DataListShimmerContent({
    required this.itemCount,
    required this.numberOfColumns,
    required this.showAvatar,
    required this.showCheckbox,
    required this.showActions,
    required this.avatarRadius,
    this.padding,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: .9);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1200),
          child: Container(
            margin: padding ?? const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: index.isOdd
                  ? colorScheme.primary.withValues(alpha: 0.04)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                if (showCheckbox) ...[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (showAvatar) ...[
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: colorScheme.primaryContainer,
                  ),
                  const SizedBox(width: 12),
                ],
                ...List.generate(numberOfColumns, (colIndex) {
                  final width = columnWidths != null && colIndex < columnWidths!.length
                      ? columnWidths![colIndex]
                      : 100.0;
                  return Expanded(
                    flex: (width / 100).toInt(),
                    child: Padding(
                      padding: EdgeInsets.only(right: colIndex < numberOfColumns - 1 ? 8 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: width,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 18,
                            width: width * 0.7,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (showActions) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== ORDER LIST SHIMMER (SPECIALIZED) ====================

class _OrderListShimmerContent extends StatelessWidget {
  final int itemCount;
  final bool showDate;
  final bool showReference;
  final bool showAmount;
  final bool showStatus;

  const _OrderListShimmerContent({
    required this.itemCount,
    required this.showDate,
    required this.showReference,
    required this.showAmount,
    required this.showStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: index.isOdd
                  ? colorScheme.primary.withValues(alpha: 0.04)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                // Copy button placeholder
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),

                // ID/Reference
                SizedBox(
                  width: showReference ? 100 : 60,
                  child: Container(height: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),

                // Date
                if (showDate) ...[
                  SizedBox(
                    width: 80,
                    child: Container(height: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                ],

                // Reference/TrnRef
                if (showReference) ...[
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 100, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 12, width: 80, color: Colors.white.withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Personal/Customer name
                Expanded(
                  child: Container(height: 16, width: double.infinity, color: Colors.white),
                ),
                const SizedBox(width: 8),

                // Invoice type
                SizedBox(
                  width: 80,
                  child: Container(height: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),

                // Amount
                if (showAmount) ...[
                  SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(height: 16, width: 60, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 12, width: 40, color: Colors.white.withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Status badge
                if (showStatus) ...[
                  Container(
                    width: 80,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== PRODUCT LIST SHIMMER ====================

class _ProductListShimmerContent extends StatelessWidget {
  final int itemCount;
  final bool showImage;
  final bool showPrice;
  final bool showRating;

  const _ProductListShimmerContent({
    required this.itemCount,
    required this.showImage,
    required this.showPrice,
    required this.showRating,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                if (showImage) ...[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 18, width: 180, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 14, width: 120, color: Colors.white),
                      if (showRating) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (star) =>
                              Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(right: 2),
                                color: Colors.white,
                              ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showPrice) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(height: 18, width: 70, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(height: 12, width: 50, color: Colors.white.withValues(alpha: 0.6)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== TABLE DATA SHIMMER ====================

class _TableDataShimmerContent extends StatelessWidget {
  final int rowCount;
  final int columnCount;
  final bool showHeader;

  const _TableDataShimmerContent({
    required this.rowCount,
    required this.columnCount,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Column(
        children: [
          if (showHeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colorScheme.primary.withValues(alpha: 0.08),
              child: Row(
                children: List.generate(columnCount, (index) => Expanded(
                  child: Container(height: 16, color: Colors.white),
                )),
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: index.isOdd
                      ? colorScheme.primary.withValues(alpha: 0.04)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: List.generate(columnCount, (colIndex) => Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: double.infinity, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 12, width: 60, color: Colors.white.withValues(alpha: 0.6)),
                      ],
                    ),
                  )),
                ),
              );
            },
          ),
        ],
      ),
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

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

// ==================== PROFILE DETAILS SHIMMER (WITH THEME COLORS) ====================

class _ProfileDetailsShimmerContent extends StatelessWidget {
  final bool showImage;
  final bool showName;
  final bool showContact;
  final bool showInfoSections;
  final int numberOfInfoSections;
  final double imageSize;

  const _ProfileDetailsShimmerContent({
    required this.showImage,
    required this.showName,
    required this.showContact,
    required this.showInfoSections,
    required this.numberOfInfoSections,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            period: const Duration(milliseconds: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                if (showImage) ...[
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          spreadRadius: 2,
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Name Section
                if (showName) ...[
                  Container(
                    height: 28,
                    width: 200,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Contact Info
                if (showContact) ...[
                  Container(
                    height: 32,
                    width: 140,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Divider
                Container(
                  height: 1,
                  width: double.infinity,
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 20),

                // Info Sections
                if (showInfoSections) ...[
                  // Section Title
                  Container(
                    height: 16,
                    width: 120,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Info Items
                  ...List.generate(numberOfInfoSections, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon placeholder
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text placeholders
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 12,
                                  width: 60,
                                  color: colorScheme.surfaceContainerHighest,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 16,
                                  width: double.infinity,
                                  color: colorScheme.surfaceContainerHighest,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== PROFILE CARD SHIMMER (WITH THEME COLORS) ====================

class _ProfileCardShimmerContent extends StatelessWidget {
  final bool showImage;
  final bool showStats;
  final double imageSize;

  const _ProfileCardShimmerContent({
    required this.showImage,
    required this.showStats,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return SingleChildScrollView(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1200),
        child: Column(
          children: [
            if (showImage) ...[
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Name placeholder
            Container(
              height: 20,
              width: 150,
              color: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),

            // Role/Title placeholder
            Container(
              height: 14,
              width: 100,
              color: colorScheme.surfaceContainerHighest,
            ),

            if (showStats) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatPlaceholder(colorScheme),
                  _buildStatPlaceholder(colorScheme),
                  _buildStatPlaceholder(colorScheme),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatPlaceholder(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(height: 20, width: 50, color: colorScheme.surfaceContainerHighest),
        const SizedBox(height: 4),
        Container(height: 12, width: 40, color: colorScheme.surfaceContainerHighest),
      ],
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
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          );
        },
      ),
    );
  }

}

// ==================== SALE INVOICE SHIMMER ====================

/// Invoice loading shimmer - Matches the invoice screen design

class _InvoiceShimmerContent extends StatelessWidget {
  const _InvoiceShimmerContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    final baseColor = colorScheme.primaryContainer.withValues(alpha: 0.8);
    final highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Column(
        children: [
          // Header section shimmer
          _buildHeaderSection(colorScheme),

          const SizedBox(height: 16),

          // Items header shimmer
          _buildItemsHeaderShimmer(colorScheme, tr),

          const SizedBox(height: 8),

          // Items list shimmer
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) => _buildItemRowShimmer(colorScheme, index),
            ),
          ),

          // Summary section shimmer
          _buildSummarySectionShimmer(colorScheme, tr),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Customer field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 70, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 40, width: double.infinity, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Account field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 70, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 40, width: double.infinity, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Remark field
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 50, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 40, width: double.infinity, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsHeaderShimmer(ColorScheme colorScheme, AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 30),
          Expanded(child: Container(height: 16, color: Colors.white, width: 60)),
          const SizedBox(width: 10),
          Container(height: 16, color: Colors.white, width: 60),
          const SizedBox(width: 10),
          Container(height: 16, color: Colors.white, width: 60),
          const SizedBox(width: 10),
          Container(height: 16, color: Colors.white, width: 60),
          const SizedBox(width: 10),
          Container(height: 16, color: Colors.white, width: 80),
          const SizedBox(width: 10),
          Container(height: 16, color: Colors.white, width: 80),
          const SizedBox(width: 10),
          Container(height: 16, color: Colors.white, width: 60),
        ],
      ),
    );
  }

  Widget _buildItemRowShimmer(ColorScheme colorScheme, int index) {
    final bool isEven = index.isEven;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : colorScheme.primary.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Index number
          SizedBox(width: 30, child: Container(height: 14, width: 20, color: Colors.white)),
          const SizedBox(width: 10),

          // Product name
          Expanded(child: Container(height: 16, color: Colors.white)),
          const SizedBox(width: 10),

          // Qty
          Container(height: 32, color: Colors.white, width: 60),
          const SizedBox(width: 10),

          // Batch
          Container(height: 32, color: Colors.white, width: 60),
          const SizedBox(width: 10),

          // Unit
          Container(height: 32, color: Colors.white, width: 60),
          const SizedBox(width: 10),

          // Unit price
          Container(height: 32, color: Colors.white, width: 80),
          const SizedBox(width: 10),

          // Discount
          Container(height: 32, color: Colors.white, width: 100),
          const SizedBox(width: 10),

          // Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 18, width: 80, color: Colors.white),
              const SizedBox(height: 4),
              Container(height: 12, width: 60, color: Colors.white.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(width: 10),

          // Delete button
          Container(height: 24, width: 24, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSummarySectionShimmer(ColorScheme colorScheme, AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Invoice Summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(height: 20, width: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 18, width: 120, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    _buildSummaryRowShimmer(),
                    const SizedBox(height: 4),
                    _buildSummaryRowShimmer(),
                    const SizedBox(height: 4),
                    _buildSummaryRowShimmer(),
                    const SizedBox(height: 8),
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    _buildSummaryRowShimmer(isBold: true),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              VerticalDivider(width: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
              const SizedBox(width: 12),

              // Right side - Payment Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(height: 20, width: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            Container(height: 18, width: 120, color: Colors.white),
                          ],
                        ),
                        Container(height: 24, width: 80, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRowShimmer(),
                          const SizedBox(height: 8),
                          _buildSummaryRowShimmer(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildSummaryRowShimmer(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRowShimmer({bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: isBold ? 18 : 14,
            width: 80,
            color: Colors.white,
          ),
          Container(
            height: isBold ? 18 : 14,
            width: 100,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}