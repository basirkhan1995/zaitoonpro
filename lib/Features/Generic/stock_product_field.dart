import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Widgets/section_title.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';

typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ItemToString<T> = String Function(T item);
typedef OnProductSelected<T> = void Function(T? product);
typedef BlocSearchFunction<B> = void Function(B bloc, String query);
typedef BlocFetchAllFunction<B> = void Function(B bloc);
typedef BlocFetchByIdFunction<B> = void Function(B bloc, int productId);
typedef ProductListItemBuilder<T> = Widget Function(BuildContext context, T product);
typedef ProductDetailsBuilder<T> = Widget Function(BuildContext context, T product);

class ProductSearchField<T, B extends BlocBase<S>, S> extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool enabled;
  final B? bloc;
  final FocusNode? focusNode; // ADDED: External focus node
  final BlocSearchFunction<B>? searchFunction;
  final BlocFetchAllFunction<B>? fetchAllFunction;
  final BlocFetchByIdFunction<B>? fetchByIdFunction;
  final List<T> Function(S state) stateToItems;
  final bool Function(S state)? stateToLoading;
  final ItemToString<T> itemToString;
  final OnProductSelected<T>? onProductSelected;

  final String? Function(T) getProductId;
  final String? Function(T) getProductName;
  final String? Function(T) getProductCode;
  final int? Function(T) getStorageId;
  final String? Function(T) getStorageName;
  final String? Function(T) getAvailable;
  final int? Function(T) getBatch;
  final String? Function(T) getAveragePrice;
  final String? Function(T) getRecentPrice;
  final String? Function(T) getLandedPrice;
  final String? Function(T) getSellPrice;

  final String? Function(T)? getProductUnit;
  final String? Function(T)? getProductBrand;
  final String? Function(T)? getProductModel;
  final String? Function(T)? getProductMadeIn;
  final String? Function(T)? getProductGrade;
  final String? Function(T)? getProductColor;
  final String? Function(T)? getProductDetails;

  final ProductListItemBuilder<T>? customListItemBuilder;
  final ProductDetailsBuilder<T>? customDetailsBuilder;

  final String noResultsText;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool showClearButton;
  final bool showAllOnFocus;
  final bool openOverlayOnFocus;
  final VoidCallback? onSubmit;

  final TextEditingController? headerSearchController;

  final int? initialProductId;
  final bool autoSelectInitialProduct;

  const ProductSearchField({
    super.key,
    required this.controller,
    required this.bloc,
    required this.searchFunction,
    required this.getBatch,
    required this.fetchAllFunction,
    required this.stateToItems,
    required this.itemToString,
    required this.onProductSelected,
    required this.getProductId,
    required this.getProductName,
    required this.getProductCode,
    required this.getStorageId,
    required this.getLandedPrice,
    required this.getStorageName,
    required this.getAvailable,
    required this.getAveragePrice,
    required this.getRecentPrice,
    required this.getSellPrice,
    this.focusNode, // ADDED
    this.getProductUnit,
    this.onSubmit,
    this.getProductBrand,
    this.getProductModel,
    this.getProductMadeIn,
    this.getProductGrade,
    this.getProductColor,
    this.getProductDetails,
    this.customListItemBuilder,
    this.customDetailsBuilder,
    this.hintText,
    this.enabled = true,
    this.stateToLoading,
    this.noResultsText = 'No products found',
    this.width,
    this.padding,
    this.showClearButton = true,
    this.showAllOnFocus = true,
    this.openOverlayOnFocus = false,
    this.headerSearchController,
    this.initialProductId,
    this.fetchByIdFunction,
    this.autoSelectInitialProduct = true,
  });

  @override
  State<ProductSearchField<T, B, S>> createState() => _ProductSearchFieldState<T, B, S>();
}

class _ProductSearchFieldState<T, B extends BlocBase<S>, S> extends State<ProductSearchField<T, B, S>> {
  int _highlightedIndex = -1;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();
  List<T> _currentSuggestions = [];
  Timer? _debounce;
  late FocusNode _internalFocusNode; // RENAMED from _focusNode
  bool _firstFocus = true;
  final FocusNode _keyboardListenerFocusNode = FocusNode(skipTraversal: true);
  T? _selectedItem;
  T? _currentHighlightedItem;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? baseCurrency;

  final TextEditingController _overlaySearchController = TextEditingController();

  bool _isSyncingFromMain = false;
  bool _isSyncingFromOverlay = false;
  bool _isSyncingFromHeader = false;

  bool _shouldKeepOverlayOpen = false;

  String _currentSearchQuery = '';

  Timer? _loadingTimeout;

  bool _isInitializing = false;
  bool _initialLoadDone = false;

  // ADDED: Use provided focusNode or internal one
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode(); // Create internal focus node
    _effectiveFocusNode.addListener(_onFocusChange); // Listen on effective node
    widget.controller.addListener(_onMainControllerChanged);
    _overlaySearchController.addListener(_onOverlaySearchChanged);

