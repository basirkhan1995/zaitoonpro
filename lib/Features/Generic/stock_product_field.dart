import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Widgets/section_title.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';

typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ItemToString<T> = String Function(T item);
typedef OnProductSelected<T> = void Function(T? product);
typedef BlocSearchFunction<B> = void Function(B bloc, String query);
typedef BlocFetchAllFunction<B> = void Function(B bloc);
typedef ProductListItemBuilder<T> =
Widget Function(BuildContext context, T product);
typedef ProductDetailsBuilder<T> =
Widget Function(BuildContext context, T product);

class ProductSearchField<T, B extends BlocBase<S>, S> extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool enabled;
  final B? bloc;
  final BlocSearchFunction<B>? searchFunction;
  final BlocFetchAllFunction<B>? fetchAllFunction;
  final List<T> Function(S state) stateToItems;
  final bool Function(S state)? stateToLoading;
  final ItemToString<T> itemToString;
  final OnProductSelected<T>? onProductSelected;

  // Product-specific fields
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

  // New product specification fields
  final String? Function(T)? getProductUnit;
  final String? Function(T)? getProductBrand;
  final String? Function(T)? getProductModel;
  final String? Function(T)? getProductMadeIn;
  final String? Function(T)? getProductGrade;
  final String? Function(T)? getProductColor;
  final String? Function(T)? getProductDetails;

  // Optional custom builders
  final ProductListItemBuilder<T>? customListItemBuilder;
  final ProductDetailsBuilder<T>? customDetailsBuilder;

  final String noResultsText;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool showClearButton;
  final bool showAllOnFocus;
  final bool openOverlayOnFocus;

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
    this.getProductUnit,
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
  });

  @override
  State<ProductSearchField<T, B, S>> createState() =>
      _ProductSearchFieldState<T, B, S>();
}

