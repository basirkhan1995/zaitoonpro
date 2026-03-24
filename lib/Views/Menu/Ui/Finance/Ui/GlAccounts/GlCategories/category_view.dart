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
  final ValueChanged<GlCategoriesModel?>? onChanged;
  final GlCategoriesModel? initiallySelected;

  const GlSubCategoriesDrop({
    super.key,
    this.height = 40,
    this.disableAction = false,
    this.onChanged,
    this.title,
    required this.mainCategoryId,
    this.initiallySelected,
  });

  @override
  State<GlSubCategoriesDrop> createState() => _GlSubCategoriesDropState();
}

class _GlSubCategoriesDropState extends State<GlSubCategoriesDrop> {
  GlCategoriesModel? _selectedSingle;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  /// This runs when mainCategoryId changes
  @override
  void didUpdateWidget(covariant GlSubCategoriesDrop oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mainCategoryId != widget.mainCategoryId) {
      _initialized = false;
      _selectedSingle = null;

      _loadSubCategories();
    }
  }

  void _loadSubCategories() {
    context
        .read<GlCategoryBloc>()
        .add(LoadGlCategoriesEvent(widget.mainCategoryId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlCategoryBloc, GlCategoryState>(
      builder: (context, state) {
        final bool isLoading = state is GlCategoryLoadingState;

        /// ---------------- TITLE ----------------
        Widget buildTitle() {
          final titleText = widget.title ?? AppLocalizations.of(context)!.currencyTitle;
          if (isLoading) {
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

        /// -------- AUTO SELECT FIRST ITEM (PER CATEGORY) --------
        if (state is GlCategoryLoadedState &&
            !_initialized &&
            state.glCat.isNotEmpty) {
          _selectedSingle = state.glCat.first;
          _initialized = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged?.call(_selectedSingle);
          });
        }

        if (state is GlCategoryErrorState) {
          return Text(
            'Error: ${state.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        /// ---------------- DROPDOWN ----------------
        return ZDropdown<GlCategoriesModel>(
          disableAction: widget.disableAction,
          title: '',
          height: widget.height,

          items: state is GlCategoryLoadedState ? state.glCat : [],

          selectedItem: _selectedSingle,
          itemLabel: (item) => item.acgName ?? '',

          onItemSelected: (item) {
            setState(() => _selectedSingle = item);
            widget.onChanged?.call(item);
          },

          isLoading: isLoading,
          itemStyle: Theme.of(context).textTheme.bodyMedium,

          customTitle:
          (widget.title != null && widget.title!.isNotEmpty) ? buildTitle() : const SizedBox.shrink(),
        );
      },
    );
  }
}

