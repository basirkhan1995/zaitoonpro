import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../bloc/pro_cat_bloc.dart';
import '../model/pro_cat_model.dart';

class ProductCategoryDropdown extends StatefulWidget {
  /// Category ID from Product (EDIT mode)
  final int? selectedCategoryId;

  /// Whether to show "All" option in dropdown
  final bool showAllOption;

  /// Returns FULL model, null when "All" is selected (if showAllOption is true)
  final ValueChanged<ProCategoryModel?> onCategorySelected;

  const ProductCategoryDropdown({
    super.key,
    this.selectedCategoryId,
    this.showAllOption = false,
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

    // When external selectedCategoryId becomes null (on clear)
    if (widget.selectedCategoryId == null && oldWidget.selectedCategoryId != null) {
      setState(() {
        _selectedCategory = null;
        widget.onCategorySelected(null);
      });
    }
    // When external selectedCategoryId changes to a new value, find and select it
    else if (widget.selectedCategoryId != null &&
        widget.selectedCategoryId != oldWidget.selectedCategoryId &&
        _categories.isNotEmpty) {
      setState(() {
        _selectedCategory = _categories.firstWhere(
              (c) => c.pcId == widget.selectedCategoryId,
          orElse: () {
            if (widget.showAllOption) {
              return _categories.firstWhere(
                    (c) => c.pcId == null,
                orElse: () => _categories.first,
              );
            }
            return _categories.first;
          },
        );
      });

      if (_selectedCategory != null) {
        widget.onCategorySelected(
            (widget.showAllOption && _selectedCategory!.pcId == null)
                ? null
                : _selectedCategory
        );
      }
    }
  }

  void _onSelect(ProCategoryModel cat) {
    setState(() => _selectedCategory = cat);
    // Pass null when "All" is selected and showAllOption is true
    widget.onCategorySelected(
        (widget.showAllOption && cat.pcId == null) ? null : cat
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProCatBloc, ProCatState>(
      listener: (context, state) {
        if (state is ProCatLoadedState) {
          setState(() {
            // Prepare items list
            _categories = [];

            // Add "All" option if enabled
            if (widget.showAllOption) {
              final allOption = ProCategoryModel(
                pcId: null,
                pcName: AppLocalizations.of(context)!.all,
              );
              _categories.add(allOption);
            }

            // Add actual categories
            _categories.addAll(state.proCategory);

            if (_categories.isEmpty) {
              _selectedCategory = null;
              return;
            }

            // EDIT mode → map ID to model
            if (widget.selectedCategoryId != null) {
              _selectedCategory = _categories.firstWhere(
                    (c) => c.pcId == widget.selectedCategoryId,
                orElse: () {
                  if (widget.showAllOption) {
                    return _categories.firstWhere(
                          (c) => c.pcId == null,
                      orElse: () => _categories.first,
                    );
                  }
                  return _categories.first;
                },
              );
            }
            // ADD mode → select first item (or "All" if enabled)
            else if (widget.selectedCategoryId == null && !widget.showAllOption) {
              // When no "All" option and no selectedCategoryId, keep null to show title
              _selectedCategory = null;
            }
            else {
              if (widget.showAllOption) {
                _selectedCategory = _categories.firstWhere(
                      (c) => c.pcId == null,
                  orElse: () => _categories.first,
                );
              } else {
                _selectedCategory = _categories.first;
              }
            }
          });

          if (_selectedCategory != null) {
            widget.onCategorySelected(
                (widget.showAllOption && _selectedCategory!.pcId == null)
                    ? null
                    : _selectedCategory
            );
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