import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_model.dart';
import '../../Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';

typedef OnProductSelected = void Function(ProductsModel? product);
typedef ProductListItemBuilder = Widget Function(BuildContext context, ProductsModel product);
typedef ProductDetailsBuilder = Widget Function(BuildContext context, ProductsModel product);

class PurchaseProductSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool enabled;
  final FocusNode? focusNode;
  final void Function()? onSubmitted;
  final ProductsBloc bloc;
  final OnProductSelected? onProductSelected;
  final ProductListItemBuilder? customListItemBuilder;
  final ProductDetailsBuilder? customDetailsBuilder;
  final String noResultsText;
  final String initialMessageText;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool showClearButton;
  final bool showAllOnFocus;
  final bool openOverlayOnFocus;

  const PurchaseProductSearchField({
    super.key,
    required this.controller,
    required this.bloc,
    this.onProductSelected,
    this.focusNode,
    this.onSubmitted,
    this.customListItemBuilder,
    this.customDetailsBuilder,
    this.hintText,
    this.enabled = true,
    this.noResultsText = 'No products found',
    this.initialMessageText = 'Search for products',
    this.width,
    this.padding,
    this.showClearButton = true,
    this.showAllOnFocus = false, // Changed to false
    this.openOverlayOnFocus = false,
  });

  @override
  State<PurchaseProductSearchField> createState() => _PurchaseProductSearchFieldState();
}

class _PurchaseProductSearchFieldState extends State<PurchaseProductSearchField> {
  int _highlightedIndex = -1;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();
  List<ProductsModel> _currentSuggestions = [];
  Timer? _debounce;
  late FocusNode _internalFocusNode;
  bool _firstFocus = true;
  final FocusNode _keyboardListenerFocusNode = FocusNode(skipTraversal: true);
  ProductsModel? _selectedItem;
  ProductsModel? _currentHighlightedItem;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isOverlayHovered = false;

