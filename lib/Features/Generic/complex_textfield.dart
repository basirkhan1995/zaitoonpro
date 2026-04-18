// generic_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flag/flag_widget.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import '../../Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/bloc/currencies_bloc.dart';
import '../../Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';

// ============================================
// ENUMS
// ============================================
enum ZTextFieldBorderType {
  rounded,
  underline,
}

enum ZTextFieldType {
  text,      // Regular text input
  numeric,   // Numbers only (integers)
  amount,    // Decimal numbers with currency symbol
  currency,  // Currency selector with dropdown
  email,     // Email input
  phone,     // Phone number input
  password,  // Password input
  multiline, // Multi-line text
  currencyWithAmount, // Combined currency + amount field
}

enum CurrencyPosition {
  prefix,  // Currency symbol on left
  suffix,  // Currency symbol on right
}

// ============================================
// MODELS
// ============================================
class CurrencyItem {
  final String code;
  final String symbol;
  final String? name;
  final Widget? flagIcon;
  final String? countryCode;
  final CurrenciesModel? originalModel;

  const CurrencyItem({
    required this.code,
    required this.symbol,
    this.name,
    this.flagIcon,
    this.countryCode,
    this.originalModel,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrencyItem &&
        other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

// ============================================
// THOUSAND SEPARATOR FORMATTER
// ============================================
class _ThousandSeparatorFormatter extends TextInputFormatter {
  final int decimalPlaces;

  _ThousandSeparatorFormatter({this.decimalPlaces = 2});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // If the new value is empty, return it
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove existing separators
    final rawText = newValue.text.replaceAll(',', '');

    // Allow empty or just decimal point
    if (rawText.isEmpty || rawText == '.') {
      return newValue;
    }

    // Check if it matches the decimal pattern
    final decimalRegex = RegExp(r'^\d*\.?\d{0,' + decimalPlaces.toString() + r'}$');
    if (!decimalRegex.hasMatch(rawText)) {
      // If invalid, return the old value
      return oldValue;
    }

    // Format with thousand separators
    String formattedText;
    if (rawText.contains('.')) {
      final parts = rawText.split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';

      // Format integer part with commas
      String formattedInteger = integerPart;
      if (integerPart.isNotEmpty) {
        final intValue = int.tryParse(integerPart);
        if (intValue != null) {
          formattedInteger = _formatWithCommas(intValue);
        }
      }

      formattedText = decimalPart.isNotEmpty
          ? '$formattedInteger.$decimalPart'
          : formattedInteger;
    } else {
      final intValue = int.tryParse(rawText);
      formattedText = intValue != null ? _formatWithCommas(intValue) : rawText;
    }

    // Preserve cursor position at the end
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _formatWithCommas(int value) {
    final chars = value.toString().split('');
    final result = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(chars[i]);
    }
    return result.toString();
  }
}

// Helper function to clean amount (remove commas and formatting)
String cleanAmount(String formattedAmount) {
  if (formattedAmount.isEmpty) return '';
  return formattedAmount.replaceAll(',', '');
}

// Helper function to get double value from formatted amount
double? getAmountValue(String formattedAmount) {
  final clean = cleanAmount(formattedAmount);
  return double.tryParse(clean);
}

// ============================================
// MAIN WIDGET
// ============================================
class ZGenericTextField extends StatefulWidget {
  // Basic properties
  final String title;
  final String? hint;
  final ZTextFieldType fieldType;
  final bool isRequired;
  final bool isEnabled;
  final bool readOnly;
  final double? vertical;
  final ZTextFieldBorderType borderType;
  final bool showClearButton;
  final IconData? icon;
  final String errorMessage;
  final Color? infoColor;
  final Widget? end;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final FormFieldValidator? validator;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? trailing;
  final double width;
  final bool? compactMode;
  final bool autoFocus;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormat;

  // Currency specific properties
  final ValueChanged<CurrenciesModel?>? onCurrencyChanged;
  final ValueChanged<(CurrenciesModel?, String)>? onCurrencyAmountChanged;
  final String? defaultCurrencyCode;
  final bool showFlag;
  final bool showSymbol;
  final int decimalPlaces;
  final String? fixedCurrencySymbol;
  final bool showCurrencySymbol;
  final CurrencyPosition currencyPosition;

  // Numeric specific properties
  final double? minValue;
  final double? maxValue;
  final bool allowNegative;

  // Thousand separator feature
  final bool useThousandSeparator; // NEW: Enable thousand separator

  // Email/Phone specific
  final String? countryCode;

  const ZGenericTextField({
    super.key,
    required this.title,
    this.hint,
    this.fieldType = ZTextFieldType.text,
    this.isRequired = false,
    this.isEnabled = true,
    this.readOnly = false,
    this.vertical,
    this.borderType = ZTextFieldBorderType.rounded,
    this.showClearButton = false,
    this.icon,
    this.errorMessage = "",
    this.infoColor,
    this.end,
    this.inputAction,
    this.onChanged,
    this.onSubmit,
    this.validator,
    this.controller,
    this.focusNode,
    this.trailing,
    this.width = .5,
    this.compactMode = true,
    this.autoFocus = false,
    this.maxLength,
    this.maxLines,
    this.minLines,
    this.inputFormat,

    // Currency params
    this.onCurrencyChanged,
    this.onCurrencyAmountChanged,
    this.defaultCurrencyCode,
    this.showFlag = true,
    this.showSymbol = true,
    this.decimalPlaces = 2,
    this.fixedCurrencySymbol,
    this.showCurrencySymbol = true,
    this.currencyPosition = CurrencyPosition.prefix,

    // Numeric params
    this.minValue,
    this.maxValue,
    this.allowNegative = false,

    // Thousand separator
    this.useThousandSeparator = false, // Default to false

    // Phone params
    this.countryCode,
  });

  @override
  State<ZGenericTextField> createState() => _ZGenericTextFieldState();
}

class _ZGenericTextFieldState extends State<ZGenericTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late List<TextInputFormatter> _formatters;
  CurrenciesModel? _selectedCurrency;
  List<CurrencyItem> _currencyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupInputFormatters();

    if (widget.fieldType == ZTextFieldType.currencyWithAmount) {
      _controller.addListener(_onAmountChanged);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.fieldType == ZTextFieldType.currencyWithAmount) {
      _controller.removeListener(_onAmountChanged);
    }
    super.dispose();
  }