    if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.addListener(_onHeaderSearchChanged);
      if (widget.headerSearchController!.text != widget.controller.text) {
        widget.headerSearchController!.text = widget.controller.text;
      }
    }

    final auth = context.read<AuthBloc>().state;
    if (auth is AuthenticatedState) {
      baseCurrency = auth.loginData.company?.comLocalCcy;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardListenerFocusNode.requestFocus();
      _initializeFromProductId();
    });
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose(); // Always dispose internal node
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

  void _initializeFromProductId() {
    if (_isInitializing || _initialLoadDone) return;

    final hasInitialId = widget.initialProductId != null &&
        widget.initialProductId! > 0 &&
        widget.fetchByIdFunction != null;

    if (!hasInitialId) return;

    if (widget.controller.text.isNotEmpty) {
      _initialLoadDone = true;
      return;
    }

    _isInitializing = true;
    _setLoading(true);
    widget.fetchByIdFunction!(widget.bloc!, widget.initialProductId!);
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

    if (_selectedItem != null && query != widget.itemToString(_selectedItem as T)) {
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

    if (_effectiveFocusNode.hasFocus) { // CHANGED from _focusNode
      _showOverlay();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (query.isNotEmpty && widget.searchFunction != null && query == _currentSearchQuery) {
        try {
          widget.searchFunction!(widget.bloc!, query);
        } catch (e) {
          debugPrint('Search error: $e');
          _setLoading(false);
        }
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
      _effectiveFocusNode.unfocus(); // CHANGED from _focusNode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _keyboardListenerFocusNode.requestFocus();
        }
      });
    }
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_effectiveFocusNode.hasFocus) { // CHANGED from _focusNode
      if (widget.showAllOnFocus && _firstFocus && widget.fetchAllFunction != null) {
        widget.fetchAllFunction!(widget.bloc!);
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
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final tr = AppLocalizations.of(context)!;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.outline);
    _shouldKeepOverlayOpen = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
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
                        Flexible(
                          flex: 5,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              children: [
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
                                      prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(tr.productName, style: titleStyle)),
                                      SizedBox(width: 60, child: Text(tr.unit, textAlign: TextAlign.center, style: titleStyle)),
                                      SizedBox(width: 100, child: Text(tr.batchTitle, textAlign: isRTL ? TextAlign.left : TextAlign.right, style: titleStyle)),
                                      SizedBox(width: 120, child: Text(tr.available, textAlign: isRTL ? TextAlign.left : TextAlign.right, style: titleStyle)),
                                      SizedBox(width: 120, child: Text(tr.unitPrice, textAlign: isRTL ? TextAlign.left : TextAlign.right, style: titleStyle)),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ? widget.customDetailsBuilder!(context, _currentHighlightedItem as T)
            : _buildDefaultDetails(_currentHighlightedItem as T),
      ),
    );
  }

  Widget _buildDefaultListItem(T product) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.getProductName(product) ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            widget.getProductUnit!(product) ?? '0',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(
            widget.getBatch(product).toString(),
            textAlign: isRTL ? TextAlign.left : TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: Text(
            widget.getAvailable(product) ?? '0',
            textAlign: isRTL ? TextAlign.left : TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _getAvailabilityColor(widget.getAvailable(product) ?? '0'),
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: Text(
            widget.getSellPrice(product).toAmount(),
            textAlign: isRTL ? TextAlign.left : TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Color _getAvailabilityColor(String available) {
    final qty = int.tryParse(available) ?? 0;
    if (qty <= 0) return Colors.red;
    if (qty < 10) return Colors.orange;
    return Colors.green;
  }

  Widget _buildDefaultDetails(T product) {
    final tr = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 3,
                      children: [
                        Text(
                          widget.getProductName(product) ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.getProductCode(product) ?? 'N/A',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailCard(tr.stock, [
          _buildDetailItem(Icons.store, tr.storage, widget.getStorageName(product) ?? 'N/A'),
          _buildDetailItem(Icons.numbers, tr.batchTitle, widget.getBatch(product)?.toString() ?? 'N/A'),
          _buildDetailItem(
            Icons.shopping_bag,
            tr.available,
            widget.getAvailable(product) ?? '0',
            color: _getAvailabilityColor(widget.getAvailable(product) ?? '0'),
            isBold: true,
          ),
        ]),
        const SizedBox(height: 8),
        _buildDetailCard(tr.pricingInformation, [
          _buildDetailItem(Icons.trending_up, tr.averagePrice, widget.getAveragePrice(product).toAmount(), currency: baseCurrency),
          _buildDetailItem(Icons.history, tr.recentPrice, widget.getRecentPrice(product).toAmount(), currency: baseCurrency),
          _buildDetailItem(Icons.dark_mode, tr.landedPrice, widget.getLandedPrice(product).toAmount(), currency: baseCurrency),
          _buildDetailItem(Icons.attach_money, tr.sellPrice, widget.getSellPrice(product).toAmount(), color: Colors.green, isBold: true, currency: baseCurrency),
        ]),
        const SizedBox(height: 16),
        _buildDetailCard(tr.productSpecification, [
          if (widget.getProductUnit != null)
            _buildDetailItem(Icons.category, tr.unit, widget.getProductUnit!(product) ?? 'N/A'),
          if (widget.getProductBrand != null)
            _buildDetailItem(Icons.branding_watermark, tr.brandTitle, widget.getProductBrand!(product) ?? 'N/A'),
          if (widget.getProductModel != null)
            _buildDetailItem(Icons.model_training, tr.modelTitle, widget.getProductModel!(product) ?? 'N/A'),
          if (widget.getProductMadeIn != null)
            _buildDetailItem(Icons.location_on, tr.madeIn, widget.getProductMadeIn!(product) ?? 'N/A'),
          if (widget.getProductGrade != null)
            _buildDetailItem(Icons.star, tr.gradeTitle, widget.getProductGrade!(product) ?? 'N/A'),
          if (widget.getProductColor != null)
            _buildDetailItem(Icons.color_lens, 'Color', widget.getProductColor!(product) ?? 'N/A'),
        ]),
        const SizedBox(height: 8),
        if (widget.getProductDetails != null && widget.getProductDetails!(product) != null && widget.getProductDetails!(product)!.isNotEmpty)
          _buildDetailCard(tr.productDetails, [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.getProductDetails!(product) ?? '',
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
      String value, {
        String? currency,
        Color? color,
        bool isBold = false,
      }) {
    final displayValue = currency != null && currency.isNotEmpty ? "$value $currency" : value;

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
              displayValue,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color,
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

  void _handleItemSelection(T item) {
    final selectedProductName = widget.itemToString(item);

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
            (element) => widget.itemToString(element) == widget.itemToString(item),
      );
      if (selectedIndex >= 0) {
        _highlightedIndex = selectedIndex;
      }
    });

    widget.onProductSelected?.call(item);
    _closeOverlay();
    widget.onSubmit?.call();
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
            _initialLoadDone = false;
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
        widget.onSubmit?.call();
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
        widget.onSubmit?.call();
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
                  focusNode: _effectiveFocusNode, // CHANGED from _focusNode
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

                    if (_selectedItem != null && value != widget.itemToString(_selectedItem as T)) {
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
                      widget.onSubmit?.call();
                    } else if (_highlightedIndex >= 0 && _highlightedIndex < _currentSuggestions.length) {
                      _handleItemSelection(_currentSuggestions[_highlightedIndex]);
                    } else if (_currentSuggestions.isNotEmpty) {
                      _handleItemSelection(_currentSuggestions.first);
                    } else {
                      _closeOverlay();
                      widget.onSubmit?.call();
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
            if (widget.bloc != null)
              BlocListener<B, S>(
                bloc: widget.bloc,
                listener: (context, state) {
                  _loadingTimeout?.cancel();

                  final items = widget.stateToItems(state);
                  final isLoading = widget.stateToLoading != null && widget.stateToLoading!(state);

                  if (mounted) {
                    setState(() {
                      _currentSuggestions = items;
                      _isLoading = isLoading;

                      if (!isLoading) {
                        if (_isInitializing && items.isNotEmpty && !_initialLoadDone) {
                          final product = items.first;
                          final productName = widget.itemToString(product);

                          _isSyncingFromMain = true;
                          _isSyncingFromOverlay = true;
                          _isSyncingFromHeader = true;

                          widget.controller.text = productName;
                          _overlaySearchController.text = productName;

                          if (widget.headerSearchController != null &&
                              widget.headerSearchController != widget.controller) {
                            widget.headerSearchController!.text = productName;
                          }

                          _isSyncingFromMain = false;
                          _isSyncingFromOverlay = false;
                          _isSyncingFromHeader = false;

                          setState(() {
                            _selectedItem = product;
                            _currentHighlightedItem = product;
                          });

                          widget.onProductSelected?.call(product);
                          _initialLoadDone = true;
                          _isInitializing = false;
                        }

                        if (_selectedItem != null && items.isNotEmpty) {
                          final selectedIndex = items.indexWhere(
                                (item) => widget.itemToString(item) == widget.itemToString(_selectedItem as T),
                          );
                          if (selectedIndex >= 0) {
                            _highlightedIndex = selectedIndex;
                            _currentHighlightedItem = _selectedItem;
                          } else if (_highlightedIndex >= items.length) {
                            _highlightedIndex = items.isEmpty ? -1 : 0;
                            _currentHighlightedItem = items.isNotEmpty ? items[_highlightedIndex] : null;
                          }
                        } else {
                          if (_highlightedIndex >= items.length) {
                            _highlightedIndex = items.isEmpty ? -1 : 0;
                          }
                          if (items.isNotEmpty && _highlightedIndex >= 0) {
                            _currentHighlightedItem = items[_highlightedIndex];
                          } else if (items.isNotEmpty) {
                            _currentHighlightedItem = items.first;
                          } else {
                            _currentHighlightedItem = null;
                          }
                        }
                      }
                    });

                    _refreshOverlay();
                  }

                  final hasText = widget.controller.text.isNotEmpty;
                  if (_effectiveFocusNode.hasFocus && (hasText || isLoading || widget.openOverlayOnFocus)) { // CHANGED from _focusNode
                    _showOverlay();
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