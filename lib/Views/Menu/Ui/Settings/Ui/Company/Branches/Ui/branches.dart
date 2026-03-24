import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/branch_details.dart';
import '../../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../../Features/Widgets/search_field.dart';
import '../bloc/branch_bloc.dart';
import 'add_edit_branch.dart';

class BranchesView extends StatelessWidget {
  const BranchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileBranchesView(),
      tablet: _TabletBranchesView(),
      desktop: _DesktopBranchesView(),
    );
  }
}

// Base class to share common functionality
class _BaseBranchesView extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseBranchesView({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseBranchesView> createState() => _BaseBranchesViewState();
}

class _BaseBranchesViewState extends State<_BaseBranchesView> {
  final TextEditingController searchController = TextEditingController();

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
                      context.read<BranchBloc>().add(LoadBranchesEvent());
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
                        builder: (context) => const BranchAddEditView(),
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
                context.read<BranchBloc>().add(LoadBranchesEvent());
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
                  builder: (context) => const BranchAddEditView(),
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
                context.read<BranchBloc>().add(LoadBranchesEvent());
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
                  builder: (context) => const BranchAddEditView(),
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
  Widget _buildTableHeader(AppLocalizations locale, TextTheme textTheme) {
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
              child: Text(locale.branchId, style: textTheme.titleMedium),
            ),
            Expanded(
              flex: 2,
              child: Text(locale.branchName, style: textTheme.titleMedium),
            ),
            SizedBox(
              width: 120,
              child: Text(locale.city, style: textTheme.titleMedium),
            ),
            SizedBox(
              width: 100,
              child: Text(locale.province, style: textTheme.titleMedium),
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
              width: 70,
              child: Text(locale.branchId, style: textTheme.titleMedium),
            ),
            Expanded(
              child: Text(locale.branchName, style: textTheme.titleMedium),
            ),
            SizedBox(
              width: 150,
              child: Text(locale.city, style: textTheme.titleMedium),
            ),
            SizedBox(
              width: 120,
              child: Text(locale.province, style: textTheme.titleMedium),
            ),
            SizedBox(
              width: 120,
              child: Text(locale.country, style: textTheme.titleMedium),
            ),
          ],
        ),
      );
    }
  }

  // Build branch item based on screen size
  Widget _buildBranchItem(dynamic brc, int index, TextTheme textTheme, ColorScheme color) {
    if (widget.isMobile) {
      // Mobile card view
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => BranchDetailsView(branch: brc),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        brc.brcName ?? "",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "ID: ${brc.brcId}",
                        style: textTheme.bodySmall?.copyWith(
                          color: color.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: color.primary.withValues(alpha: .7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [
                          brc.addCity,
                          brc.addProvince,
                          brc.addCountry,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                        style: textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
      // Tablet row view
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => BranchDetailsView(branch: brc),
          );
        },
        splashColor: color.primary.withValues(alpha: .05),
        hoverColor: color.primary.withValues(alpha: .05),
        child: Container(
          decoration: BoxDecoration(
            color: index.isOdd ? color.primary.withValues(alpha: .05) : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    brc.brcId.toString(),
                    style: textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    brc.brcName ?? "",
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    brc.addCity ?? "",
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    brc.addProvince ?? "",
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Desktop row view
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => BranchDetailsView(branch: brc),
          );
        },
        splashColor: color.primary.withValues(alpha: .05),
        hoverColor: color.primary.withValues(alpha: .05),
        child: Container(
          decoration: BoxDecoration(
            color: index.isOdd ? color.primary.withValues(alpha: .05) : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    brc.brcId.toString(),
                    style: textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    brc.brcName ?? "",
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    brc.addCity ?? "",
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    brc.addProvince ?? "",
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    brc.addCountry ?? "",
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
        title: Text(locale.branches),
      )
          : null,
      body: Column(
        children: [
          // Header Section
          _buildHeaderRow(locale),

          if (!widget.isMobile) ...[
            const SizedBox(height: 5),
            // Table Header
            _buildTableHeader(locale, textTheme),
            Divider(
              color: color.primary,
              indent: widget.isTablet ? 12 : 15,
              endIndent: widget.isTablet ? 12 : 15,
            ),
          ],

          // Branches List
          Expanded(
            child: BlocConsumer<BranchBloc, BranchState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (state is BranchErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: () {
                      context.read<BranchBloc>().add(LoadBranchesEvent());
                    },
                  );
                }
                if (state is BranchLoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (state is BranchLoadedState) {
                  final query = searchController.text.toLowerCase().trim();
                  final filteredList = state.branches.where((item) {
                    final name = item.brcName?.toLowerCase() ?? '';
                    final city = item.addCity?.toLowerCase() ?? '';
                    final province = item.addProvince?.toLowerCase() ?? '';
                    final country = item.addCountry?.toLowerCase() ?? '';
                    return name.contains(query) ||
                        city.contains(query) ||
                        province.contains(query) ||
                        country.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: locale.noDataFound,
                      onRefresh: () {
                        context.read<BranchBloc>().add(LoadBranchesEvent());
                      },
                    );
                  }

                  return ListView.builder(
                    padding: widget.isMobile
                        ? const EdgeInsets.symmetric(vertical: 8)
                        : EdgeInsets.zero,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final brc = filteredList[index];
                      return _buildBranchItem(brc, index, textTheme, color);
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
class _MobileBranchesView extends StatelessWidget {
  const _MobileBranchesView();

  @override
  Widget build(BuildContext context) {
    return const _BaseBranchesView(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletBranchesView extends StatelessWidget {
  const _TabletBranchesView();

  @override
  Widget build(BuildContext context) {
    return const _BaseBranchesView(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopBranchesView extends StatelessWidget {
  const _DesktopBranchesView();

  @override
  Widget build(BuildContext context) {
    return const _BaseBranchesView(
      isMobile: false,
      isTablet: false,
    );
  }
}