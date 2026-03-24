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
              hint: tr.accNameOrNumber,
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
              hint: tr.accNameOrNumber,
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
      // Desktop header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
        child: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
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
            Expanded(
              flex: 2,
              child: ZSearchField(
                controller: searchController,
                hint: tr.accNameOrNumber,
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
            ZOutlineButton(
              width: 110,
              icon: Icons.refresh,
              onPressed: onRefresh,
              label: Text(tr.refresh),
            ),
            ZOutlineButton(
              width: 110,
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

  // Build table header for different screen sizes
  Widget _buildTableHeader(AppLocalizations tr, TextStyle? titleStyle, ColorScheme color) {
    if (widget.isMobile) {
      // Mobile card view doesn't need table header
      return const SizedBox.shrink();
    } else if (widget.isTablet) {
      // Tablet table header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(tr.categoryTitle, style: titleStyle),
            ),
            SizedBox(
              width: 80,
              child: Text(tr.status, style: titleStyle, textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    } else {
      // Desktop table header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(tr.categoryTitle, style: titleStyle)),
            SizedBox(
              width: 60,
              child: Text(tr.status, style: titleStyle, textAlign: TextAlign.right),
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
                        "ID: ${cat.pcId}",
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
      // Desktop row view
      return ListTile(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AddEditProCategoryView(model: cat),
          );
        },
        tileColor: index.isEven ? color.primary.withValues(alpha: .05) : Colors.transparent,
        leading: Text(cat.pcId.toString()),
        title: Text(cat.pcName ?? ""),
        subtitle: Text(cat.pcDescription ?? ""),
        trailing: StatusBadge(
          status: cat.pcStatus!,
          trueValue: tr.active,
          falseValue: tr.inactive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;
    final titleStyle = textTheme.titleMedium;

    return Scaffold(
      body: Column(
        children: [
          // Header Section
          _buildHeader(tr, textTheme, color),

          if (!widget.isMobile) ...[
            // Table Header
            _buildTableHeader(tr, titleStyle, color),
            const SizedBox(height: 4),
          ],

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