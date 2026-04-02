import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../bloc/pro_cat_bloc.dart';
import '../model/pro_cat_model.dart';

class ProductCategoryDropdown extends StatefulWidget {
  /// Category ID from Product (EDIT mode)
  final int? selectedCategoryId;

  /// Returns FULL model
  final ValueChanged<ProCategoryModel> onCategorySelected;

  const ProductCategoryDropdown({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<ProductCategoryDropdown> createState() =>
      _ProductCategoryDropdownState();
}

class _ProductCategoryDropdownState extends State<ProductCategoryDropdown> {
  ProCategoryModel? _selectedCategory;
  List<ProCategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();

    // Load categories once after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProCatBloc>().add(LoadProCatEvent());
    });
  }

  @override
  void didUpdateWidget(covariant ProductCategoryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If selectedCategoryId changes (edit / rebuild)
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId &&
        _categories.isNotEmpty) {
      setState(() {
        _selectedCategory = _categories.firstWhere(
              (c) => c.pcId == widget.selectedCategoryId,
          orElse: () => _categories.first,
        );
      });

      if (_selectedCategory != null) {
        widget.onCategorySelected(_selectedCategory!);
      }
    }
  }

  void _onSelect(ProCategoryModel cat) {
    setState(() => _selectedCategory = cat);
    widget.onCategorySelected(cat);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProCatBloc, ProCatState>(
      listener: (context, state) {
        if (state is ProCatLoadedState) {
          setState(() {
            _categories = state.proCategory;

            if (_categories.isEmpty) {
              _selectedCategory = null;
              return;
            }

            // EDIT mode → map ID to model
            if (widget.selectedCategoryId != null) {
              _selectedCategory = _categories.firstWhere(
                    (c) => c.pcId == widget.selectedCategoryId,
                orElse: () => _categories.first,
              );
            }
            // ADD mode → select first
            else {
              _selectedCategory = _categories.first;
            }
          });

          if (_selectedCategory != null) {
            widget.onCategorySelected(_selectedCategory!);
          }
        }
      },
      child: ZDropdown<ProCategoryModel>(
        title: AppLocalizations.of(context)!.categoryTitle,
        items: _categories,
        isLoading: _categories.isEmpty,
        selectedItem: _selectedCategory,
        itemLabel: (cat) => cat.pcName ?? "",
        onItemSelected: _onSelect,
      ),
    );
  }
}
