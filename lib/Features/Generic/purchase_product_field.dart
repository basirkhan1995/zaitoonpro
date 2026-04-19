import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Widgets/section_title.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_model.dart';
import '../../Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';

typedef OnProductSelected = void Function(ProductsModel? product);
typedef ProductListItemBuilder = Widget Function(BuildContext context, ProductsModel product);
typedef ProductDetailsBuilder = Widget Function(BuildContext context, ProductsModel product);

class PurchaseProductSearchField extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController? headerSearchController;
  final String? hintText;
  final bool enabled;
  final FocusNode? focusNode;
  final void Function()? onSubmitted;
  final ProductsBloc bloc;
  final OnProductSelected? onProductSelected;
  final ProductListItemBuilder? customListItemBuilder;
  final ProductDetailsBuilder? customDetailsBuilder;
  final String noResultsText;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool showClearButton;
  final bool showAllOnFocus;
  final bool openOverlayOnFocus;

  const PurchaseProductSearchField({
    super.key,
    required this.controller,
    required this.bloc,
    this.headerSearchController,
    this.onProductSelected,
    this.focusNode,
    this.onSubmitted,
    this.customListItemBuilder,
    this.customDetailsBuilder,
    this.hintText,
    this.enabled = true,
    this.noResultsText = 'No products found',
    this.width,
    this.padding,
    this.showClearButton = true,
    this.showAllOnFocus = false,
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

  // Search TextField controller inside overlay
  final TextEditingController _overlaySearchController = TextEditingController();

  // Sync flags
  bool _isSyncingFromMain = false;
  bool _isSyncingFromOverlay = false;
  bool _isSyncingFromHeader = false;

  // Track if overlay should stay open
  bool _shouldKeepOverlayOpen = false;

  // Track current search query to prevent stale responses
  String _currentSearchQuery = '';

  // Timeout for loading state
  Timer? _loadingTimeout;

  // Use provided focus node or internal one
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onMainControllerChanged);
    _overlaySearchController.addListener(_onOverlaySearchChanged);

    // Sync with header search controller if provided
    if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.addListener(_onHeaderSearchChanged);
      if (widget.headerSearchController!.text != widget.controller.text) {
        widget.headerSearchController!.text = widget.controller.text;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardListenerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    widget.controller.removeListener(_onMainControllerChanged);
    _overlaySearchController.removeListener(_onOverlaySearchChanged);

    if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.removeListener(_onHeaderSearchChanged);
    }

    _debounce?.cancel();
    _loadingTimeout?.cancel();
    _removeOverlay();
    _scrollController.dispose();
    _overlaySearchController.dispose();
    super.dispose();
  }

  void _onMainControllerChanged() {
    if (_isSyncingFromOverlay || _isSyncingFromHeader) return;
    _isSyncingFromMain = true;

    if (_overlaySearchController.text != widget.controller.text) {
      _overlaySearchController.text = widget.controller.text;
    }

    if (widget.headerSearchController != null &&
        widget.headerSearchController != widget.controller &&
        widget.headerSearchController!.text != widget.controller.text) {
      widget.headerSearchController!.text = widget.controller.text;
    }

    _isSyncingFromMain = false;
  }

  void _onOverlaySearchChanged() {
    if (_isSyncingFromMain || _isSyncingFromHeader) return;
    _isSyncingFromOverlay = true;

    final overlayText = _overlaySearchController.text;

    if (widget.controller.text != overlayText) {
      widget.controller.text = overlayText;
    }

    if (widget.headerSearchController != null &&
        widget.headerSearchController != widget.controller &&
        widget.headerSearchController!.text != overlayText) {
      widget.headerSearchController!.text = overlayText;
    }

    _triggerSearch(overlayText);

    _isSyncingFromOverlay = false;
  }

  void _onHeaderSearchChanged() {
    if (_isSyncingFromMain || _isSyncingFromOverlay) return;
    _isSyncingFromHeader = true;

    final headerText = widget.headerSearchController?.text ?? '';

    if (widget.controller.text != headerText) {
      widget.controller.text = headerText;
    }

    if (_overlaySearchController.text != headerText) {
      _overlaySearchController.text = headerText;
    }

    if (headerText != _currentSearchQuery) {
      _triggerSearch(headerText);
    }

    _isSyncingFromHeader = false;
  }

  void _setLoading(bool loading) {
    if (!mounted) return;

    _loadingTimeout?.cancel();

    if (loading) {
      _loadingTimeout = Timer(const Duration(seconds: 10), () {
        if (mounted && _isLoading) {
          debugPrint('Loading timeout - clearing loading state');
          setState(() {
            _isLoading = false;
          });
          _loadingTimeout = null;
          _refreshOverlay();
        }
      });
    }

    setState(() {
      _isLoading = loading;
    });

    _refreshOverlay();
  }

  void _triggerSearch(String query) {
    _debounce?.cancel();
    _loadingTimeout?.cancel();

    if (_selectedItem != null && query != (_selectedItem?.proName ?? '')) {
      setState(() {
        _selectedItem = null;
        _currentHighlightedItem = null;
        _highlightedIndex = -1;
      });
      widget.onProductSelected?.call(null);
    }

    if (query.isEmpty) {
      setState(() {
        _currentSuggestions = [];
        _isLoading = false;
        _currentSearchQuery = '';
      });
      _loadingTimeout?.cancel();
      _removeOverlay();
      return;
    }

    _setLoading(true);
    _currentSearchQuery = query;

    if (_effectiveFocusNode.hasFocus) {
      _showOverlay();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (query.isNotEmpty && query == _currentSearchQuery) {
        widget.bloc.add(LoadProductsEvent(input: query));
      }
    });
  }

  void _closeOverlay({bool shouldResetFocus = true}) {
    _shouldKeepOverlayOpen = false;
    _removeOverlay();
    setState(() {
      _highlightedIndex = -1;
      _currentHighlightedItem = null;
    });
    if (shouldResetFocus) {
      _effectiveFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _keyboardListenerFocusNode.requestFocus();
        }
      });
    }
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_effectiveFocusNode.hasFocus) {
      if (widget.showAllOnFocus && _firstFocus) {
        widget.bloc.add(LoadProductsEvent());
        _firstFocus = false;
      }

      if ((_currentSuggestions.isNotEmpty || _isLoading || widget.controller.text.isNotEmpty || widget.openOverlayOnFocus) &&
          widget.controller.text.isNotEmpty) {
        _showOverlay();
      }
    } else {
      if (!_shouldKeepOverlayOpen) {
        _closeOverlay(shouldResetFocus: false);
      }
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
    if (!_scrollController.hasClients || _highlightedIndex < 0) return;

    const itemHeight = 72.0;
    final viewportStart = _scrollController.offset;
    final viewportEnd = viewportStart + _scrollController.position.viewportDimension;
    final itemStart = _highlightedIndex * itemHeight;
    final itemEnd = itemStart + itemHeight;

    if (itemEnd > viewportEnd) {
      _scrollController.animateTo(
        itemEnd - _scrollController.position.viewportDimension,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else if (itemStart < viewportStart) {
      _scrollController.animateTo(
        itemStart,
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
    const double panelHeightPercentage = 0.85;

    double panelWidth = screenWidth * panelWidthPercentage;
    double panelHeight = screenHeight * panelHeightPercentage;

    const double maxPanelWidth = 1400;
    const double maxPanelHeight = 900;
    const double minPanelWidth = 800;
    const double minPanelHeight = 500;

    panelWidth = panelWidth.clamp(minPanelWidth, maxPanelWidth);
    panelHeight = panelHeight.clamp(minPanelHeight, maxPanelHeight);
    final tr = AppLocalizations.of(context)!;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.surface);
    _shouldKeepOverlayOpen = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background overlay - clicking this closes
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _closeOverlay(),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: .3)),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: overlayWidth,
              height: overlayHeight,
              child: Center(
                child: Container(
                  width: panelWidth,
                  height: panelHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(5),
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
                    borderRadius: BorderRadius.circular(5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left panel - product list
                        Flexible(
                          flex: 5,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                // Search TextField inside overlay
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                                      ),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _overlaySearchController,
                                    autofocus: true,
                                    showCursor: true,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!.searchProducts,
                                      prefixIcon: Icon(Icons.search,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 18,
                                      ),
                                      suffixIcon: _overlaySearchController.text.isNotEmpty
                                          ? IconButton(
                                        icon: Icon(Icons.clear,
                                          color: Theme.of(context).colorScheme.outline,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _overlaySearchController.clear();
                                          _triggerSearch('');
                                        },
                                      )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(3),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(3),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(3),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 1,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    ),
                                    onSubmitted: (_) {
                                      if (_highlightedIndex >= 0 && _highlightedIndex < _currentSuggestions.length) {
                                        _handleItemSelection(_currentSuggestions[_highlightedIndex]);
                                      } else if (_currentSuggestions.isNotEmpty) {
                                        _handleItemSelection(_currentSuggestions.first);
                                      }
                                    },
                                  ),
                                ),
                                // Header row - Product Name, Unit, Brand, Grade
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(tr.productName, style: titleStyle),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(tr.unit,
                                            textAlign: TextAlign.center,
                                            style: titleStyle),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(tr.brandTitle,
                                            textAlign: TextAlign.center,
                                            style: titleStyle),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(tr.gradeTitle,
                                            textAlign: TextAlign.center,
                                            style: titleStyle),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _isLoading
                                      ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context)!.loading,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      : _currentSuggestions.isEmpty
                                      ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, size: 48,
                                            color: Theme.of(context).colorScheme.outline.withValues(alpha: .5)),
                                        const SizedBox(height: 16),
                                        Text(
                                          widget.noResultsText,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.outline,
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
                                      final item = _currentSuggestions[index];
                                      final isHighlighted = index == _highlightedIndex;
                                      final isRTL = Directionality.of(context) == TextDirection.rtl;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isHighlighted
                                              ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                              width: 0.5,
                                            ),
                                            left: isHighlighted && !isRTL
                                                ? BorderSide(
                                              color: Theme.of(context).colorScheme.primary,
                                              width: 3,
                                            )
                                                : BorderSide.none,
                                            right: isHighlighted && isRTL
                                                ? BorderSide(
                                              color: Theme.of(context).colorScheme.primary,
                                              width: 3,
                                            )
                                                : BorderSide.none,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () => _handleItemSelection(item),
                                          onHover: (hovered) {
                                            if (hovered && mounted) {
                                              setState(() {
                                                _highlightedIndex = index;
                                                _currentHighlightedItem = item;
                                              });
                                              _refreshOverlay();
                                            }
                                          },
                                          child: widget.customListItemBuilder != null
                                              ? widget.customListItemBuilder!(context, item)
                                              : _buildDefaultListItem(item),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (!_isLoading && _currentSuggestions.isNotEmpty)
                                  _buildKeyboardHints(),
                              ],
                            ),
                          ),
                        ),
                        // Right panel - details
                        if (_currentHighlightedItem != null && !_isLoading && _currentSuggestions.isNotEmpty)
                          Container(
                            width: 350,
                            height: double.infinity,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .05),
                                  blurRadius: 8,
                                  offset: const Offset(-2, 0),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildProductDetailsPanel(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildKeyboardHints() {
    return Container(
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
    );
  }

  Widget _buildProductDetailsPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      child: SingleChildScrollView(
        child: widget.customDetailsBuilder != null
            ? widget.customDetailsBuilder!(context, _currentHighlightedItem!)
            : _buildDefaultDetails(_currentHighlightedItem!),
      ),
    );
  }

  Widget _buildDefaultListItem(ProductsModel product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              product.proName ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              product.proUnit ?? 'N/A',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              product.proBrand ?? 'N/A',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              product.proGrade ?? 'N/A',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultDetails(ProductsModel product) {
    final tr = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product code and basic info (name removed as it's shown on top)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tr.productCode}: ${product.proCode ?? 'N/A'}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailCard(tr.basicInformation, [
          _buildDetailItem(Icons.category, tr.unit, product.proUnit ?? 'N/A'),
          _buildDetailItem(Icons.branding_watermark, tr.brandTitle, product.proBrand ?? 'N/A'),
          _buildDetailItem(Icons.model_training, tr.modelTitle, product.proModel ?? 'N/A'),
          _buildDetailItem(Icons.location_on, tr.madeIn, product.proMadeIn ?? 'N/A'),
          _buildDetailItem(Icons.star, tr.gradeTitle, product.proGrade ?? 'N/A'),
        ]),
        const SizedBox(height: 8),
        if (product.proDetails != null && product.proDetails!.isNotEmpty)
          _buildDetailCard(tr.productDetails, [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.proDetails ?? '',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ]),
      ],
    );
  }

  Widget _buildDetailItem(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: Text('$label:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZCover(radius: 3, padding: EdgeInsets.symmetric(horizontal: 3), child: SectionTitle(title: title)),
          const SizedBox(height: 5),
          ...children,
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
        Text(action, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _handleItemSelection(ProductsModel item) {
    final selectedProductName = item.proName ?? '';

    // Update all controllers without sync loops
    _isSyncingFromMain = true;
    _isSyncingFromOverlay = true;
    _isSyncingFromHeader = true;

    widget.controller.text = selectedProductName;
    _overlaySearchController.text = selectedProductName;

    if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.text = selectedProductName;
    }

    _isSyncingFromMain = false;
    _isSyncingFromOverlay = false;
    _isSyncingFromHeader = false;

    setState(() {
      _selectedItem = item;
      _currentHighlightedItem = item;
      final selectedIndex = _currentSuggestions.indexWhere(
            (element) => element.proId == item.proId,
      );
      if (selectedIndex >= 0) {
        _highlightedIndex = selectedIndex;
      }
    });

    widget.onProductSelected?.call(item);
    _closeOverlay();
    widget.onSubmitted?.call();
  }

  Widget? _buildSuffixIcon() {
    return widget.showClearButton && widget.controller.text.isNotEmpty
        ? IconButton(
      constraints: const BoxConstraints(),
      splashRadius: 2,
      icon: Icon(Icons.clear, size: 16, color: Theme.of(context).colorScheme.secondary),
      onPressed: () {
        _isSyncingFromMain = true;
        _isSyncingFromOverlay = true;
        _isSyncingFromHeader = true;

        widget.controller.clear();
        _overlaySearchController.clear();

        if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
          widget.headerSearchController!.clear();
        }

        _isSyncingFromMain = false;
        _isSyncingFromOverlay = false;
        _isSyncingFromHeader = false;

        _debounce?.cancel();
        _loadingTimeout?.cancel();

        if (mounted) {
          setState(() {
            _currentSuggestions = [];
            _firstFocus = true;
            _selectedItem = null;
            _currentHighlightedItem = null;
            _highlightedIndex = -1;
            _isLoading = false;
            _currentSearchQuery = '';
          });
        }
        widget.onProductSelected?.call(null);
        _closeOverlay();
      },
    )
        : null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_overlayEntry != null) {
        _closeOverlay();
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
      } else if (_currentSuggestions.isNotEmpty) {
        _handleItemSelection(_currentSuggestions.first);
      } else {
        _closeOverlay();
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
                    if (_isSyncingFromOverlay || _isSyncingFromHeader) return;

                    if (mounted) {
                      setState(() {
                        _highlightedIndex = -1;
                      });
                    }

                    if (_selectedItem != null && value != (_selectedItem?.proName ?? '')) {
                      setState(() {
                        _selectedItem = null;
                        _currentHighlightedItem = null;
                      });
                      widget.onProductSelected?.call(null);
                    }

                    if (_overlaySearchController.text != value) {
                      _overlaySearchController.text = value;
                    }

                    if (widget.headerSearchController != null &&
                        widget.headerSearchController != widget.controller &&
                        widget.headerSearchController!.text != value) {
                      widget.headerSearchController!.text = value;
                    }

                    _triggerSearch(value);
                  },
                  onFieldSubmitted: (_) {
                    if (_currentSuggestions.isEmpty) {
                      _closeOverlay();
                      widget.onSubmitted?.call();
                    } else if (_highlightedIndex >= 0 && _highlightedIndex < _currentSuggestions.length) {
                      _handleItemSelection(_currentSuggestions[_highlightedIndex]);
                    } else if (_currentSuggestions.isNotEmpty) {
                      _handleItemSelection(_currentSuggestions.first);
                    } else {
                      _closeOverlay();
                      widget.onSubmitted?.call();
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    suffixIconConstraints: const BoxConstraints(),
                    suffixIcon: _buildSuffixIcon(),
                    isDense: true,
                    hintText: widget.hintText,
                  ),
                ),
              ),
            ),
            BlocListener<ProductsBloc, ProductsState>(
              bloc: widget.bloc,
              listener: (context, state) {
                _loadingTimeout?.cancel();

                if (state is ProductsLoadedState) {
                  setState(() {
                    _currentSuggestions = state.products;
                    _isLoading = false;

                    if (_selectedItem != null && state.products.isNotEmpty) {
                      final selectedIndex = state.products.indexWhere(
                            (item) => item.proId == _selectedItem?.proId,
                      );
                      if (selectedIndex >= 0) {
                        _highlightedIndex = selectedIndex;
                        _currentHighlightedItem = _selectedItem;
                      } else if (_highlightedIndex >= state.products.length) {
                        _highlightedIndex = state.products.isEmpty ? -1 : 0;
                        _currentHighlightedItem = state.products.isNotEmpty ? state.products[_highlightedIndex] : null;
                      }
                    } else {
                      if (_highlightedIndex >= state.products.length) {
                        _highlightedIndex = state.products.isEmpty ? -1 : 0;
                      }
                      if (state.products.isNotEmpty && _highlightedIndex >= 0) {
                        _currentHighlightedItem = state.products[_highlightedIndex];
                      } else if (state.products.isNotEmpty) {
                        _currentHighlightedItem = state.products.first;
                      } else {
                        _currentHighlightedItem = null;
                      }
                    }
                  });

                  _refreshOverlay();

                  final hasText = widget.controller.text.isNotEmpty;
                  if (_effectiveFocusNode.hasFocus && (hasText || widget.openOverlayOnFocus)) {
                    _showOverlay();
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