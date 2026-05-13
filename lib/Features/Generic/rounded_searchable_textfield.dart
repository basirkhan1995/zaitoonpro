import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';

typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef ItemToString<T> = String Function(T item);
typedef OnItemSelected<T> = void Function(T item);
typedef BlocSearchFunction<B> = void Function(B bloc, String query);
typedef BlocFetchAllFunction<B> = void Function(B bloc);
typedef OnFieldSubmitFunction = void Function({required String name});

enum TextFieldStyle {
  roundedBorder,
  underline,
  noBorder,
}

class GenericTextField<T, B extends BlocBase<S>, S> extends StatefulWidget {
  final LoadingBuilder? loadingBuilder;
  final bool Function(S state)? stateToLoading;
  final double? width;
  final double? height;
  final bool isEnabled;
  final TextEditingController? controller;
  final String? hintText;
  final String title;
  final bool compactMode;
  final Widget? trailing;
  final Widget? end;
  final IconData? icon;
  final bool isRequired;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final OnItemSelected<T>? onSelected;
  final OnFieldSubmitFunction? onSubmitted;
  final ItemBuilder<T> itemBuilder;
  final ItemToString<T> itemToString;
  final B? bloc;
  final BlocSearchFunction<B>? searchFunction;
  final BlocFetchAllFunction<B>? fetchAllFunction;
  final String? Function(T)? itemValidator;
  final String noResultsText;
  final List<T> Function(S state) stateToItems;
  final EdgeInsetsGeometry? padding;
  final bool readOnly;
  final bool showClearButton;
  final bool showAllOnFocus;
  final T? allOption;
  final bool showAllOption;
  final String allOptionText;
  final TextFieldStyle textFieldStyle;

  /// Optional external focus node
  final FocusNode? focusNode;

  const GenericTextField({
    super.key,
    this.isEnabled = true,
    this.height = 60,
    required this.controller,
    required this.title,
    this.onSubmitted,
    this.readOnly = false,
    required this.itemBuilder,
    required this.itemToString,
    required this.stateToItems,
    this.loadingBuilder,
    this.stateToLoading,
    this.bloc,
    this.searchFunction,
    this.fetchAllFunction,
    this.hintText,
    this.compactMode = true,
    this.onSelected,
    this.icon,
    this.trailing,
    this.end,
    this.isRequired = false,
    this.onChanged,
    this.validator,
    this.width,
    this.itemValidator,
    this.noResultsText = 'No results found',
    this.padding,
    this.showClearButton = true,
    this.showAllOnFocus = true,
    this.allOption,
    this.showAllOption = false,
    this.allOptionText = 'All',
    this.textFieldStyle = TextFieldStyle.roundedBorder,
    this.focusNode,
  }) : assert(
  bloc != null || searchFunction == null,
  'If searchFunction is provided, bloc must also be provided',
  );

  @override
  State<GenericTextField<T, B, S>> createState() => _GenericTextFieldState<T, B, S>();
}