  // Use provided focus node or internal one
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardListenerFocusNode.requestFocus();
      // REMOVED: No initial fetch
    });
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    widget.controller.removeListener(_onControllerChanged);
    _debounce?.cancel();
    _removeOverlay();
    _scrollController.dispose();
    super.dispose();
  }

  void _closeOverlayAndReset() {
    _removeOverlay();
    setState(() {
      _highlightedIndex = -1;
      _currentHighlightedItem = null;
    });
    _effectiveFocusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardListenerFocusNode.requestFocus();
      }
    });
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_effectiveFocusNode.hasFocus) {
      if (widget.showAllOnFocus && _firstFocus) {
        _firstFocus = false;
        if (widget.showAllOnFocus) {
          widget.bloc.add(LoadProductsEvent());
        }
      }

      // Only show overlay if there are suggestions, loading, or text is not empty
      if (_currentSuggestions.isNotEmpty ||
          _isLoading ||
          widget.controller.text.isNotEmpty ||
          widget.openOverlayOnFocus) {
        _showOverlay();
      }
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _refreshOverlay() {
    if (_overlayEntry != null && mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _scrollToHighlightedItem() {
    if (_scrollController.hasClients && _highlightedIndex >= 0) {
      final itemHeight = 72.0;
      final scrollOffset = _highlightedIndex * itemHeight;
      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _refreshOverlay();
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null || !mounted) return;

    final overlayWidth = overlay.size.width;
    final overlayHeight = overlay.size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const double panelWidthPercentage = 0.85;
    const double panelHeightPercentage = 0.75;

    double panelWidth = screenWidth * panelWidthPercentage;
    double panelHeight = screenHeight * panelHeightPercentage;

    const double maxPanelWidth = 1400;
    const double maxPanelHeight = 900;
    const double minPanelWidth = 800;
    const double minPanelHeight = 500;

    panelWidth = panelWidth.clamp(minPanelWidth, maxPanelWidth);
    panelHeight = panelHeight.clamp(minPanelHeight, maxPanelHeight);

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeOverlayAndReset,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: .5),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: overlayWidth,
                height: overlayHeight,
                child: Center(
                  child: MouseRegion(
                    onEnter: (_) {
                      _isOverlayHovered = true;
                    },
                    onExit: (_) {
                      _isOverlayHovered = false;
                      _keyboardListenerFocusNode.requestFocus();
                    },
                    child: Container(
                      width: panelWidth,
                      height: panelHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: .5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Flexible(
                              flex: 5,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: .2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              widget.controller.text.isEmpty
                                                  ? AppLocalizations.of(context)!.searchProducts
                                                  : '${AppLocalizations.of(context)!.searchResult} "${widget.controller.text}"${!_isLoading && _currentSuggestions.isNotEmpty ? ' (${_currentSuggestions.length})' : ''}',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_isLoading)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          IconButton(
                                            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.outline),
                                            onPressed: _closeOverlayAndReset,
                                            tooltip: AppLocalizations.of(context)!.closeKey,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: _isLoading
                                          ? Center(
                                        child: CircularProgressIndicator(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      )
                                          : _currentSuggestions.isEmpty
                                          ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              widget.controller.text.isEmpty ? Icons.search : Icons.search_off,
                                              size: 48,
                                              color: Theme.of(context).colorScheme.outline.withValues(alpha: .5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              widget.controller.text.isEmpty
                                                  ? widget.initialMessageText
                                                  : widget.noResultsText,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.outline,
                                              ),
                                            ),
                                            if (widget.controller.text.isEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  'Type to search for products',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline
                                                        .withValues(alpha: .7),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      )
                                          : ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        itemCount: _currentSuggestions.length,
                                        itemBuilder: (context, index) {
                                          final product = _currentSuggestions[index];
                                          final isHighlighted = index == _highlightedIndex;

                                          return Container(
                                            decoration: BoxDecoration(
                                              color: isHighlighted
                                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .1)
                                                  : Colors.transparent,
                                              border: isHighlighted
                                                  ? Border(
                                                left: BorderSide(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  width: 3,
                                                ),
                                              )
                                                  : null,
                                            ),
                                            child: InkWell(
                                              onTap: () => _handleItemSelection(product),
                                              onHover: (hovered) {
                                                if (hovered && mounted) {
                                                  setState(() {
                                                    _highlightedIndex = index;
                                                    _currentHighlightedItem = product;
                                                  });
                                                  _refreshOverlay();
                                                }
                                              },
                                              child: widget.customListItemBuilder != null
                                                  ? widget.customListItemBuilder!(context, product)
                                                  : _buildDefaultListItem(product),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (!_isLoading && _currentSuggestions.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                                          border: Border(
                                            top: BorderSide(
                                              color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildKeyHint(context, '↑↓', AppLocalizations.of(context)!.navigateTitle),
                                            const SizedBox(width: 16),
                                            _buildKeyHint(context, '⏎', AppLocalizations.of(context)!.selectTitle),
                                            const SizedBox(width: 16),
                                            _buildKeyHint(context, 'ESC', AppLocalizations.of(context)!.closeTitle),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (_currentHighlightedItem != null && !_isLoading && _currentSuggestions.isNotEmpty)
                              Flexible(
                                flex: 3,
                                child: ZCover(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.inventory_2_rounded,
                                              size: 20,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(context)!.productDetails,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  AppLocalizations.of(context)!.completeInfo,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: widget.customDetailsBuilder != null
                                              ? widget.customDetailsBuilder!(context, _currentHighlightedItem!)
                                              : _buildDefaultDetails(_currentHighlightedItem!),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDefaultListItem(ProductsModel product) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -4),
      contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 15),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.inventory,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        product.proName ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${product.proCode ?? 'N/A'} | ${product.proBrand ?? 'N/A'} | ${product.proUnit ?? 'N/A'}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildDefaultDetails(ProductsModel product) {
    final tr = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailCard(tr.basicInformation, [
          _buildDetailItem(Icons.label, tr.productName, product.proName ?? 'N/A'),
          _buildDetailItem(Icons.qr_code, tr.productCode, product.proCode ?? 'N/A'),
          _buildDetailItem(Icons.category, tr.unit, product.proUnit ?? 'N/A'),
          _buildDetailItem(Icons.grade, tr.brandTitle, product.proBrand ?? 'N/A'),
          _buildDetailItem(Icons.grade, tr.modelTitle, product.proModel ?? 'N/A'),
          _buildDetailItem(Icons.place, tr.madeIn, product.proMadeIn ?? 'N/A'),
          _buildDetailItem(Icons.grade, tr.gradeTitle, product.proGrade ?? 'N/A'),
        ]),
        const SizedBox(height: 16),
        _buildDetailCard(tr.productDetails, [
          _buildDetailItem(Icons.description, tr.details, product.proDetails ?? 'N/A'),
        ]),
      ],
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: .2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyHint(BuildContext context, String key, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            key,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          action,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _handleItemSelection(ProductsModel product) {
    widget.controller.text = product.proName ?? '';
    setState(() {
      _selectedItem = product;
      _currentHighlightedItem = product;
      final selectedIndex = _currentSuggestions.indexWhere(
            (element) => element.proId == product.proId,
      );
      if (selectedIndex >= 0) {
        _highlightedIndex = selectedIndex;
      }
    });
    widget.onProductSelected?.call(product);
    _closeOverlayAndReset();
    widget.onSubmitted?.call();
  }

  Widget? _buildSuffixIcon() {
    return widget.showClearButton && widget.controller.text.isNotEmpty
        ? IconButton(
      constraints: const BoxConstraints(),
      splashRadius: 2,
      icon: Icon(Icons.clear, size: 16, color: Theme.of(context).colorScheme.secondary),
      onPressed: () {
        widget.controller.clear();
        if (mounted) {
          setState(() {
            _currentSuggestions = [];
            _firstFocus = true;
            _selectedItem = null;
            _currentHighlightedItem = null;
            _highlightedIndex = -1;
            _isLoading = false;
          });
        }
        widget.onProductSelected?.call(null);
        _closeOverlayAndReset();
        // REMOVED: Don't fetch all products on clear
      },
    )
        : null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_overlayEntry != null) {
        _closeOverlayAndReset();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (_overlayEntry == null) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        widget.onSubmitted?.call();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_currentSuggestions.isNotEmpty && mounted) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1) % _currentSuggestions.length;
          _currentHighlightedItem = _currentSuggestions[_highlightedIndex];
        });
        _scrollToHighlightedItem();
        _refreshOverlay();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_currentSuggestions.isNotEmpty && mounted) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1 + _currentSuggestions.length) % _currentSuggestions.length;
          _currentHighlightedItem = _currentSuggestions[_highlightedIndex];
        });
        _scrollToHighlightedItem();
        _refreshOverlay();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _currentSuggestions.length) {
        final selectedItem = _currentSuggestions[_highlightedIndex];
        _handleItemSelection(selectedItem);
      } else {
        _closeOverlayAndReset();
        widget.onSubmitted?.call();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: Focus(
                focusNode: _keyboardListenerFocusNode,
                onKeyEvent: _handleKeyEvent,
                child: TextFormField(
                  focusNode: _effectiveFocusNode,
                  enabled: widget.enabled,
                  key: _fieldKey,
                  controller: widget.controller,
                  onChanged: (value) {
                    setState(() {
                      _highlightedIndex = -1;
                    });

                    if (_selectedItem != null) {
                      setState(() {
                        _selectedItem = null;
                      });
                      widget.onProductSelected?.call(null);
                    }

                    if (_debounce?.isActive ?? false) _debounce!.cancel();

                    if (value.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                      });
                      if (_effectiveFocusNode.hasFocus) {
                        _showOverlay();
                      }
                    } else {
                      // Clear suggestions when search is empty
                      setState(() {
                        _currentSuggestions = [];
                        _isLoading = false;
                      });
                      _removeOverlay();
                    }

                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      if (!mounted) return;

                      if (value.isNotEmpty) {
                        widget.bloc.add(LoadProductsEvent(input: value));
                      } else {
                        setState(() {
                          _currentSuggestions = [];
                          _isLoading = false;
                        });
                        _removeOverlay();
                      }
                    });
                  },
                  onFieldSubmitted: (_) {
                    widget.onSubmitted?.call();
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    suffixIconConstraints: const BoxConstraints(),
                    suffixIcon: _buildSuffixIcon(),
                    isDense: true,
                    hintText: widget.hintText ?? 'Products',
                  ),
                ),
              ),
            ),
            BlocListener<ProductsBloc, ProductsState>(
              bloc: widget.bloc,
              listener: (context, state) {
                if (state is ProductsLoadedState) {
                  setState(() {
                    _currentSuggestions = state.products;
                    _isLoading = false;

                    if (_highlightedIndex >= _currentSuggestions.length) {
                      _highlightedIndex = _currentSuggestions.isEmpty ? -1 : 0;
                    }
                    if (_currentSuggestions.isNotEmpty && _highlightedIndex >= 0) {
                      _currentHighlightedItem = _currentSuggestions[_highlightedIndex];
                    } else if (_currentSuggestions.isNotEmpty) {
                      _currentHighlightedItem = _currentSuggestions.first;
                    } else {
                      _currentHighlightedItem = null;
                    }
                  });

                  final hasText = widget.controller.text.isNotEmpty;
                  if (_effectiveFocusNode.hasFocus && (hasText || widget.openOverlayOnFocus)) {
                    _showOverlay();
                  } else if (!_effectiveFocusNode.hasFocus && !_isOverlayHovered) {
                    _removeOverlay();
                  }
                } else if (state is ProductsLoadingState) {
                  setState(() {
                    _isLoading = true;
                  });
                  if (_effectiveFocusNode.hasFocus && widget.controller.text.isNotEmpty) {
                    _showOverlay();
                  }
                } else if (state is ProductsErrorState) {
                  setState(() {
                    _isLoading = false;
                    _currentSuggestions = [];
                  });
                }
              },
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}