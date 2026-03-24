import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/Ui/BranchLimits/Ui/add_edit_limit.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/Ui/BranchLimits/bloc/branch_limit_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branches/model/branch_model.dart';
import '../../../../../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';

class BranchLimitsView extends StatelessWidget {
  final BranchModel branch;
  const BranchLimitsView({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileBranchLimits(branch: branch),
      tablet: _TabletBranchLimits(branch: branch),
      desktop: _DesktopBranchLimits(branch: branch),
    );
  }
}

// Base class to share common functionality
class _BaseBranchLimits extends StatefulWidget {
  final BranchModel branch;
  final bool isMobile;
  final bool isTablet;

  const _BaseBranchLimits({
    required this.branch,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseBranchLimits> createState() => _BaseBranchLimitsState();
}

class _BaseBranchLimitsState extends State<_BaseBranchLimits> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BranchLimitBloc>().add(LoadBranchLimitEvent(widget.branch.brcId));
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Build header row with search and buttons
  Widget _buildHeaderRow(AppLocalizations locale) {
    if (widget.isMobile) {
      // Mobile header - stacked layout
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ZSearchField(
              icon: FontAwesomeIcons.magnifyingGlass,
              controller: searchController,
              hint: locale.search,
              onChanged: (e) {
                setState(() {});
              },
              title: "",
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    toolTip: "F5",
                    icon: Icons.refresh,
                    onPressed: () {
                      context.read<BranchLimitBloc>().add(
                        LoadBranchLimitEvent(widget.branch.brcId),
                      );
                    },
                    label: Text(locale.refresh),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZOutlineButton(
                    toolTip: "F1",
                    icon: Icons.add,
                    isActive: true,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BranchLimitAddEditView(
                          branchCode: widget.branch.brcId,
                        ),
                      );
                    },
                    label: Text(locale.newKeyword),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (widget.isTablet) {
      // Tablet header - compact row layout
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ZSearchField(
                icon: FontAwesomeIcons.magnifyingGlass,
                controller: searchController,
                hint: locale.search,
                onChanged: (e) {
                  setState(() {});
                },
                title: "",
              ),
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              toolTip: "F5",
              width: 100,
              icon: Icons.refresh,
              onPressed: () {
                context.read<BranchLimitBloc>().add(
                  LoadBranchLimitEvent(widget.branch.brcId),
                );
              },
              label: Text(locale.refresh),
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              toolTip: "F1",
              width: 100,
              icon: Icons.add,
              isActive: true,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => BranchLimitAddEditView(
                    branchCode: widget.branch.brcId,
                  ),
                );
              },
              label: Text(locale.newKeyword),
            ),
          ],
        ),
      );
    } else {
      // Desktop header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: ZSearchField(
                icon: FontAwesomeIcons.magnifyingGlass,
                controller: searchController,
                hint: locale.search,
                onChanged: (e) {
                  setState(() {});
                },
                title: "",
              ),
            ),
            ZOutlineButton(
              toolTip: "F5",
              width: 120,
              icon: Icons.refresh,
              onPressed: () {
                context.read<BranchLimitBloc>().add(
                  LoadBranchLimitEvent(widget.branch.brcId),
                );
              },
              label: Text(locale.refresh),
            ),
            ZOutlineButton(
              toolTip: "F1",
              width: 120,
              icon: Icons.add,
              isActive: true,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => BranchLimitAddEditView(
                    branchCode: widget.branch.brcId,
                  ),
                );
              },
              label: Text(locale.newKeyword),
            ),
          ],
        ),
      );
    }
  }

  // Build table header for different screen sizes
  Widget _buildTableHeader(AppLocalizations locale, TextTheme textTheme, ColorScheme color) {
    if (widget.isMobile) {
      // Mobile card view doesn't need a table header
      return const SizedBox.shrink();
    } else if (widget.isTablet) {
      // Tablet table header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(locale.branchId, style: textTheme.titleSmall),
            ),
            Expanded(
              child: Text(locale.currencyTitle, style: textTheme.titleSmall),
            ),
            SizedBox(
              width: 120,
              child: Text(locale.amount, style: textTheme.titleSmall, textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    } else {
      // Desktop table header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(locale.branchId, style: textTheme.titleSmall),
            ),
            Text(locale.currencyTitle, style: textTheme.titleSmall),
            const Spacer(),
            SizedBox(
              width: 150,
              child: Text(locale.amount, style: textTheme.titleSmall, textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to safely parse amount
  num _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is num) return amount;
    if (amount is String) {
      return num.tryParse(amount) ?? 0;
    }
    return 0;
  }

  // Build limit item based on screen size
  Widget _buildLimitItem(dynamic limit, int index, TextTheme textTheme, ColorScheme color, AppLocalizations locale) {
    // Parse the amount safely
    final amountValue = _parseAmount(limit.balLimitAmount);

    if (widget.isMobile) {
      // Mobile card view - Enhanced Design
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.outline.withValues(alpha: .1),
          ),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => BranchLimitAddEditView(branchLimit: limit),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top row with ID and Currency
                Row(
                  children: [
                    // ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.primary.withValues(alpha: .8),
                            color.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.primary.withValues(alpha: .2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "#${limit.balId}",
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Currency with icon
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.currency_exchange,
                              size: 16,
                              color: color.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              limit.balCurrency?.toUpperCase() ?? "N/A",
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider with gradient
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        color.outline.withValues(alpha: .2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Amount section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Label
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 18,
                          color: color.outline,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          locale.amount, // Using existing locale.amount instead of limitAmount
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Amount value with highlight
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.primary.withValues(alpha: .1),
                            color.primary.withValues(alpha: .05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: color.primary.withValues(alpha: .2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "₹",
                            style: textTheme.titleLarge?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            amountValue.toAmount(),
                            style: textTheme.titleLarge?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else if (widget.isTablet) {
      // Tablet row view - Enhanced Design
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => BranchLimitAddEditView(branchLimit: limit),
          );
        },
        splashColor: color.primary.withValues(alpha: .05),
        highlightColor: color.primary.withValues(alpha: .05),
        child: Container(
          decoration: BoxDecoration(
            color: index.isOdd ? color.primary.withValues(alpha: .02) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: color.outline.withValues(alpha: .05),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14),
            child: Row(
              children: [
                // ID with badge
                SizedBox(
                  width: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      limit.balId.toString(),
                      style: textTheme.bodySmall?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Currency with icon
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.currency_exchange,
                          size: 14,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          limit.balCurrency?.toUpperCase() ?? "N/A",
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount with styling
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.primary.withValues(alpha: .2),
                    ),
                  ),
                  child: Text(
                    amountValue.toAmount(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Desktop row view - Enhanced Design
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => BranchLimitAddEditView(branchLimit: limit),
          );
        },
        splashColor: color.primary.withValues(alpha: .05),
        hoverColor: color.primary.withValues(alpha: .05),
        child: Container(
          decoration: BoxDecoration(
            color: index.isOdd ? color.primary.withValues(alpha: .02) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: color.outline.withValues(alpha: .05),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
            child: Row(
              children: [
                // ID with badge
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    limit.balId.toString(),
                    style: textTheme.bodySmall?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Currency with icon
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.currency_exchange,
                          size: 16,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ZCover(
                        child: Text(
                          limit.balCurrency?.toUpperCase() ?? "N/A",
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount with styling
                Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.primary.withValues(alpha: .1),
                        color.primary.withValues(alpha: .05),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.primary.withValues(alpha: .2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "₹",
                        style: textTheme.bodyLarge?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        amountValue.toAmount(),
                        style: textTheme.bodyLarge?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: widget.isMobile
          ? AppBar(
        title: Text("${locale.branchLimits} - ${widget.branch.brcName}"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BranchLimitBloc>().add(
                LoadBranchLimitEvent(widget.branch.brcId),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => BranchLimitAddEditView(
                  branchCode: widget.branch.brcId,
                ),
              );
            },
          ),
        ],
      )
          : null,
      body: Column(
        children: [
          // Header Section
          _buildHeaderRow(locale),

          if (!widget.isMobile) ...[
            const SizedBox(height: 5),
            // Table Header
            _buildTableHeader(locale, textTheme, color),
            Divider(
              color: color.primary,
              indent: widget.isTablet ? 12 : 15,
              endIndent: widget.isTablet ? 12 : 15,
            ),
          ],

          // Limits List
          Expanded(
            child: BlocConsumer<BranchLimitBloc, BranchLimitState>(
              listener: (context, state) {
                if (state is BranchLimitSuccessState) {
                  Navigator.of(context).pop();
                  context.read<BranchLimitBloc>().add(
                    LoadBranchLimitEvent(widget.branch.brcId),
                  );
                }
              },
              builder: (context, state) {
                if (state is BranchLimitErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: () {
                      context.read<BranchLimitBloc>().add(
                        LoadBranchLimitEvent(widget.branch.brcId),
                      );
                    },
                  );
                }
                if (state is BranchLimitLoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (state is BranchLimitLoadedState) {
                  final query = searchController.text.toLowerCase().trim();

                  // Filter with amount parsing for search
                  final filteredList = state.limits.where((item) {
                    final name = item.balCurrency?.toLowerCase() ?? '';
                    final amount = item.balLimitAmount?.toString() ?? '';
                    final amountValue = _parseAmount(item.balLimitAmount);
                    final amountFormatted = amountValue.toAmount().toLowerCase();

                    return name.contains(query) ||
                        amount.contains(query) ||
                        amountFormatted.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: locale.noDataFound,
                      onRefresh: () {
                        context.read<BranchLimitBloc>().add(
                          LoadBranchLimitEvent(widget.branch.brcId),
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    padding: widget.isMobile
                        ? const EdgeInsets.symmetric(vertical: 8)
                        : EdgeInsets.zero,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final limit = filteredList[index];
                      return _buildLimitItem(limit, index, textTheme, color, locale);
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Mobile View
class _MobileBranchLimits extends StatelessWidget {
  final BranchModel branch;

  const _MobileBranchLimits({required this.branch});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchLimits(
      branch: branch,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletBranchLimits extends StatelessWidget {
  final BranchModel branch;

  const _TabletBranchLimits({required this.branch});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchLimits(
      branch: branch,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopBranchLimits extends StatelessWidget {
  final BranchModel branch;

  const _DesktopBranchLimits({required this.branch});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchLimits(
      branch: branch,
      isMobile: false,
      isTablet: false,
    );
  }
}