class _GenericTextFieldState<T, B extends BlocBase<S>, S>
    extends State<GenericTextField<T, B, S>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();

  late FocusNode _focusNode;

  List<T> _currentSuggestions = [];
  Timer? _debounce;

  bool _showClear = false;
  bool _firstFocus = true;

  /// Keyboard navigation index
  int _highlightedIndex = -1;

  bool get _usingExternalFocusNode => widget.focusNode != null;

  @override
  void initState() {
    super.initState();

    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChange);
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(
      covariant GenericTextField<T, B, S> oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);

      if (!_usingExternalFocusNode) {
        _focusNode.dispose();
      }

      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);

    if (!_usingExternalFocusNode) {
      _focusNode.dispose();
    }

    widget.controller?.removeListener(_onControllerChanged);

    _debounce?.cancel();
    _removeOverlay();

    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    setState(() {
      _showClear = widget.controller?.text.isNotEmpty == true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onFocusChange() {
    if (widget.readOnly) {
      _removeOverlay();
      return;
    }

    if (_focusNode.hasFocus) {
      if (widget.showAllOnFocus &&
          _firstFocus &&
          widget.bloc != null &&
          widget.fetchAllFunction != null) {
        widget.fetchAllFunction!(widget.bloc!);
        _firstFocus = false;
      }

      if (_currentSuggestions.isNotEmpty) {
        _showOverlay(_currentSuggestions);
      }
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _selectItem(T item) {
    final itemText = widget.itemToString(item);

    widget.controller?.text = itemText;

    widget.onSelected?.call(item);
    widget.onChanged?.call(itemText);

    _removeOverlay();
    _focusNode.unfocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final allItems = _getAllItems();

    if (allItems.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < allItems.length - 1) {
          _highlightedIndex++;
        } else {
          _highlightedIndex = 0;
        }
      });

      _showOverlay(_currentSuggestions);
    }

    else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex > 0) {
          _highlightedIndex--;
        } else {
          _highlightedIndex = allItems.length - 1;
        }
      });

      _showOverlay(_currentSuggestions);
    }

    else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 &&
          _highlightedIndex < allItems.length) {
        _selectItem(allItems[_highlightedIndex]);
      }
    }

    else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
    }
  }

  List<T> _getAllItems() {
    final items = [..._currentSuggestions];

    if (widget.showAllOption && widget.allOption != null) {
      items.insert(0, widget.allOption as T);
    }

    return items;
  }

  void _showOverlay(List<T> items) {
    _removeOverlay();

    final renderBox =
    _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    final overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null) return;

    final position =
    renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + renderBox.size.height + 4,
        width: renderBox.size.width,
        child: Material(
          elevation: 1,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              width: 1,
            ),
          ),
          child: _buildSuggestionsList(items),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildSuggestionsList(List<T> items) {
    final allItems = _getAllItems();

    if (allItems.isEmpty) {
      final isLoading = widget.bloc != null &&
          widget.stateToLoading != null &&
          widget.stateToLoading!(widget.bloc!.state);

      return SizedBox(
        height: widget.height,
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : Text(
            widget.noResultsText,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: .7),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];

          final isHighlighted = index == _highlightedIndex;

          return Material(
            color: isHighlighted
                ? Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: .10)
                : Colors.transparent,
            child: InkWell(
              hoverColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: .05),
              highlightColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: .05),
              onTap: () => _selectItem(item),
              child: widget.itemBuilder(context, item),
            ),
          );
        },
      ),
    );
  }

  String? _customValidator(String? value) {
    if (widget.isRequired &&
        (value == null || value.isEmpty)) {
      return AppLocalizations.of(context)!
          .required(widget.title);
    }

    if (widget.itemValidator != null) {
      T? selectedItem;

      try {
        selectedItem = _currentSuggestions.firstWhere(
              (item) => widget.itemToString(item) == value,
        );
      } catch (_) {
        selectedItem = null;
      }

      if (selectedItem != null) {
        return widget.itemValidator!(selectedItem);
      }
    }

    if (value != null &&
        value.isNotEmpty &&
        !_currentSuggestions.any(
              (item) => widget.itemToString(item) == value,
        )) {
      return widget.title;
    }

    return null;
  }

  Widget? _buildSuffixIcon() {
    final isLoading = widget.bloc != null &&
        widget.stateToLoading != null &&
        widget.stateToLoading!(widget.bloc!.state);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 10),
            child: widget.loadingBuilder?.call(context) ??
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
          ),
        if (_showClear &&
            widget.showClearButton &&
            !isLoading)
          IconButton(
            splashRadius: 2,
            splashColor: Theme.of(context)
                .colorScheme
                .primary
                .withAlpha(23),
            highlightColor: Theme.of(context)
                .colorScheme
                .primary
                .withAlpha(23),
            hoverColor: Theme.of(context)
                .colorScheme
                .primary
                .withAlpha(23),
            icon: Icon(
              Icons.clear,
              size: 14,
              color:
              Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              widget.controller?.clear();

              widget.onChanged?.call('');

              setState(() {
                _currentSuggestions = [];
                _showClear = false;
                _firstFocus = true;
                _highlightedIndex = -1;
              });

              _removeOverlay();
            },
          ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  InputBorder _getEnabledBorder() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .secondary
                .withValues(alpha: .3),
          ),
        );

      case TextFieldStyle.underline:
        return const UnderlineInputBorder();

      case TextFieldStyle.noBorder:
        return const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        );
    }
  }

  InputBorder _getFocusedBorder() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        );

      case TextFieldStyle.underline:
        return UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        );

      case TextFieldStyle.noBorder:
        return const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        );
    }
  }

  InputBorder _getErrorBorder() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        );

      case TextFieldStyle.underline:
        return const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        );

      case TextFieldStyle.noBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        );
    }
  }

  InputBorder _getDisabledBorder() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .secondary
                .withValues(alpha: .2),
          ),
        );

      case TextFieldStyle.underline:
        return const UnderlineInputBorder();

      case TextFieldStyle.noBorder:
        return const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        );
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        );

      case TextFieldStyle.underline:
        return const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        );

      case TextFieldStyle.noBorder:
        return const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title.isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.isRequired)
                      Padding(
                        padding:
                        const EdgeInsets.only(left: 2),
                        child: Text(
                          ' *',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Container(
              decoration:
              widget.textFieldStyle ==
                  TextFieldStyle.noBorder
                  ? BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: .08),
                borderRadius:
                BorderRadius.circular(4),
              )
                  : null,
              child: KeyboardListener(
                focusNode: FocusNode(skipTraversal: true),
                onKeyEvent: _handleKeyEvent,
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextFormField(
                    focusNode: _focusNode,
                    key: _fieldKey,
                    controller: widget.controller,
                    enabled: widget.isEnabled,
                    readOnly: widget.readOnly,
                    validator:
                    widget.validator ?? _customValidator,

                    onChanged: (value) {
                      if (widget.readOnly) return;

                      setState(() {
                        _showClear = value.isNotEmpty;
                        _highlightedIndex = -1;
                      });

                      if (_debounce?.isActive ?? false) {
                        _debounce?.cancel();
                      }

                      _debounce = Timer(
                        const Duration(milliseconds: 500),
                            () {
                          if (value.isNotEmpty &&
                              widget.bloc != null &&
                              widget.searchFunction != null) {
                            widget.searchFunction!(
                              widget.bloc!,
                              value,
                            );
                          } else if (value.isEmpty &&
                              widget.bloc != null &&
                              widget.fetchAllFunction !=
                                  null) {
                            widget.fetchAllFunction!(
                              widget.bloc!,
                            );
                          } else {
                            _currentSuggestions = [];
                            _removeOverlay();
                          }
                        },
                      );
                    },

                    onFieldSubmitted: (value) {
                      final input = value.trim();

                      widget.onSubmitted?.call(
                        name: input,
                      );

                      T? match;

                      try {
                        match =
                            _currentSuggestions.firstWhere(
                                  (item) {
                                String? code;

                                try {
                                  final dynamic dyn = item;
                                  code = dyn.proCode
                                      ?.toLowerCase();
                                } catch (_) {
                                  code = null;
                                }

                                return code ==
                                    input.toLowerCase();
                              },
                            );
                      } catch (_) {
                        match = null;
                      }

                      if (match != null) {
                        widget.controller?.text =
                            widget.itemToString(match);

                        widget.onChanged?.call(
                          widget.itemToString(match),
                        );

                        widget.onSelected?.call(match);

                        _focusNode.unfocus();

                        _removeOverlay();
                      }
                    },

                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface,
                    ),

                    decoration: InputDecoration(
                      isDense: true,

                      prefixIcon: widget.icon != null
                          ? Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                        ),
                      )
                          : null,

                      suffixIcon: _buildSuffixIcon(),

                      hintText: widget.hintText,

                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: .5),
                      ),

                      contentPadding:
                      _getContentPadding(),

                      disabledBorder:
                      _getDisabledBorder(),

                      enabledBorder:
                      _getEnabledBorder(),

                      focusedBorder:
                      _getFocusedBorder(),

                      focusedErrorBorder:
                      _getErrorBorder(),

                      errorBorder: _getErrorBorder(),

                      errorStyle:
                      const TextStyle(fontSize: 11),

                      fillColor:
                      widget.textFieldStyle ==
                          TextFieldStyle.noBorder
                          ? Colors.transparent
                          : null,

                      filled:
                      widget.textFieldStyle ==
                          TextFieldStyle.noBorder,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.end != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: widget.end,
              ),
            if (widget.bloc != null)
              BlocListener<B, S>(
                bloc: widget.bloc,
                listener: (context, state) {
                  if (widget.readOnly) return;

                  final items =
                  widget.stateToItems(state);

                  setState(() {
                    _currentSuggestions = items;

                    if (_highlightedIndex >=
                        items.length) {
                      _highlightedIndex =
                      items.isEmpty ? -1 : 0;
                    }
                  });

                  if (_focusNode.hasFocus) {
                    _showOverlay(items);
                  } else {
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