  void _onAmountChanged() {
    if (widget.onCurrencyAmountChanged != null && _selectedCurrency != null) {
      // Send clean amount without commas
      final cleanAmount = _controller.text.cleanAmount;
      widget.onCurrencyAmountChanged!((_selectedCurrency, cleanAmount));
    }
  }

  void _setupInputFormatters() {
    _formatters = [];

    switch (widget.fieldType) {
      case ZTextFieldType.numeric:
        _formatters.add(
          FilteringTextInputFormatter.allow(RegExp(widget.allowNegative ? r'^-?\d*$' : r'^\d*$')),
        );
        break;

      case ZTextFieldType.amount:
      case ZTextFieldType.currencyWithAmount:
      // Add thousand separator formatter if enabled
        if (widget.useThousandSeparator) {
          _formatters.add(_ThousandSeparatorFormatter(decimalPlaces: widget.decimalPlaces));
        } else {
          _formatters.add(
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,' + widget.decimalPlaces.toString() + r'}')),
          );
        }

        if (widget.minValue != null || widget.maxValue != null) {
          _formatters.add(_NumericRangeFormatter(
            minValue: widget.minValue,
            maxValue: widget.maxValue,
          ));
        }
        break;

      case ZTextFieldType.email:
        _formatters.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
        break;

      case ZTextFieldType.phone:
        _formatters.add(FilteringTextInputFormatter.allow(RegExp(r'^[\d+\-\(\)\s]+$')));
        break;

      case ZTextFieldType.password:
      case ZTextFieldType.text:
      case ZTextFieldType.multiline:
      case ZTextFieldType.currency:
        break;
    }

