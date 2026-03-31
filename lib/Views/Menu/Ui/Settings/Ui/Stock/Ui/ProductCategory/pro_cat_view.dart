import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/ProductCategory/add_edit_cat.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/ProductCategory/bloc/pro_cat_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/search_field.dart';

class ProCatView extends StatelessWidget {
  const ProCatView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileProCatView(),
      tablet: _TabletProCatView(),
      desktop: _DesktopProCatView(),
    );
  }
}

// Base class to share common functionality
class _BaseProCatView extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseProCatView({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseProCatView> createState() => _BaseProCatViewState();
}

class _BaseProCatViewState extends State<_BaseProCatView> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProCatBloc>().add(LoadProCatEvent());
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<ProCatBloc>().add(LoadProCatEvent());
  }

  // Build header for different screen sizes
  Widget _buildHeader(AppLocalizations tr, TextTheme textTheme, ColorScheme color) {
    if (widget.isMobile) {
      // Mobile header - stacked layout
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.categoryTitle, style: textTheme.titleLarge),
            Text(
              tr.productCategoryTitle,
              style: textTheme.bodySmall?.copyWith(color: color.outline),
            ),
            const SizedBox(height: 12),
            ZSearchField(
              controller: searchController,
              hint: tr.search,
              title: '',
              end: searchController.text.isNotEmpty
                  ? InkWell(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    searchController.clear();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.clear, size: 15),
                ),
              )
                  : const SizedBox(),
              onChanged: (e) {
                setState(() {});
              },
              icon: FontAwesomeIcons.magnifyingGlass,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    icon: Icons.refresh,
                    onPressed: onRefresh,
                    label: Text(tr.refresh),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZOutlineButton(
                    isActive: true,
                    icon: Icons.add,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddEditProCategoryView(),
                      );
                    },
                    label: Text(tr.newKeyword),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.categoryTitle, style: textTheme.titleLarge),
                      Text(
                        tr.productCategoryTitle,
                        style: textTheme.bodySmall?.copyWith(color: color.outline),
                      ),
                    ],
                  ),
                ),
                ZOutlineButton(
                  width: 100,
                  icon: Icons.refresh,
                  onPressed: onRefresh,
                  label: Text(tr.refresh),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  width: 100,
                  isActive: true,
                  icon: Icons.add,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddEditProCategoryView(),
                    );
                  },
                  label: Text(tr.newKeyword),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ZSearchField(
              controller: searchController,
              hint: tr.search,
              title: '',
              end: searchController.text.isNotEmpty
                  ? InkWell(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    searchController.clear();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.clear, size: 15),
                ),
              )
                  : const SizedBox(),
              onChanged: (e) {
                setState(() {});
              },
              icon: FontAwesomeIcons.magnifyingGlass,
            ),
          ],
        ),
      );
    } else {
      // SIMPLIFIED DESKTOP HEADER
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.surface,
          border: Border(
            bottom: BorderSide(color: color.outline.withValues(alpha: .1)),
          ),
        ),
        child: Row(
          children: [
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.categoryTitle,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    tr.productCategoryTitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurface.withValues(alpha: .6),
                    ),
                  ),
                ],
              ),
            ),

            // Search
            SizedBox(
              width: 300,
              child: ZSearchField(
                controller: searchController,
                hint: tr.search,
                title: '',
                end: searchController.text.isNotEmpty
                    ? InkWell(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    setState(() {
                      searchController.clear();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.clear, size: 15),
                  ),
                )
                    : const SizedBox(),
                onChanged: (e) {
                  setState(() {});
                },
                icon: FontAwesomeIcons.magnifyingGlass,
              ),
            ),
            const SizedBox(width: 12),

            // Buttons
            ZOutlineButton(
              width: 100,
              icon: Icons.refresh,
              onPressed: onRefresh,
              label: Text(tr.refresh),
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              width: 100,
              isActive: true,
              icon: Icons.add,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddEditProCategoryView(),
                );
              },
              label: Text(tr.newKeyword),
            ),
          ],
        ),
      );
    }
  }

  // Build category item based on screen size
  Widget _buildCategoryItem(dynamic cat, int index, TextTheme textTheme, ColorScheme color, AppLocalizations tr) {
    if (widget.isMobile) {
      // Mobile card view
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddEditProCategoryView(model: cat),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID and Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${tr.id}: ${cat.pcId}",
                        style: textTheme.bodySmall?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusBadge(
                      status: cat.pcStatus!,
                      trueValue: tr.active,
                      falseValue: tr.inactive,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Name
                Text(
                  cat.pcName ?? "",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                if (cat.pcDescription != null && cat.pcDescription!.isNotEmpty)
                  Text(
                    cat.pcDescription!,
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      );
    } else if (widget.isTablet) {
      // Tablet row view
      return ListTile(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AddEditProCategoryView(model: cat),
          );
        },
        tileColor: index.isEven ? color.primary.withValues(alpha: .05) : Colors.transparent,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.primary.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              cat.pcId.toString(),
              style: textTheme.bodyMedium?.copyWith(
                color: color.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          cat.pcName ?? "",
          style: textTheme.titleMedium,
        ),
        subtitle: Text(
          cat.pcDescription ?? "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 80,
          child: StatusBadge(
            status: cat.pcStatus!,
            trueValue: tr.active,
            falseValue: tr.inactive,
          ),
        ),
      );
    } else {
      // SIMPLIFIED DESKTOP ROW VIEW - Just Name and Status
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        decoration: BoxDecoration(
          color: index.isEven ? color.primary.withValues(alpha: .02) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddEditProCategoryView(model: cat),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // ID
                SizedBox(
                  width: 50,
                  child: Text(
                    cat.pcId.toString(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Name
                Expanded(
                  child: Text(
                    cat.pcName ?? "",
                    style: textTheme.titleMedium,
                  ),
                ),

                // Status
                SizedBox(
                  width: 100,
                  child: StatusBadge(
                    status: cat.pcStatus!,
                    trueValue: tr.active,
                    falseValue: tr.inactive,
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
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Header Section
          _buildHeader(tr, textTheme, color),

          // SIMPLIFIED DESKTOP TABLE HEADER
          if (!widget.isMobile && !widget.isTablet)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      tr.id,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tr.categoryTitle,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      tr.status,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

          // Categories List
          Expanded(
            child: BlocConsumer<ProCatBloc, ProCatState>(
              listener: (context, state) {
                if (state is ProCatSuccessState) {
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                if (state is ProCatLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProCatErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: onRefresh,
                  );
                }
                if (state is ProCatLoadedState) {
                  final query = searchController.text.toLowerCase().trim();

                  final filteredList = state.proCategory.where((item) {
                    final name = item.pcName?.toLowerCase() ?? '';
                    final desc = item.pcDescription?.toLowerCase() ?? '';
                    final id = item.pcId.toString();
                    return name.contains(query) || desc.contains(query) || id.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      onRefresh: onRefresh,
                    );
                  }

                  return ListView.builder(
                    padding: widget.isMobile
                        ? const EdgeInsets.symmetric(vertical: 8)
                        : EdgeInsets.zero,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final cat = filteredList[index];
                      return _buildCategoryItem(cat, index, textTheme, color, tr);
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
class _MobileProCatView extends StatelessWidget {
  const _MobileProCatView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProCatView(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletProCatView extends StatelessWidget {
  const _TabletProCatView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProCatView(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopProCatView extends StatelessWidget {
  const _DesktopProCatView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProCatView(
      isMobile: false,
      isTablet: false,
    );
  }
}