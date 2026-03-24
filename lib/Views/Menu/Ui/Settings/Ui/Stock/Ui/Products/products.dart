import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/search_field.dart';
import 'add_edit_product.dart';
import 'bloc/products_bloc.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileProductsView(),
      tablet: _TabletProductsView(),
      desktop: _DesktopProductsView(),
    );
  }
}

// Base class to share common functionality
class _BaseProductsView extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseProductsView({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseProductsView> createState() => _BaseProductsViewState();
}

class _BaseProductsViewState extends State<_BaseProductsView> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductsBloc>().add(LoadProductsEvent());
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<ProductsBloc>().add(LoadProductsEvent());
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
            Text(tr.products, style: textTheme.titleLarge),
            Text(
              tr.manageProductTitle,
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
                        builder: (context) => const AddEditProductView(),
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
                      Text(tr.products, style: textTheme.titleLarge),
                      Text(
                        tr.manageProductTitle,
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
                      builder: (context) => const AddEditProductView(),
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
      // Desktop header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        child: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.products, style: textTheme.titleLarge),
                  Text(
                    tr.manageProductTitle,
                    style: textTheme.bodySmall?.copyWith(color: color.outline),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
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
                  builder: (context) => const AddEditProductView(),
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
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(tr.productName, style: titleStyle),
            ),
            SizedBox(
              width: 100,
              child: Text(tr.status, style: titleStyle),
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
            Expanded(
              child: Text(tr.productName, style: titleStyle),
            ),
            Expanded(
              child: Text(tr.details, style: titleStyle),
            ),
            SizedBox(
              width: 150,
              child: Text(tr.madeIn, style: titleStyle),
            ),
            SizedBox(
              width: 90,
              child: Text(tr.status, style: titleStyle),
            ),
          ],
        ),
      );
    }
  }

  // Build product item based on screen size
  Widget _buildProductItem(dynamic product, int index, TextTheme textTheme, ColorScheme color, AppLocalizations tr) {
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
              builder: (context) => AddEditProductView(model: product),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.proName ?? "",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusBadge(
                      status: product.proStatus!,
                      trueValue: tr.active,
                      falseValue: tr.inactive,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Product Code
                ZCover(
                  child: Text(
                    product.proCode ?? "",
                    style: textTheme.bodySmall?.copyWith(
                      color: color.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Details
                if (product.proDetails != null && product.proDetails!.isNotEmpty)
                  Text(
                    product.proDetails!,
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),

                // Made In
                if (product.proMadeIn != null && product.proMadeIn!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: color.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.proMadeIn!,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.outline,
                          ),
                          maxLines: 1,
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
            builder: (context) => AddEditProductView(model: product),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: index.isEven
                ? color.primary.withValues(alpha: .05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.proName ?? "",
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    ZCover(
                      child: Text(
                        product.proCode ?? "",
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: StatusBadge(
                  status: product.proStatus!,
                  trueValue: tr.active,
                  falseValue: tr.inactive,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Desktop row view
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AddEditProductView(model: product),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: index.isEven
                ? color.primary.withValues(alpha: .05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      product.proName ?? "",
                      style: textTheme.titleMedium,
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        ZCover(child: Text(product.proCode ?? "")),
                        Text(product.proDetails ?? ""),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: Text(product.proMadeIn ?? ""),
              ),
              SizedBox(
                width: 90,
                child: StatusBadge(
                  status: product.proStatus!,
                  trueValue: tr.active,
                  falseValue: tr.inactive,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final titleStyle = textTheme.titleSmall;

    return Scaffold(
      backgroundColor: color.surface,
      body: Column(
        children: [
          // Header Section
          _buildHeader(tr, textTheme, color),

          if (!widget.isMobile) ...[
            const SizedBox(height: 5),
            // Table Header
            _buildTableHeader(tr, titleStyle, color),
            Divider(endIndent: 15, indent: 15),
          ],

          // Products List
          Expanded(
            child: BlocConsumer<ProductsBloc, ProductsState>(
              listener: (context, state) {
                if (state is ProductsSuccessState) {
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                if (state is ProductsLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductsErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: onRefresh,
                  );
                }
                if (state is ProductsLoadedState) {
                  final query = searchController.text.toLowerCase().trim();

                  final filteredList = state.products.where((item) {
                    final code = item.proCode?.toLowerCase() ?? '';
                    final productName = item.proName?.toString().toLowerCase() ?? '';
                    final details = item.proDetails?.toLowerCase() ?? '';
                    final madeIn = item.proMadeIn?.toLowerCase() ?? '';

                    return code.contains(query) ||
                        productName.contains(query) ||
                        details.contains(query) ||
                        madeIn.contains(query);
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
                      final product = filteredList[index];
                      return _buildProductItem(product, index, textTheme, color, tr);
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
class _MobileProductsView extends StatelessWidget {
  const _MobileProductsView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProductsView(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletProductsView extends StatelessWidget {
  const _TabletProductsView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProductsView(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopProductsView extends StatelessWidget {
  const _DesktopProductsView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProductsView(
      isMobile: false,
      isTablet: false,
    );
  }
}