    if (widget.inputFormat != null) {
      _formatters.addAll(widget.inputFormat!);
    }
  }

  TextInputType _getKeyboardType() {
    switch (widget.fieldType) {
      case ZTextFieldType.numeric:
      case ZTextFieldType.amount:
      case ZTextFieldType.currencyWithAmount:
        return const TextInputType.numberWithOptions(decimal: true);
      case ZTextFieldType.email:
        return TextInputType.emailAddress;
      case ZTextFieldType.phone:
        return TextInputType.phone;
      case ZTextFieldType.multiline:
        return TextInputType.multiline;
      case ZTextFieldType.text:
      case ZTextFieldType.password:
      case ZTextFieldType.currency:
        return TextInputType.text;
    }
  }

  bool _isObscure() {
    return widget.fieldType == ZTextFieldType.password;
  }

  List<CurrencyItem> _convertToCurrencyItems(List<CurrenciesModel> currencies) {
    return currencies.map((currency) {
      return CurrencyItem(
        code: currency.ccyCode ?? "",
        symbol: currency.ccySymbol ?? currency.ccyCode ?? "",
        name: currency.ccyName,
        countryCode: currency.ccyCountryCode,
        originalModel: currency,
        flagIcon: widget.showFlag && currency.ccyCountryCode != null
            ? SizedBox(
          width: 24,
          height: 16,
          child: Flag.fromString(
            currency.ccyCountryCode!,
            height: 16,
            width: 24,
            borderRadius: 2,
            fit: BoxFit.fill,
          ),
        )
            : null,
      );
    }).toList();
  }

  CurrenciesModel? _getDefaultCurrency(List<CurrenciesModel> currencies) {
    if (currencies.isEmpty) return null;

    if (widget.defaultCurrencyCode != null && widget.defaultCurrencyCode!.isNotEmpty) {
      try {
        return currencies.firstWhere(
              (c) => c.ccyCode == widget.defaultCurrencyCode,
        );
      } catch (e) {
        return currencies.first;
      }
    }
    return currencies.first;
  }

  String? _validateInput(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (widget.isRequired && (value == null || value.isEmpty)) {
      return 'This field is required';
    }

    if (value != null && value.isNotEmpty) {
      // Clean the value for validation (remove commas)
      final cleanValue = cleanAmount(value);

      switch (widget.fieldType) {
        case ZTextFieldType.numeric:
          if (double.tryParse(cleanValue) == null) {
            return 'Please enter a valid number';
          }
          break;

        case ZTextFieldType.amount:
        case ZTextFieldType.currencyWithAmount:
          final amount = double.tryParse(cleanValue);
          if (amount == null) {
            return 'Please enter a valid amount';
          }
          if (widget.minValue != null && amount < widget.minValue!) {
            return 'Amount must be at least ${widget.minValue}';
          }
          if (widget.maxValue != null && amount > widget.maxValue!) {
            return 'Amount must not exceed ${widget.maxValue}';
          }
          break;

        case ZTextFieldType.email:
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          break;

        case ZTextFieldType.phone:
          if (value.length < 8) {
            return 'Please enter a valid phone number';
          }
          break;

        default:
          break;
      }
    }

    return null;
  }

  Widget _buildCurrencyContent(List<CurrenciesModel> currencies) {
    _isLoading = false;

    if (currencies.isEmpty) {
      return _buildTextField();
    }

    _currencyItems = _convertToCurrencyItems(currencies);

    _selectedCurrency ??= _getDefaultCurrency(currencies);

    final selectedCurrencyItem = _selectedCurrency != null
        ? _currencyItems.firstWhere(
          (item) => item.code == _selectedCurrency!.ccyCode,
      orElse: () => _currencyItems.first,
    )
        : null;

    return _buildTextField(
      currencyItems: _currencyItems,
      selectedCurrencyItem: selectedCurrencyItem,
      onCurrencySelected: (currencyItem) {
        final newCurrency = currencyItem.originalModel;
        setState(() {
          _selectedCurrency = newCurrency;
        });
        if (widget.onCurrencyChanged != null) {
          widget.onCurrencyChanged!(newCurrency);
        }
        if (widget.onCurrencyAmountChanged != null && _controller.text.isNotEmpty) {
          final cleanAmount = _controller.text.cleanAmount;
          widget.onCurrencyAmountChanged!((newCurrency, cleanAmount));
        }
      },
    );
  }

  Widget _buildTextField({
    List<CurrencyItem>? currencyItems,
    CurrencyItem? selectedCurrencyItem,
    Function(CurrencyItem)? onCurrencySelected,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title.isNotEmpty)
                Row(
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (widget.isRequired)
                      Text(
                        " *",
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                  ],
                ),
              if (widget.title.isNotEmpty) const SizedBox(height: 4),

              TextFormField(
                readOnly: widget.readOnly,
                focusNode: _focusNode,
                autofocus: widget.autoFocus,
                enabled: widget.isEnabled,
                validator: _validateInput,
                onChanged: (text) {
                  if (widget.onChanged != null) {
                    // Send clean amount without commas
                    final cleanText = cleanAmount(text);
                    widget.onChanged!(cleanText);
                  }
                  if (widget.fieldType == ZTextFieldType.currencyWithAmount &&
                      widget.onCurrencyAmountChanged != null &&
                      _selectedCurrency != null) {
                    final cleanAmount = text.cleanAmount;
                    widget.onCurrencyAmountChanged!((_selectedCurrency, cleanAmount));
                  }
                },
                onFieldSubmitted: widget.onSubmit,
                obscureText: _isObscure(),
                inputFormatters: _formatters,
                keyboardType: _getKeyboardType(),
                controller: _controller,
                maxLength: widget.maxLength,
                maxLines: widget.fieldType == ZTextFieldType.multiline
                    ? widget.maxLines ?? 3
                    : (widget.maxLines ?? 1),
                minLines: widget.fieldType == ZTextFieldType.multiline
                    ? widget.minLines ?? 3
                    : 1,
                decoration: InputDecoration(
                  filled: !widget.isEnabled,
                  prefixIcon: _buildPrefix(currencyItems, selectedCurrencyItem, onCurrencySelected),
                  suffixIcon: widget.fieldType == ZTextFieldType.amount
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildClearButton(value.text),
                      if (_buildSuffix(currencyItems, selectedCurrencyItem, onCurrencySelected) != null)
                        _buildSuffix(currencyItems, selectedCurrencyItem, onCurrencySelected)!,
                      if (widget.trailing != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: widget.trailing!,
                        ),
                    ].whereType<Widget>().toList(),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildClearButton(value.text),
                      if (widget.trailing != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: widget.trailing!,
                        ),
                    ].whereType<Widget>().toList(),
                  ),
                  suffix: widget.end,
                  counterText: '',
                  suffixIconConstraints: const BoxConstraints(maxWidth: 80, maxHeight: 40),

                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: .3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: .3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  isDense: widget.compactMode,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: widget.vertical ?? 12.0,
                  ),
                ),
              ),

              if (widget.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    widget.errorMessage,
                    style: TextStyle(
                      color: widget.infoColor ?? Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildPrefix(
      List<CurrencyItem>? currencyItems,
      CurrencyItem? selectedCurrencyItem,
      Function(CurrencyItem)? onCurrencySelected,
      ) {
    if (_isLoading && (widget.fieldType == ZTextFieldType.currency ||
        widget.fieldType == ZTextFieldType.currencyWithAmount)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.fieldType == ZTextFieldType.currency && currencyItems != null) {
      return _buildCurrencySelector(currencyItems, selectedCurrencyItem, onCurrencySelected);
    }

    if (widget.fieldType == ZTextFieldType.currencyWithAmount && currencyItems != null) {
      return _buildCurrencySelector(currencyItems, selectedCurrencyItem, onCurrencySelected);
    }

    if ((widget.fieldType == ZTextFieldType.amount) &&
        widget.showCurrencySymbol &&
        widget.showSymbol &&
        (widget.fixedCurrencySymbol != null || selectedCurrencyItem != null) &&
        widget.currencyPosition == CurrencyPosition.prefix) {
      final symbol = selectedCurrencyItem?.symbol ?? widget.fixedCurrencySymbol;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          symbol ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Icon(widget.icon, size: 18);
    }

    return null;
  }

  Widget? _buildSuffix(
      List<CurrencyItem>? currencyItems,
      CurrencyItem? selectedCurrencyItem,
      Function(CurrencyItem)? onCurrencySelected,
      ) {
    if (widget.fieldType == ZTextFieldType.currency) {
      return null;
    }

    if (widget.fieldType == ZTextFieldType.currencyWithAmount && currencyItems != null) {
      return null;
    }

    if ((widget.fieldType == ZTextFieldType.amount) &&
        widget.showCurrencySymbol &&
        widget.showSymbol &&
        (widget.fixedCurrencySymbol != null || selectedCurrencyItem != null) &&
        widget.currencyPosition == CurrencyPosition.suffix) {
      final symbol = selectedCurrencyItem?.symbol ?? widget.fixedCurrencySymbol;
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          symbol ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildCurrencySelector(
      List<CurrencyItem> currencyItems,
      CurrencyItem? selectedCurrencyItem,
      Function(CurrencyItem)? onCurrencySelected,
      ) {
    if (currencyItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final validSelectedItem = selectedCurrencyItem ?? currencyItems.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CurrencyItem>(
          value: validSelectedItem,
          items: currencyItems.map((currency) {
            return DropdownMenuItem<CurrencyItem>(
              value: currency,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showFlag && currency.flagIcon != null) ...[
                    currency.flagIcon!,
                    const SizedBox(width: 6),
                  ],
                  if (widget.showSymbol) ...[
                    Text(
                      currency.symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    currency.code,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (CurrencyItem? newCurrency) {
            if (newCurrency != null && onCurrencySelected != null) {
              onCurrencySelected(newCurrency);
            }
          },
          isDense: true,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: Theme.of(context).colorScheme.outline,
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildClearButton(String text) {
    if (!widget.showClearButton || text.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        _controller.clear();
        if (widget.onChanged != null) widget.onChanged!('');
        if (widget.fieldType == ZTextFieldType.currencyWithAmount &&
            widget.onCurrencyAmountChanged != null) {
          widget.onCurrencyAmountChanged!((_selectedCurrency, ''));
        }
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Icon(Icons.close, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fieldType == ZTextFieldType.currency ||
        widget.fieldType == ZTextFieldType.currencyWithAmount) {
      return BlocBuilder<CurrenciesBloc, CurrenciesState>(
        builder: (context, state) {
          if (state is CurrenciesLoadedState) {
            return _buildCurrencyContent(state.ccy);
          }
          return _buildTextField();
        },
      );
    }

    return _buildTextField();
  }
}

// ============================================
// HELPER CLASSES
// ============================================
class _NumericRangeFormatter extends TextInputFormatter {
  final double? minValue;
  final double? maxValue;

  const _NumericRangeFormatter({
    this.minValue,
    this.maxValue,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue;

    final value = double.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (minValue != null && value < minValue!) return oldValue;
    if (maxValue != null && value > maxValue!) return oldValue;

    return newValue;
  }
}