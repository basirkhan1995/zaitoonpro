import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zform_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/%D9%8FSingleProduct/single_product_bloc.dart';
import '../ProductCategory/features/pro_cat_drop.dart';
import '../ProductCategory/model/pro_cat_model.dart';
import 'Features/GradeDrop/grade_drop.dart';
import 'Features/product_image.dart';
import 'bloc/products_bloc.dart';
import 'model/product_model.dart';
import 'dart:math';

class AddEditProductView extends StatelessWidget {
  final int? proId;
  const AddEditProductView({super.key, this.proId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileProductAddEdit(proId: proId),
      tablet: _TabletProductAddEdit(proId: proId),
      desktop: _DesktopProductAddEdit(proId: proId),
    );
  }
}

// Base class to share common functionality
class _BaseProductAddEdit extends StatefulWidget {
  final int? proId;
  final bool isMobile;
  final bool isTablet;

  const _BaseProductAddEdit({
    required this.proId,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseProductAddEdit> createState() => _BaseProductAddEditState();
}

class _BaseProductAddEditState extends State<_BaseProductAddEdit> {
  final formKey = GlobalKey<FormState>();

  final productName = TextEditingController();
  final productCode = TextEditingController();
  final madeIn = TextEditingController();
  final productUnit = TextEditingController();
  final productColor = TextEditingController();
  final productModel = TextEditingController();
  final productBrand = TextEditingController();
  final minimumStock = TextEditingController();
  final List<Uint8List> productImages = [];
  final l = TextEditingController();
  final w = TextEditingController();
  final b = TextEditingController();
  final weight = TextEditingController();
  final salePricePercentage = TextEditingController();

  final details = TextEditingController();
  String? productGrade = "A";

  int? catId;
  ProCategoryModel? _selectedCategory;

  // Store the loaded product from API
  ProductsModel? _loadedProduct;
  bool _isLoadingProduct = false;

  @override
  void initState() {
    super.initState();

    if (widget.proId != null) {
      // Editing existing product - fetch data by ID
      _isLoadingProduct = true;
      context.read<SingleProductBloc>().add(LoadSingleProductEvent(widget.proId!));
    } else {
      // New product - just generate code and clear any old state
      context.read<SingleProductBloc>().add(ClearSingleProductEvent());
      productCode.text = generateProductCode();
      _clearAllControllers(); // Clear any existing data
    }
  }

  void _clearAllControllers() {
    productName.clear();
    productCode.text = generateProductCode();
    madeIn.clear();
    details.clear();
    catId = null;
    minimumStock.clear();
    productUnit.clear();
    productColor.clear();
    productBrand.clear();
    productGrade = "A";
    productModel.clear();
    w.clear();
    l.clear();
    b.clear();
    weight.clear();
    salePricePercentage.clear();
    _selectedCategory = null;
    _loadedProduct = null;
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
    final bloc = context.read<ProductsBloc>();
    final data = ProductsModel(
      proId: widget.proId ?? _loadedProduct?.proId,
      proCode: productCode.text,
      proName: productName.text,
      proMadeIn: madeIn.text,
      proCategory: _selectedCategory?.pcId ?? catId,
      proDetails: details.text,
      proBrand: productBrand.text,
      proModel: productModel.text,
      proColor: productColor.text,
      proGrade: productGrade,
      proLsNqty: int.tryParse(minimumStock.text),
      proUnit: productUnit.text,
      proWidth: w.text,
      proLength: l.text,
      proBreadth: b.text,
      proWeight: weight.text,
      proSpp: salePricePercentage.text,
      proStatus: 1,
    );
    if (widget.proId != null || _loadedProduct != null) {
      bloc.add(UpdateProductEvent(data));
    } else {
      bloc.add(AddProductEvent(data));
    }
  }



  // Update controllers from loaded product
  void _updateControllersFromLoadedProduct(ProductsModel product) {
    if (mounted) {
      productName.text = product.proName ?? "";
      productCode.text = product.proCode ?? "";
      madeIn.text = product.proMadeIn ?? "";
      details.text = product.proDetails ?? "";
      catId = product.proCategory;
      minimumStock.text = product.proLsNqty?.toString() ?? "";
      productUnit.text = product.proUnit ?? "";
      productColor.text = product.proColor ?? "";
      productBrand.text = product.proBrand ?? "";
      productGrade = product.proGrade ?? "";
      productModel.text = product.proModel ?? "";
      w.text = product.proWidth?.toAmount() ?? "";
      l.text = product.proLength?.toAmount() ?? "";
      b.text = product.proBreadth?.toAmount() ?? "";
      weight.text = product.proWeight?.toAmount() ?? "";
      salePricePercentage.text = product.proSpp ?? "";

      _loadedProduct = product;
      _isLoadingProduct = false;
    }
  }

  @override
  void dispose() {
    productName.dispose();
    productCode.dispose();
    madeIn.dispose();
    details.dispose();
    productUnit.dispose();
    productColor.dispose();
    productModel.dispose();
    productBrand.dispose();
    minimumStock.dispose();
    l.dispose();
    w.dispose();
    b.dispose();
    weight.dispose();
    salePricePercentage.dispose();
    super.dispose();
  }

  String generateProductCode({String prefix = 'PRD'}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final now = DateTime.now();

    final batch = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    final date = '${now.year % 100}${now.month.toString().padLeft(2, '0')}';
    return '$prefix-$date-$batch';
  }

  void _showDeleteConfirmation(AppLocalizations tr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close product dialog
              context.read<ProductsBloc>().add(DeleteProductEvent(widget.proId!));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBatchesSection(List<Batch> batches, AppLocalizations tr, ColorScheme color, TextTheme textTheme) {
    final totalBox = batches.fold(0, (sum, batch) =>
    sum + (int.tryParse(batch.availableQuantity ?? "0") ?? 0)
    );

    final totalItems = batches.fold(0, (sum, batch) {
      final quantity = int.tryParse(batch.availableQuantity ?? "0") ?? 0;
      final batchNumber = batch.batch ?? 0;
      return sum + (quantity * batchNumber);
    });

    return Container(
      margin: const EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outline.withValues(alpha: .1)),
      ),
      child: Column(
        children: [
          // Header with Primary Color
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory, size: 20, color: color.onPrimary),
                const SizedBox(width: 8),
                Text(
                  "Stock Batches",
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.onPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.onPrimary.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    "${batches.length} ${tr.batchTitle}",
                    style: TextStyle(
                      fontSize: 12,
                      color: color.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .05),
              border: Border(
                bottom: BorderSide(color: color.outline.withValues(alpha: .1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    tr.storage,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    tr.batchTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr.qty,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr.totalItems,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batches.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: color.outline.withValues(alpha: .1),
            ),
            itemBuilder: (context, index) {
              final batch = batches[index];
              final quantity = int.tryParse(batch.availableQuantity ?? "0") ?? 0;
              final batchNumber = batch.batch ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        batch.storage?.toString() ?? "N/A",
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "$batchNumber",
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        quantity.toString(),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: quantity > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (quantity * batchNumber).toString(),
                        textAlign: TextAlign.right,
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        tr.totalQty.toUpperCase(),
                        style: textTheme.titleMedium?.copyWith(color: color.outline),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        totalBox.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        tr.totalItems.toUpperCase(),
                        style: textTheme.titleMedium?.copyWith(color: color.outline),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        totalItems.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: color.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDeleteButton(AppLocalizations tr, ColorScheme color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton.icon(
        onPressed: () => _showDeleteConfirmation(tr),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: Text(
          tr.delete,
          style: const TextStyle(color: Colors.red),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
  Widget _buildActionButton(AppLocalizations tr, ColorScheme color, bool isEdit, dynamic state) {
    final isLoading = state is ProductsLoadingState;

    if (widget.isMobile) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.primary,
            foregroundColor: color.surface,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: color.surface,
            ),
          )
              : Text(
            isEdit ? tr.update : tr.create,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return isLoading
          ? SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          color: color.primary,
        ),
      )
          : Text(isEdit ? tr.update : tr.create);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.proId != null;

    if (widget.isMobile) {
      // Mobile dialog using SingleProductBloc
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: BlocListener<SingleProductBloc, SingleProductState>(
          listener: (context, state) {
            if (state is SingleProductLoadedState && _isLoadingProduct) {
              _updateControllersFromLoadedProduct(state.product);
            }
            if (state is ProductsSuccessState) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            margin: EdgeInsets.zero,
            color: color.surface,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.primary,
                        color.primary.withValues(alpha: .8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? tr.update : tr.newKeyword,
                              style: textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEdit ? tr.edit : tr.newKeyword,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: .8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: BlocBuilder<SingleProductBloc, SingleProductState>(
                      builder: (context, state) {
                        if (state is SingleProductLoadingState && _isLoadingProduct) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        return Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Product Code
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: .05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ZTextFieldEntitled(
                                  title: tr.productCode,
                                  controller: productCode,
                                  maxLength: 13,
                                  isRequired: true,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return tr.required(tr.productCode);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Product Name
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: .05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ZTextFieldEntitled(
                                  title: tr.productName,
                                  controller: productName,
                                  isRequired: true,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return tr.required(tr.productName);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Category Dropdown
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: .05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ProductCategoryDropdown(
                                  selectedCategoryId: catId,
                                  onCategorySelected: (cat) {
                                    _selectedCategory = cat;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Made In
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: .05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ZTextFieldEntitled(
                                  title: tr.madeIn,
                                  controller: madeIn,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Details
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: .05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ZTextFieldEntitled(
                                  title: tr.details,
                                  controller: details,
                                  keyboardInputType: TextInputType.multiline,
                                  maxLength: 100,
                                ),
                              ),
                              // Show batches if available
                              if (state is SingleProductLoadedState &&
                                  state.product.batches != null &&
                                  state.product.batches!.isNotEmpty)
                                _buildBatchesSection(state.product.batches!, tr, color, textTheme),
                              // Delete button for edit mode
                              if (isEdit)
                                _buildDeleteButton(tr, color),
                              const SizedBox(height: 24),
                              // Action Button
                              _buildActionButton(tr, color, isEdit, state),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (widget.isTablet) {
      // Tablet dialog
      return BlocListener<SingleProductBloc, SingleProductState>(
        listener: (context, state) {
          if (state is SingleProductLoadedState && _isLoadingProduct) {
            _updateControllersFromLoadedProduct(state.product);
          }
          if (state is ProductsSuccessState) {
            Navigator.of(context).pop();
          }
        },
        child: ZFormDialog(
          onAction: onSubmit,
          title: isEdit ? tr.update : tr.newKeyword,
          actionLabel: _buildActionButton(tr, color, isEdit, context.watch<ProductsBloc>().state),
          width: 650,
          child: BlocBuilder<SingleProductBloc, SingleProductState>(
            builder: (context, state) {
              if (state is SingleProductLoadingState && _isLoadingProduct) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      spacing: 12,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ZTextFieldEntitled(
                          title: tr.productCode,
                          controller: productCode,
                          maxLength: 13,
                          isRequired: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return tr.required(tr.productCode);
                            }
                            return null;
                          },
                        ),
                        ZTextFieldEntitled(
                          title: tr.productName,
                          controller: productName,
                          isRequired: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return tr.required(tr.productName);
                            }
                            return null;
                          },
                        ),
                        ProductCategoryDropdown(
                          selectedCategoryId: catId,
                          onCategorySelected: (cat) {
                            _selectedCategory = cat;
                          },
                        ),
                        ZTextFieldEntitled(
                          title: tr.madeIn,
                          controller: madeIn,
                        ),
                        ZTextFieldEntitled(
                          title: tr.details,
                          controller: details,
                          keyboardInputType: TextInputType.multiline,
                          maxLength: 100,
                        ),
                        if (state is SingleProductLoadedState &&
                            state.product.batches != null &&
                            state.product.batches!.isNotEmpty)
                          _buildBatchesSection(state.product.batches!, tr, color, textTheme),
                        if (isEdit)
                          _buildDeleteButton(tr, color),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Desktop dialog
      return BlocListener<SingleProductBloc, SingleProductState>(
        listener: (context, state) {
          if (state is SingleProductLoadedState && _isLoadingProduct) {
            _updateControllersFromLoadedProduct(state.product);
          }
          if (state is ProductsSuccessState) {
            Navigator.of(context).pop();
          }
        },
        child: BlocBuilder<SingleProductBloc, SingleProductState>(
          builder: (context, state) {
            if (state is SingleProductLoadingState && _isLoadingProduct) {
              return Center(
                child: ZFormDialog(
                  width: MediaQuery.of(context).size.width * .75,
                  icon: Icons.production_quantity_limits_rounded,
                  onAction: () {},
                  title: isEdit ? tr.update.toUpperCase() : tr.newKeyword,

                  actionLabel: const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              );
            }

            return ZFormDialog(
              width: MediaQuery.of(context).size.width * .85,
              icon: Icons.production_quantity_limits_rounded,
              onAction: onSubmit,
              title: isEdit ? tr.update.toUpperCase() : tr.newKeyword,
              actionLabel: _buildActionButton(tr, color, isEdit, context.watch<ProductsBloc>().state),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column
                            Expanded(
                              flex: 6,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSection(
                                      title: tr.nameAndDescription,
                                      children: [
                                        ZTextFieldEntitled(
                                          title: tr.productCode,
                                          controller: productCode,
                                          maxLength: 13,
                                          isRequired: true,
                                          validator: (value) {
                                            if (value.isEmpty) {
                                              return tr.required(tr.productCode);
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        ZTextFieldEntitled(
                                          title: tr.productName,
                                          controller: productName,
                                          isRequired: true,
                                          validator: (value) {
                                            if (value.isEmpty) {
                                              return tr.required(tr.productName);
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        ZTextFieldEntitled(
                                          title: tr.details,
                                          controller: details,
                                          keyboardInputType: TextInputType.multiline,
                                          maxLength: 100,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: _buildSection(
                                        title: tr.productDetails,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: GradeDropdown(
                                                  selectedGrade: productGrade,
                                                  onGradeSelected: (grade) {
                                                    setState(() {
                                                      productGrade = grade;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ZTextFieldEntitled(
                                                  title: tr.unit,
                                                  hint: "مثال، دانه، جوره، قطی",
                                                  suggestions: ["دانه", "جوره", "حلقه","قطی","سیت"],
                                                  showClearButton: true,
                                                  controller: productUnit,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ProductCategoryDropdown(
                                                  selectedCategoryId: catId,
                                                  onCategorySelected: (cat) {
                                                    _selectedCategory = cat;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ZTextFieldEntitled(
                                                  title: tr.productBrands,
                                                  hint: "مثال، کیهان، امر، کمپنی",
                                                  suggestions: ["کیهان", "امر", "کمپنی"],
                                                  showClearButton: true,
                                                  controller: productBrand,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ZTextFieldEntitled(
                                                  title: tr.productModel,
                                                  hint: "مثال، هندا، اسکارت، دوپلکه",
                                                  suggestions: ["هندا", "اسکارت", "دوپلکه"],
                                                  showClearButton: true,
                                                  controller: productModel,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ZTextFieldEntitled(
                                                  title: tr.madeIn,
                                                  hint: "مثال، چین، پاکستان، ایران",
                                                  suggestions: ["چین", "پاکستان", "ایران"],
                                                  showClearButton: true,
                                                  controller: madeIn,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ZTextFieldEntitled(
                                                  title: tr.productColor,
                                                  hint: "مثال، سفید، سیاه",
                                                  suggestions: ["سیاه", "سفید", "سرخ","جگری","زرد"],
                                                  showClearButton: true,
                                                  controller: productColor,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ZTextFieldEntitled(
                                                  title: tr.minimumStock,
                                                  hint: "مثال، 10 یا 20",
                                                  controller: minimumStock,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ZTextFieldEntitled(
                                                  title: tr.salePrice,
                                                  hint: "%20, 30%",
                                                  controller: salePricePercentage,
                                                  end: const Text("%"),
                                                  keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                                                  inputFormat: [
                                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                                  ],
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;
                                                    final cleanValue = value.replaceAll('%', '').replaceAll(' ', '').trim();
                                                    if (cleanValue.isEmpty) return null;
                                                    final number = double.tryParse(cleanValue);
                                                    if (number == null) return 'Please enter a valid number';
                                                    if (number < 0) return 'Cannot be negative';
                                                    if (number > 100) return 'Maximum 100%';
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Right column
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSection(
                                      title: "Product Images",
                                      children: [
                                        ProductImageCarousel(
                                          images: productImages,
                                          maxImages: 5,
                                          onImagesChanged: (images) {
                                            setState(() {
                                              productImages.clear();
                                              productImages.addAll(images);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildSection(
                                      title: tr.shippingDetails,
                                      children: [
                                        ZTextFieldEntitled(
                                          title: tr.weight,
                                          hint: "30 Kg",
                                          controller: weight,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ZTextFieldEntitled(
                                                title: tr.lenghtTitle,
                                                hint: "12 cm",
                                                controller: l,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ZTextFieldEntitled(
                                                title: tr.breadth,
                                                hint: "12 cm",
                                                controller: b,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ZTextFieldEntitled(
                                                title: tr.widthTitle,
                                                hint: "12 cm",
                                                controller: w,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state is SingleProductLoadedState &&
                          state.product.batches != null &&
                          state.product.batches!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildBatchesSection(state.product.batches!, tr, color, textTheme),
                      ],
                      if (isEdit) ...[
                        const SizedBox(height: 16),
                        _buildDeleteButton(tr, color),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

// Mobile View
class _MobileProductAddEdit extends StatelessWidget {
  final int? proId;
  const _MobileProductAddEdit({this.proId});

  @override
  Widget build(BuildContext context) {
    return _BaseProductAddEdit(
      proId: proId,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletProductAddEdit extends StatelessWidget {
  final int? proId;
  const _TabletProductAddEdit({this.proId});

  @override
  Widget build(BuildContext context) {
    return _BaseProductAddEdit(
      proId: proId,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopProductAddEdit extends StatelessWidget {
  final int? proId;
  const _DesktopProductAddEdit({this.proId});

  @override
  Widget build(BuildContext context) {
    return _BaseProductAddEdit(
      proId: proId,
      isMobile: false,
      isTablet: false,
    );
  }
}