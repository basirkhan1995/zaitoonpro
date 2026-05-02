import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/StockAvailability/bloc/product_report_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/StockAvailability/features/storage_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/StockAvailability/print_stock.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../../../../Localizations/Bloc/localizations_bloc.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import '../../../../Settings/Ui/Stock/Ui/Products/model/product_model.dart';
import '../../UserReport/status_drop.dart';
import 'model/product_report_model.dart';


class ProductReportView extends StatelessWidget {
  const ProductReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Mobile(), tablet: _Tablet(), desktop: _Desktop());
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  int? storageId;
  String? baseCcy;
  String? myLocale;
  int? productId;
  int? isNoStock;

  final productController = TextEditingController();
  final filterProductController = TextEditingController();

  String? _getBaseCurrency() {
    try {
      final companyState = context.read<CompanyProfileBloc>().state;
      if (companyState is CompanyProfileLoadedState) {
        return companyState.company.comLocalCcy;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  @override
  void initState() {
    super.initState();
    baseCcy = _getBaseCurrency();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<ProductReportBloc>().add(ResetProductReportEvent());
  }

  @override
  void dispose() {
    productController.dispose();
    filterProductController.dispose();
    super.dispose();
  }

  bool get hasAnyFilter {
    return isNoStock != null || storageId != null || productId != null;
  }

  void _clearFilters() {
    setState(() {
      isNoStock = null;
      productId = null;
      storageId = null;
      productController.clear();
      filterProductController.clear();
    });
    context.read<ProductReportBloc>().add(ResetProductReportEvent());
  }

  bool _isOutOfStock(String? quantity) {
    if (quantity == null || quantity.isEmpty) return true;
    try {
      return double.parse(quantity) <= 0;
    } catch (e) {
      return true;
    }
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      bodyBuilder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 8),

                /// 🔹 Product Selection
                GenericTextField<ProductsModel, ProductsBloc, ProductsState>(
                  title: tr.products,
                  controller: filterProductController,
                  hintText: tr.products,
                  bloc: context.read<ProductsBloc>(),
                  fetchAllFunction: (bloc) =>
                      bloc.add(LoadProductsEvent()),
                  searchFunction: (bloc, query) =>
                      bloc.add(LoadProductsEvent()),
                  showAllOption: true,
                  allOption: ProductsModel(
                    proId: null,
                    proName: tr.all,
                    proCode: '',
                  ),
                  itemBuilder: (context, product) {
                    if (product.proId == null) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          tr.all,
                          style: TextStyle(
                            color: color.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(product.proName ?? ''),
                    );
                  },
                  itemToString: (product) =>
                  product.proName ??
                      (product.proId == null ? tr.all : ''),
                  stateToLoading: (state) =>
                  state is ProductsLoadingState,
                  stateToItems: (state) {
                    if (state is ProductsLoadedState) {
                      return state.products;
                    }
                    return [];
                  },
                  onSelected: (product) {
                    setSheetState(() {
                      productId = product.proId;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// 🔹 Storage Dropdown
                StorageDropDown(
                  height: 45,
                  title: tr.storage,
                  selectedId: storageId,
                  onChanged: (e) {
                    setSheetState(() {
                      storageId = e?.stgId;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// 🔹 Status Dropdown
                StatusDropdown(
                  height: 45,
                  items: const [
                    StatusItem(null, "All"),
                    StatusItem(1, "Available"),
                    StatusItem(2, "Out of Stock"),
                  ],
                  value: isNoStock,
                  onChanged: (e) {
                    setSheetState(() {
                      isNoStock = e;
                    });
                  },
                ),

                const SizedBox(height: 24),

                /// 🔹 Buttons
                Row(
                  children: [
                    if (hasAnyFilter)
                      Expanded(
                        child: ZOutlineButton(
                          onPressed: () {
                            setSheetState(() {
                              isNoStock = null;
                              productId = null;
                              storageId = null;
                              filterProductController.clear();
                            });

                            setState(() {
                              productController.clear();
                            });
                          },
                          label: Text(tr.clear),
                        ),
                      ),

                    if (hasAnyFilter)
                      const SizedBox(width: 8),

                    Expanded(
                      child: ZOutlineButton(
                        isActive: true,
                        onPressed: () {
                          Navigator.pop(context);

                          setState(() {
                            if (filterProductController
                                .text
                                .isNotEmpty) {
                              productController.text =
                                  filterProductController.text;
                            }
                          });

                          context
                              .read<ProductReportBloc>()
                              .add(
                            LoadProductsReportEvent(
                              isNoStock: isNoStock,
                              storageId: storageId,
                              productId: productId,
                            ),
                          );
                        },
                        label: Text(tr.apply),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text("${tr.products} ${tr.report}"),
        actions: [
          if (hasAnyFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected Filters Chips
          if (hasAnyFilter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (productController.text.isNotEmpty)
                      _buildFilterChip(
                        label: productController.text,
                        color: color.primary,
                        onRemove: () {
                          setState(() {
                            productId = null;
                            productController.clear();
                          });
                          if (!hasAnyFilter) {
                            context.read<ProductReportBloc>().add(ResetProductReportEvent());
                          }
                        },
                      ),
                    if (storageId != null)
                      _buildFilterChip(
                        label: "${tr.storage}: $storageId",
                        color: color.secondary,
                        onRemove: () {
                          setState(() {
                            storageId = null;
                          });
                          if (!hasAnyFilter) {
                            context.read<ProductReportBloc>().add(ResetProductReportEvent());
                          }
                        },
                      ),
                    if (isNoStock != null)
                      _buildFilterChip(
                        label: isNoStock == 1 ? tr.available : tr.outOfStock,
                        color: isNoStock == 1 ? Colors.green : color.error,
                        onRemove: () {
                          setState(() {
                            isNoStock = null;
                          });
                          if (!hasAnyFilter) {
                            context.read<ProductReportBloc>().add(ResetProductReportEvent());
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: BlocBuilder<ProductReportBloc, ProductReportState>(
              builder: (context, state) {
                if (state is ProductReportErrorState) {
                  return NoDataWidget(
                    title: tr.accessDenied,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is ProductReportInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Inventory Overview",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Stock Availability Summary",
                          style: TextStyle(color: color.outline),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showFilterBottomSheet,
                          icon: const Icon(Icons.filter_list),
                          label: Text(tr.apply),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ProductReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductReportLoadedState) {
                  if (state.stock.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.stock.length,
                    itemBuilder: (context, index) {
                      final stk = state.stock[index];
                      final isOutOfStock = _isOutOfStock(stk.availableQuantity);

                      return ZCover(
                        radius: 5,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with ID and Name
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.primary.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "#${stk.no}",
                                      style: TextStyle(
                                        color: color.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isOutOfStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.error.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tr.outOfStock,
                                        style: TextStyle(
                                          color: color.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Product Name
                              Text(
                                stk.proName ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Storage
                              Row(
                                children: [
                                  Icon(
                                    Icons.inventory,
                                    size: 14,
                                    color: color.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    stk.stgName ?? "",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: color.outline,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              // Details Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Unit Price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr.unitPrice,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color.outline,
                                          ),
                                        ),
                                        Text(
                                          "${stk.pricePerUnit.toAmount()} $baseCcy",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quantity
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          tr.unit,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color.outline,
                                          ),
                                        ),
                                        Text(
                                          stk.availableQuantity?.isEmpty == true ? "0" : stk.availableQuantity!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isOutOfStock ? color.error : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Total
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          tr.totalProductValue,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color.outline,
                                          ),
                                        ),
                                        Text(
                                          "${stk.total.toAmount(decimal: 2)} $baseCcy",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: color.primary,
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
                      );
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

  Widget _buildFilterChip({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  int? storageId;
  String? baseCcy;
  String? myLocale;
  int? productId;
  int? isNoStock;
  bool _showFilters = true;

  final productController = TextEditingController();

  String? _getBaseCurrency() {
    try {
      final companyState = context.read<CompanyProfileBloc>().state;
      if (companyState is CompanyProfileLoadedState) {
        return companyState.company.comLocalCcy;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  @override
  void initState() {
    super.initState();
    baseCcy = _getBaseCurrency();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<ProductReportBloc>().add(ResetProductReportEvent());
  }

  @override
  void dispose() {
    productController.dispose();
    super.dispose();
  }

  bool get hasAnyFilter {
    return isNoStock != null || storageId != null || productId != null;
  }

  void _clearFilters() {
    setState(() {
      isNoStock = null;
      productId = null;
      storageId = null;
      productController.clear();
    });
    context.read<ProductReportBloc>().add(ResetProductReportEvent());
  }

  bool _isOutOfStock(String? quantity) {
    if (quantity == null || quantity.isEmpty) return true;
    try {
      return double.parse(quantity) <= 0;
    } catch (e) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text("${tr.products} ${tr.report}"),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (hasAnyFilter)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              context.read<ProductReportBloc>().add(LoadProductsReportEvent(
                isNoStock: isNoStock,
                storageId: storageId,
                productId: productId,
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Product
                  SizedBox(
                    width: 300,
                    child: GenericTextField<ProductsModel, ProductsBloc, ProductsState>(
                      title: tr.products,
                      controller: productController,
                      hintText: tr.products,
                      bloc: context.read<ProductsBloc>(),
                      fetchAllFunction: (bloc) => bloc.add(LoadProductsEvent()),
                      searchFunction: (bloc, query) => bloc.add(LoadProductsEvent()),
                      showAllOption: true,
                      allOption: ProductsModel(
                        proId: null,
                        proName: tr.all,
                        proCode: '',
                      ),
                      itemBuilder: (context, product) {
                        if (product.proId == null) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              tr.all,
                              style: TextStyle(
                                color: color.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(product.proName ?? ''),
                        );
                      },
                      itemToString: (product) => product.proName ?? (product.proId == null ? tr.all : ''),
                      stateToLoading: (state) => state is ProductsLoadingState,
                      stateToItems: (state) {
                        if (state is ProductsLoadedState) return state.products;
                        return [];
                      },
                      onSelected: (product) {
                        setState(() {
                          productId = product.proId;
                        });
                      },
                    ),
                  ),
                  // Storage
                  SizedBox(
                    width: 200,
                    child: StorageDropDown(
                      height: 45,
                      title: tr.storage,
                      selectedId: storageId,
                      onChanged: (e) {
                        setState(() {
                          storageId = e?.stgId;
                        });
                      },
                    ),
                  ),
                  // Status
                  SizedBox(
                    width: 200,
                    child: StatusDropdown(
                      height: 45,
                      items: const [
                        StatusItem(null, "All"),
                        StatusItem(1, "Available"),
                        StatusItem(2, "Out of Stock"),
                      ],
                      value: isNoStock,
                      onChanged: (e) {
                        setState(() {
                          isNoStock = e;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<ProductReportBloc, ProductReportState>(
              builder: (context, state) {
                if (state is ProductReportErrorState) {
                  return NoDataWidget(
                    title: tr.accessDenied,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is ProductReportInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Inventory Overview",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Stock Availability Summary",
                          style: TextStyle(color: color.outline),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ProductReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductReportLoadedState) {
                  if (state.stock.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.stock.length,
                    itemBuilder: (context, index) {
                      final stk = state.stock[index];
                      final isOutOfStock = _isOutOfStock(stk.availableQuantity);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ID and Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "#${stk.no}",
                                    style: TextStyle(
                                      color: color.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isOutOfStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.error.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tr.outOfStock,
                                        style: TextStyle(
                                          color: color.error,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Product Name
                              Text(
                                stk.proName ?? "",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Storage
                              Row(
                                children: [
                                  Icon(
                                    Icons.inventory,
                                    size: 12,
                                    color: color.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      stk.stgName ?? "",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color.outline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              // Details
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Price",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color.outline,
                                        ),
                                      ),
                                      Text(
                                        stk.pricePerUnit.toAmount(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Qty
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        tr.qty,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color.outline,
                                        ),
                                      ),
                                      Text(
                                        stk.availableQuantity?.isEmpty == true ? "0" : stk.availableQuantity!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isOutOfStock ? color.error : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Total
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        tr.totalTitle,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color.outline,
                                        ),
                                      ),
                                      Text(
                                        stk.total.toAmount(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: color.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  int? storageId;
  String? baseCcy;
  String? myLocale;
  int? productId;
  int? isNoStock;

  String? _getBaseCurrency() {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        return authState.loginData.company?.comLocalCcy;
      }
      return "";
    } catch (e) {
      return "";
    }
  }
  @override
  void initState() {
    super.initState();
    baseCcy = _getBaseCurrency();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<ProductReportBloc>().add(ResetProductReportEvent());
  }

  bool get hasAnyFilter {
    return isNoStock != null ||
        storageId != null ||
        productId != null;
  }

  final productController = TextEditingController();
  void _clearFilters() {
    setState(() {
      isNoStock = null;
      productId = null;
      storageId = null;
      productController.clear(); // Clear the textfield
    });
    context.read<ProductReportBloc>().add(ResetProductReportEvent());
  }
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.surface);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("${tr.products} ${tr.report}"),
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          if(hasAnyFilter)...[
            ZOutlineButton(
                icon: Icons.filter_alt_off_outlined,
                backgroundHover: Theme.of(context).colorScheme.error,
                onPressed: _clearFilters,
                label: Text(tr.clearFilters)),
            SizedBox(width: 8),
          ],
          ZOutlineButton(
              icon: Icons.print,
              backgroundHover: Theme.of(context).colorScheme.error,
              onPressed: _printProductReport,
              label: Text(tr.print)),
          SizedBox(width: 8),
          ZOutlineButton(
              icon: Icons.filter_alt,
              isActive: true,
              onPressed: (){
                context.read<ProductReportBloc>().add(LoadProductsReportEvent(
                  isNoStock: isNoStock,
                  storageId: storageId,
                  productId: productId,
                ));
              },
              label: Text(tr.applyFilter)),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                // Product Selection
                Expanded(
                  child: GenericTextField<ProductsModel, ProductsBloc, ProductsState>(
                    title: tr.products,
                    controller: productController,
                    hintText: tr.products,
                    bloc: context.read<ProductsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadProductsEvent()),
                    searchFunction: (bloc, query) => bloc.add(LoadProductsEvent()),
                    itemBuilder: (context, product) {
                      // Check if this is the "All" option
                      if (product.proId == null) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            tr.all,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(product.proName ?? ''),
                      );
                    },
                    itemToString: (product) => product.proName ?? (product.proId == null ? tr.all : ''),
                    stateToLoading: (state) => state is ProductsLoadingState,
                    stateToItems: (state) {
                      if (state is ProductsLoadedState) return state.products;
                      return [];
                    },
                    onSelected: (product) {
                      setState(() {
                        // product will be null when "All" is selected
                        productId = product.proId; // This will be null for "All"
                      });
                    },
                    // Add "All" option configuration
                    showAllOption: true,
                    allOption: ProductsModel(
                      proId: null,
                      proName: tr.all,
                      proCode: '',
                    ),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: StorageDropDown(
                    height: 40,
                    title: tr.storage,
                    selectedId: storageId,
                    onChanged: (e){
                      setState(() {
                        storageId = e?.stgId;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: StatusDropdown(
                    height: 40,
                    items: [
                      StatusItem(null, tr.all),
                      StatusItem(1, tr.available),
                      StatusItem(2, tr.outOfStock),
                    ],
                    value: isNoStock,
                    onChanged: (e) {
                      setState(() {
                        isNoStock = e;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 15.0),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .8)
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 50,
                    child: Text("#",style: titleStyle)),
                SizedBox(
                    width: 150,
                    child: Text(tr.productCode,style: titleStyle)),
                Expanded(
                    child: Text(tr.productName,style: titleStyle)),
                SizedBox(
                    width: 150,
                    child: Text(tr.storage,style: titleStyle)),
                SizedBox(
                    width: 150,
                    child: Text(tr.unitPrice,style: titleStyle)),
                SizedBox(
                    width: 120,
                    child: Text(tr.qty,style: titleStyle)),
                SizedBox(
                    width: 120,
                    child: Text(tr.totalItems,style: titleStyle)),
                SizedBox(
                    width: 120,
                    child: Text(tr.totalAmount,style: titleStyle)),
              ],
            ),
          ),
          SizedBox(height: 5),
          Expanded(
            child: BlocBuilder<ProductReportBloc, ProductReportState>(
              builder: (context, state) {
                if(state is ProductReportErrorState){
                  return NoDataWidget(
                    title: tr.accessDenied,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if(state is ProductReportInitial){
                  return NoDataWidget(
                    title: "Inventory Overview",
                    message: "Stock Availability Summary",
                    enableAction: false,
                  );
                }
                if(state is ProductReportLoadingState){
                  return Center(child: CircularProgressIndicator());
                }
                if(state is ProductReportLoadedState){
                  if(state.stock.isEmpty){
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.stock.length,
                          itemBuilder: (context, index){
                            final stk = state.stock[index];
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              margin: EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                  color: index.isEven ? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 50, child: Text((index + 1).toString())),
                                  SizedBox(width: 150, child: Text(stk.proCode ?? "")),
                                  Expanded(child: Text(stk.proName ?? "")),
                                  SizedBox(width: 150, child: Text(stk.stgName ?? "")),
                                  SizedBox(width: 150, child: Text("${stk.pricePerUnit.toAmount()} $baseCcy")),
                                  SizedBox(width: 120, child: Text(stk.availableQuantity.toAmount(decimal: 0))),
                                  SizedBox(width: 120, child: Text(stk.totalItem.toAmount(decimal: 0))),
                                  SizedBox(width: 120, child: Text("${stk.total.toAmount(decimal: 2)} $baseCcy")),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
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
  Future<void> _printProductReport() async {
    final state = context.read<ProductReportBloc>().state;

    if (state is ProductReportLoadedState) {
      // Get company info
      final companyState = context.read<CompanyProfileBloc>().state;
      ReportModel company = ReportModel();

      if (companyState is CompanyProfileLoadedState) {
        company = ReportModel(
          comName: companyState.company.comName ?? '',
          comAddress: companyState.company.addName ?? '',
          compPhone: companyState.company.comPhone ?? '',
          comEmail: companyState.company.comEmail ?? '',
          statementDate: DateTime.now().toFullDateTime,
          comLogo: companyState.company.comLogo != null
              ? base64Decode(companyState.company.comLogo!)
              : null,
        );
      }

      // CHECK MOUNTED HERE - immediately after async operations
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => PrintPreviewDialog<List<ProductReportModel>>(
          data: state.stock,
          company: company,
          buildPreview: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return ProductReportPrintSettings().printPreview(
              products: data,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              baseCurrency: baseCcy,
              // REMOVED: storageId, storageName, productId, productName, stockStatus, statusName
            );
          },
          onPrint: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
            required selectedPrinter,
            required copies,
            required pages,
          }) {
            return ProductReportPrintSettings().printDocument(
              products: data,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              selectedPrinter: selectedPrinter,
              copies: copies,
              pages: pages,
              baseCurrency: baseCcy,
              // REMOVED: storageId, storageName, productId, productName, stockStatus, statusName
            );
          },
          onSave: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return ProductReportPrintSettings().createDocument(
              products: data,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              baseCurrency: baseCcy,
              // REMOVED: storageId, storageName, productId, productName, stockStatus, statusName
            );
          },
        ),
      );
    } else {
      if (!mounted) return;
      ToastManager.show(context: context, title: "Attention", message: "Please load the data first.", type: ToastType.warning);
    }
  }
}