class _ProductSearchFieldState<T, B extends BlocBase<S>, S>
    extends State<ProductSearchField<T, B, S>> {
  int _highlightedIndex = -1;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();
  List<T> _currentSuggestions = [];
  Timer? _debounce;
  late FocusNode _focusNode;
  bool _firstFocus = true;
  final FocusNode _keyboardListenerFocusNode = FocusNode(skipTraversal: true);
  T? _selectedItem;
  T? _currentHighlightedItem;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isOverlayHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardListenerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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
    _focusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardListenerFocusNode.requestFocus();
      }
    });
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_focusNode.hasFocus) {
      if (widget.showAllOnFocus &&
          _firstFocus &&
          widget.fetchAllFunction != null) {
        widget.fetchAllFunction!(widget.bloc!);
        _firstFocus = false;
      }

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
    if (!_scrollController.hasClients || _highlightedIndex < 0) return;

    const itemHeight = 72.0;

    final viewportStart = _scrollController.offset;
    final viewportEnd =
        viewportStart + _scrollController.position.viewportDimension;

    final itemStart = _highlightedIndex * itemHeight;
    final itemEnd = itemStart + itemHeight;

    // ✅ Scroll DOWN only if item is below view
    if (itemEnd > viewportEnd) {
      _scrollController.animateTo(
        itemEnd - _scrollController.position.viewportDimension,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
    // ✅ Scroll UP only if item is above view
    else if (itemStart < viewportStart) {
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
    final overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox?;

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
    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _closeOverlayAndReset();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.black.withValues(alpha: .5)),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .5),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: .2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: .05),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: .1),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            size: 20,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text:
                                                    '${AppLocalizations.of(context)!.searchResultTitle} ',
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                    '${AppLocalizations.of(context)!.forTitle} ',
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.outline,
                                                      fontWeight:
                                                      FontWeight.normal,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                    '"${widget.controller.text}"',
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                  ),
                                                  if (!_isLoading &&
                                                      _currentSuggestions
                                                          .isNotEmpty)
                                                    TextSpan(
                                                      text:
                                                      ' (${_currentSuggestions.length})',
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.outline,
                                                        fontWeight:
                                                        FontWeight.normal,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (_isLoading)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outline,
                                            ),
                                            onPressed: _closeOverlayAndReset,
                                            tooltip: 'Close (ESC)',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: _isLoading
                                          ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Searching...',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                          : _currentSuggestions.isEmpty
                                          ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search_off,
                                              size: 48,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withValues(alpha: .5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              widget.noResultsText,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                          : ListView.builder(
                                        controller: _scrollController,
                                        padding:
                                        const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        itemCount:
                                        _currentSuggestions.length,
                                        itemBuilder: (context, index) {
                                          final item =
                                          _currentSuggestions[index];
                                          final isHighlighted =
                                              index == _highlightedIndex;

                                          return Container(
                                            decoration: BoxDecoration(
                                              color: isHighlighted
                                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
                                                  : Colors.transparent,
                                              border: isHighlighted
                                                  ? Border(
                                                left: isRTL
                                                    ? BorderSide.none
                                                    : BorderSide(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  width: 3,
                                                ),
                                                right: isRTL
                                                    ? BorderSide(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  width: 3,
                                                )
                                                    : BorderSide.none,
                                              )
                                                  : null,
                                            ),
                                            child: InkWell(
                                              onTap: () =>
                                                  _handleItemSelection(
                                                    item,
                                                  ),
                                              onHover: (hovered) {
                                                if (hovered && mounted) {
                                                  setState(() {
                                                    _highlightedIndex =
                                                        index;
                                                    _currentHighlightedItem =
                                                        item;
                                                  });
                                                  _refreshOverlay();
                                                }
                                              },
                                              child:
                                              widget.customListItemBuilder !=
                                                  null
                                                  ? widget
                                                  .customListItemBuilder!(
                                                context,
                                                item,
                                              )
                                                  : _buildDefaultListItem(
                                                item,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (!_isLoading &&
                                        _currentSuggestions.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: .5),
                                          border: Border(
                                            top: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withValues(alpha: .1),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            _buildKeyHint(
                                              context,
                                              '↑↓',
                                              AppLocalizations.of(context)!.navigateTitle,
                                            ),
                                            const SizedBox(width: 16),
                                            _buildKeyHint(
                                              context,
                                              '⏎',
                                              AppLocalizations.of(
                                                context,
                                              )!.selectTitle,
                                            ),
                                            const SizedBox(width: 16),
                                            _buildKeyHint(
                                              context,
                                              'ESC',
                                              AppLocalizations.of(
                                                context,
                                              )!.closeTitle,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (_currentHighlightedItem != null &&
                                !_isLoading &&
                                _currentSuggestions.isNotEmpty)
                              Flexible(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: .1),
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.inventory_2_rounded,
                                              size: 20,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.productDetails,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                    FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.completeInformation,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
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
                                          child:
                                          widget.customDetailsBuilder !=
                                              null
                                              ? widget.customDetailsBuilder!(
                                            context,
                                            _currentHighlightedItem as T,
                                          )
                                              : _buildDefaultDetails(
                                            _currentHighlightedItem as T,
                                          ),
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

  Widget _buildDefaultListItem(T product) {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.getProductName(product) ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildInfoChip(
                      context,
                      icon: Icons.store,
                      label:
                      '${tr.storage}: ${widget.getStorageName(product) ?? 'N/A'}',
                    ),
                    _buildInfoChip(
                      context,
                      icon: Icons.numbers,
                      label:
                      '${tr.codeTitle}: ${widget.getProductCode(product) ?? 'N/A'}',
                    ),

                  ],
                ),

              ],
            ),
          ),
          Row(
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tr.batchTitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      widget.getBatch(product).toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAvailabilityColor(
                    widget.getAvailable(product) ?? '0',
                  ).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tr.availableTitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getAvailabilityColor(
                          widget.getAvailable(product) ?? '0',
                        ),
                      ),
                    ),
                    Text(
                      widget.getAvailable(product) ?? '0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _getAvailabilityColor(
                          widget.getAvailable(product) ?? '0',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      BuildContext context, {
        required IconData icon,
        required String label,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
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
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: .01),
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      size: 24,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 3,
                      children: [
                        Text(
                          widget.getProductName(product) ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tr.codeTitle}: ${widget.getProductCode(product) ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
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
        const SizedBox(height: 16),
        _buildDetailCard(tr.stock, [
          _buildDetailItem(
            Icons.store,
            tr.storage,
            widget.getStorageName(product) ?? 'N/A',
          ),
          _buildDetailItem(
            Icons.numbers,
            tr.batchTitle,
            widget.getBatch(product)?.toString() ?? 'N/A',
          ),
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
          _buildDetailItem(
            Icons.trending_up,
            tr.averagePrice,
            widget.getAveragePrice(product).toAmount(),
            currency: "USD"
          ),
          _buildDetailItem(
            Icons.history,
            tr.recentPrice,
            widget.getRecentPrice(product).toAmount(),
            currency: "USD"
          ),
          _buildDetailItem(
            Icons.dark_mode,
            tr.landedPrice,
            widget.getLandedPrice(product).toAmount(),
            currency: "USD"
          ),
          _buildDetailItem(
            Icons.attach_money,
            tr.sellPrice,
            widget.getSellPrice(product).toAmount(),
            color: Colors.green,
            isBold: true,
            currency: "USD"
          ),
        ]),
        const SizedBox(height: 16),
        _buildDetailCard(tr.productSpecification, [
          if (widget.getProductUnit != null)
            _buildDetailItem(
              Icons.category,
              'Unit',
              widget.getProductUnit!(product) ?? 'N/A',
            ),
          if (widget.getProductBrand != null)
            _buildDetailItem(
              Icons.branding_watermark,
              'Brand',
              widget.getProductBrand!(product) ?? 'N/A',
            ),
          if (widget.getProductModel != null)
            _buildDetailItem(
              Icons.model_training,
              'Model',
              widget.getProductModel!(product) ?? 'N/A',
            ),
          if (widget.getProductMadeIn != null)
            _buildDetailItem(
              Icons.location_on,
              'Made In',
              widget.getProductMadeIn!(product) ?? 'N/A',
            ),
          if (widget.getProductGrade != null)
            _buildDetailItem(
              Icons.star,
              'Grade',
              widget.getProductGrade!(product) ?? 'N/A',
            ),
          if (widget.getProductColor != null)
            _buildDetailItem(
              Icons.color_lens,
              'Color',
              widget.getProductColor!(product) ?? 'N/A',
            ),
        ]),
        const SizedBox(height: 8),
        if (widget.getProductDetails != null &&
            widget.getProductDetails!(product) != null &&
            widget.getProductDetails!(product)!.isNotEmpty)
          _buildDetailCard(tr.productDetails, [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.getProductDetails!(product) ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
        String? currency, // ✅ NEW
        Color? color,
        bool isBold = false,
      }) {
    final displayValue =
    currency != null && currency.isNotEmpty
        ? "$value $currency"
        : value;

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
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
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
         ZCover(
             radius: 3,
             padding: EdgeInsets.symmetric(horizontal: 3),
             child: SectionTitle(title: title)),
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
    widget.controller.text = widget.itemToString(item);

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
    _closeOverlayAndReset();
  }

  Widget? _buildSuffixIcon() {
    return widget.showClearButton && widget.controller.text.isNotEmpty
        ? IconButton(
      constraints: const BoxConstraints(),
      splashRadius: 2,
      icon: Icon(
        Icons.clear,
        size: 16,
        color: Theme.of(context).colorScheme.secondary,
      ),
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

    if (_overlayEntry == null) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_currentSuggestions.isNotEmpty && mounted) {
        setState(() {
          _highlightedIndex =
              (_highlightedIndex + 1) % _currentSuggestions.length;
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
          _highlightedIndex =
              (_highlightedIndex - 1 + _currentSuggestions.length) %
                  _currentSuggestions.length;
          _currentHighlightedItem = _currentSuggestions[_highlightedIndex];
        });
        _scrollToHighlightedItem();
        _refreshOverlay();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 &&
          _highlightedIndex < _currentSuggestions.length) {
        final selectedItem = _currentSuggestions[_highlightedIndex];
        _handleItemSelection(selectedItem);
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
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  key: _fieldKey,
                  controller: widget.controller,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _highlightedIndex = -1;
                      });
                    }

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

                      if (_focusNode.hasFocus) {
                        _showOverlay();
                      }
                    }

                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      if (!mounted) return;

                      if (value.isNotEmpty && widget.searchFunction != null) {
                        widget.searchFunction!(widget.bloc!, value);
                      } else if (value.isEmpty) {
                        setState(() {
                          _currentSuggestions = [];
                          _isLoading = false;
                        });
                        _removeOverlay();
                      }
                    });
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
                  final items = widget.stateToItems(state);
                  final isLoading =
                      widget.stateToLoading != null &&
                          widget.stateToLoading!(state);

                  if (mounted) {
                    setState(() {
                      _currentSuggestions = items;
                      _isLoading = isLoading;

                      if (_selectedItem != null && items.isNotEmpty) {
                        final selectedIndex = items.indexWhere(
                              (item) =>
                          widget.itemToString(item) ==
                              widget.itemToString(_selectedItem as T),
                        );

                        if (selectedIndex >= 0) {
                          _highlightedIndex = selectedIndex;
                          _currentHighlightedItem = _selectedItem;
                        } else if (_highlightedIndex >= items.length) {
                          _highlightedIndex = items.isEmpty ? -1 : 0;
                          _currentHighlightedItem = items.isNotEmpty
                              ? items[_highlightedIndex]
                              : null;
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
                    });
                  }

                  final hasText = widget.controller.text.isNotEmpty;
                  if (_focusNode.hasFocus &&
                      (hasText || isLoading || widget.openOverlayOnFocus)) {
                    _showOverlay();
                  } else if (!_focusNode.hasFocus && !_isOverlayHovered) {
                    _removeOverlay();
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