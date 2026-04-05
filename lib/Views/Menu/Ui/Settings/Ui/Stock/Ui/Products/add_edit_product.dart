import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zform_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/section_title.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../ProductCategory/features/pro_cat_drop.dart';
import '../ProductCategory/model/pro_cat_model.dart';
import 'Features/GradeDrop/grade_drop.dart';
import 'Features/product_image.dart';
import 'bloc/products_bloc.dart';
import 'model/product_model.dart';
import 'dart:math';

class AddEditProductView extends StatelessWidget {
  final ProductsModel? model;
  const AddEditProductView({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileProductAddEdit(model: model),
      tablet: _TabletProductAddEdit(model: model),
      desktop: _DesktopProductAddEdit(model: model),
    );
  }
}

// Base class to share common functionality
class _BaseProductAddEdit extends StatefulWidget {
  final ProductsModel? model;
  final bool isMobile;
  final bool isTablet;

  const _BaseProductAddEdit({
    required this.model,
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

  @override
  void initState() {
    super.initState();
    if (widget.model != null) {
      productName.text = widget.model?.proName ?? "";
      productCode.text = widget.model?.proCode ?? "";
      madeIn.text = widget.model?.proMadeIn ?? "";
      details.text = widget.model?.proDetails ?? "";
      catId = widget.model?.proCategory;
      minimumStock.text = widget.model?.proLsNqty.toString() ?? "";
      productUnit.text = widget.model?.proUnit ?? "";
      productColor.text = widget.model?.proColor ?? "";
      productBrand.text = widget.model?.proBrand ?? "";
      productGrade = widget.model?.proGrade ?? "";
      productModel.text = widget.model?.proModel ?? "";

      w.text = widget.model?.proWeight?.toAmount() ?? "";
      l.text = widget.model?.proLength?.toAmount() ?? "";
      b.text = widget.model?.proBreadth?.toAmount() ?? "";
      weight.text = widget.model?.proWeight?.toAmount() ?? "";

      salePricePercentage.text = widget.model?.proSpp ?? "";
    }
    if (widget.model == null) {
      productCode.text = generateProductCode();
    }
  }

  @override
  void dispose() {
    productName.dispose();
    productCode.dispose();
    madeIn.dispose();
    details.dispose();
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

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
    final bloc = context.read<ProductsBloc>();
    final data = ProductsModel(
      proId: widget.model?.proId,
      proCode: productCode.text,
      proName: productName.text,
      proMadeIn: madeIn.text,
      proCategory: _selectedCategory?.pcId,
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
    if (widget.model != null) {
      bloc.add(UpdateProductEvent(data));
    } else {
      bloc.add(AddProductEvent(data));
    }
  }

  // Build action button based on screen size and state
  Widget _buildActionButton(AppLocalizations tr, ColorScheme color, bool isEdit) {
    if (widget.isMobile) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (context.watch<ProductsBloc>().state is ProductsLoadingState)
              ? null
              : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.primary,
            foregroundColor: color.surface,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: (context.watch<ProductsBloc>().state is ProductsLoadingState)
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
      return (context.watch<ProductsBloc>().state is ProductsLoadingState)
          ? SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          color: color.surface,
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
    final isEdit = widget.model != null;

    if (widget.isMobile) {
      // Mobile full-screen dialog
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          margin: EdgeInsets.zero,
          color: color.surface,
          child: Column(
            children: [
              // Header with gradient
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
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: formKey,
                    child: BlocBuilder<ProductsBloc, ProductsState>(
                      builder: (context, state) {
                        return Column(
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

                            const SizedBox(height: 24),

                            // Action Button
                            _buildActionButton(tr, color, isEdit),

                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (widget.isTablet) {
      // Tablet dialog
      return ZFormDialog(
        onAction: onSubmit,
        title: isEdit ? tr.update : tr.newKeyword,
        actionLabel: _buildActionButton(tr, color, isEdit),
        width: 550,
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: BlocBuilder<ProductsBloc, ProductsState>(
              builder: (context, state) {
                return SingleChildScrollView(
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
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else {
      // Desktop dialog (existing)
      return BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          return ZFormDialog(
            width: MediaQuery.of(context).size.width *.75,
            icon: Icons.production_quantity_limits_rounded,

            onAction: onSubmit,
            title: isEdit ? tr.update.toUpperCase() : tr.newKeyword,
            actionLabel: state is ProductsLoadingState
                ? SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: color.surface,
              ),
            )
                : Text(isEdit ? tr.update : tr.create),
            child: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        spacing: 10,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ZCover(
                              radius: 8,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    spacing: 5,
                                    children: [
                                      SectionTitle(title: tr.nameAndDescription),
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

                                      ZTextFieldEntitled(
                                        title: tr.details,
                                        controller: details,
                                        keyboardInputType: TextInputType.multiline,
                                        maxLength: 100,
                                      ),
                                      SizedBox()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ZCover(
                              radius: 8,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    spacing: 15,
                                    children: [
                                      SectionTitle(title: tr.productDetails),
                                      Row(
                                        spacing: 8,
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
                                          Expanded(
                                            child: ZTextFieldEntitled(
                                              title: tr.unit,
                                              hint: "مثال، دانه، جوره، قطی",
                                              suggestions: ["دانه", "جوره", "حلقه","قطی","سیت"],
                                              showClearButton: true,
                                              controller: productUnit,
                                            ),
                                          ),
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
                                      Row(
                                        spacing: 8,
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
                                          Expanded(
                                            child: ZTextFieldEntitled(
                                              title: tr.productModel,
                                              hint: "مثال، هندا، اسکارت، دوپلکه",
                                              suggestions: ["هندا", "اسکارت", "دوپلکه"],
                                              showClearButton: true,
                                              controller: productModel,
                                            ),
                                          ),
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
                                      Row(
                                        spacing: 8,
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
                                          Expanded(
                                            child: ZTextFieldEntitled(
                                              title: tr.minimumStock,
                                              hint: "مثال، 10 یا 20",
                                              controller: minimumStock,
                                            ),
                                          ),
                                          Expanded(
                                            child: ZTextFieldEntitled(
                                              title: tr.salePrice,
                                              hint: "%20, 30%",
                                              controller: salePricePercentage,
                                              end: Text("%"),
                                              keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                                              inputFormat: [
                                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Allows decimals up to 2 places
                                              ],
                                              validator: (value) {
                                                if (value == null || value.isEmpty) return null;

                                                final cleanValue = value.replaceAll('%', '').replaceAll(' ', '').trim();
                                                if (cleanValue.isEmpty) return null;

                                                // Parse as double to handle decimal values
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
                                      SizedBox()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        spacing: 10,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ZCover(
                              radius: 8,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ProductImageCarousel(
                                      images: productImages,
                                      maxImages: 5,
                                      onImagesChanged: (images) {
                                        setState(() {
                                          productImages.clear();
                                          productImages.addAll(images);
                                        });
                                        // You can dispatch to bloc here if needed
                                        // context.read<ProductsBloc>().add(UpdateProductImagesEvent(images));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 205,
                            child: ZCover(
                              radius: 8,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    spacing: 10,
                                    children: [
                                      SectionTitle(title: tr.shippingDetails),
                                      ZTextFieldEntitled(
                                        title: tr.weight,
                                        hint: "30 Kg",
                                        controller: weight,
                                      ),
                                      Row(
                                        spacing: 8,
                                        children: [
                                          Expanded(
                                            child: ZTextFieldEntitled(
                                              title: tr.lenghtTitle,
                                              hint: "12 cm",
                                              controller: l,
                                            ),
                                          ),
                                          Expanded(
                                            child: ZTextFieldEntitled(
                                              title: tr.breadth,
                                              hint: "12 cm",
                                              controller: b,
                                            ),
                                          ),
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
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}

// Mobile View
class _MobileProductAddEdit extends StatelessWidget {
  final ProductsModel? model;

  const _MobileProductAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseProductAddEdit(
      model: model,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletProductAddEdit extends StatelessWidget {
  final ProductsModel? model;

  const _TabletProductAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseProductAddEdit(
      model: model,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopProductAddEdit extends StatelessWidget {
  final ProductsModel? model;

  const _DesktopProductAddEdit({this.model});

  @override
  Widget build(BuildContext context) {
    return _BaseProductAddEdit(
      model: model,
      isMobile: false,
      isTablet: false,
    );
  }
}