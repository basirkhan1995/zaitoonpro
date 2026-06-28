import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/GlCategories/bloc/gl_category_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/GlCategories/model/cat_model.dart';
import '../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';

class GlSubCategoriesDrop extends StatefulWidget {
  final int mainCategoryId;
  final String? title;
  final double height;
  final bool disableAction;

  /// Returns FULL model, null when "All" is selected
  final ValueChanged<GlCategoriesModel?>? onChanged;
  final GlCategoriesModel? initiallySelected;

  /// Whether to show "All" option in dropdown
  final bool showAllOption;

  const GlSubCategoriesDrop({
    super.key,
    this.height = 40,
    this.disableAction = false,
    this.onChanged,
    this.title,
    required this.mainCategoryId,
    this.initiallySelected,
    this.showAllOption = false,
  });

  @override
  State<GlSubCategoriesDrop> createState() => _GlSubCategoriesDropState();
}

class _GlSubCategoriesDropState extends State<GlSubCategoriesDrop> {
  GlCategoriesModel? _selectedSingle;
  List<GlCategoriesModel> _categories = [];
  bool _initialized = false;
  bool _hasNotifiedInitial = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  @override
  void didUpdateWidget(covariant GlSubCategoriesDrop oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mainCategoryId != widget.mainCategoryId) {
      _initialized = false;
      _hasNotifiedInitial = false;
      _selectedSingle = null;
      _categories = [];
      _loadSubCategories();
    }

    // When external initiallySelected becomes null (on clear)
    if (widget.initiallySelected == null && oldWidget.initiallySelected != null) {
      setState(() {
        _selectedSingle = null;
      });
      widget.onChanged?.call(null);
    }
    // When external initiallySelected changes to a new value
    else if (widget.initiallySelected != null &&
        widget.initiallySelected != oldWidget.initiallySelected &&
        _categories.isNotEmpty) {
      _selectCategoryById(widget.initiallySelected!.acgId!);
    }
  }

  void _loadSubCategories() {
    setState(() {
      _isLoading = true;
    });
    context
        .read<GlCategoryBloc>()
        .add(LoadGlCategoriesEvent(widget.mainCategoryId));
  }

  void _selectCategoryById(int categoryId) {
    final found = _categories.firstWhere(
          (c) => c.acgId == categoryId,
      orElse: () {
        if (widget.showAllOption) {
          return _categories.firstWhere(
                (c) => c.acgId == null,
            orElse: () => _categories.first,
          );
        }
        return _categories.first;
      },
    );

    if (found != _selectedSingle) {
      setState(() {
        _selectedSingle = found;
      });

      // Notify with null for "All" option
      final valueToSend = (widget.showAllOption && found.acgId == null) ? null : found;
      widget.onChanged?.call(valueToSend);
    }
  }

  void _selectDefaultCategory() {
    if (_categories.isEmpty) return;

    GlCategoriesModel? defaultCategory;

    if (widget.initiallySelected != null) {
      // Find by ID
      defaultCategory = _categories.firstWhere(
            (c) => c.acgId == widget.initiallySelected!.acgId,
        orElse: () => _categories.first,
      );
    } else if (widget.showAllOption) {
      // Select "All" option
      defaultCategory = _categories.firstWhere(
            (c) => c.acgId == null,
        orElse: () => _categories.first,
      );
    } else {
      // Select first category
      defaultCategory = _categories.first;
    }

    setState(() {
      _selectedSingle = defaultCategory;
    });

    // Notify with null for "All" option
    final valueToSend = (widget.showAllOption && defaultCategory.acgId == null)
        ? null
        : defaultCategory;

    if (!_hasNotifiedInitial || _selectedSingle != defaultCategory) {
      widget.onChanged?.call(valueToSend);
      _hasNotifiedInitial = true;
    }
  }

  void _onSelect(GlCategoriesModel cat) {
    setState(() => _selectedSingle = cat);
    // Pass null when "All" is selected and showAllOption is true
    widget.onChanged?.call(
      (widget.showAllOption && cat.acgId == null) ? null : cat,
    );
  }

  void _updateCategories(List<GlCategoriesModel> newCategories) {
    setState(() {
      _categories = newCategories;
      _isLoading = false;
    });

    // Select default category after loading
    if (_categories.isNotEmpty && !_initialized) {
      _selectDefaultCategory();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GlCategoryBloc, GlCategoryState>(
      listener: (context, state) {
        if (state is GlCategoryLoadedState) {
          // Build categories list with "All" option if enabled
          final List<GlCategoriesModel> newCategories = [];

          // Add "All" option if enabled
          if (widget.showAllOption) {
            final allOption = GlCategoriesModel(
              acgId: null,
              acgName: AppLocalizations.of(context)!.all,
            );
            newCategories.add(allOption);
          }

          // Add actual categories
          newCategories.addAll(state.glCat);

          // Update categories
          _updateCategories(newCategories);
        } else if (state is GlCategoryLoadingState) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is GlCategoryErrorState) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: Builder(
        builder: (context) {
          /// ---------------- TITLE ----------------
          Widget buildTitle() {
            final titleText = widget.title ?? AppLocalizations.of(context)!.currencyTitle;
            if (_isLoading) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titleText,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              );
            }

            return Text(
              titleText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
            );
          }

          /// If categories list is empty and not loading, show appropriate message
          if (_categories.isEmpty && !_isLoading) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.noDataFound,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }

          /// ---------------- DROPDOWN ----------------
          return ZDropdown<GlCategoriesModel>(
            disableAction: widget.disableAction,
            title: '',
            height: widget.height,
            items: _categories,
            selectedItem: _selectedSingle,
            itemLabel: (item) => item.acgName ?? '',
            onItemSelected: _onSelect,
            isLoading: _isLoading,
            itemStyle: Theme.of(context).textTheme.bodyMedium,
            customTitle: (widget.title != null && widget.title!.isNotEmpty)
                ? buildTitle()
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}