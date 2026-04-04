import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
enum ZTextFieldBorderType {
  rounded,
  underline,
}
class ZTextFieldEntitled extends StatelessWidget {
  final String title;
  final String? hint;
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
  final bool securePassword;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final FormFieldValidator? validator;
  final TextInputType? keyboardInputType;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? trailing;
  final double width;
  final bool? compactMode;
  final bool autoFocus;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormat;

  /// ✅ ONLY ADD THIS
  final List<String>? suggestions;

  const ZTextFieldEntitled({
    super.key,
    required this.title,
    this.showClearButton = false,
    this.hint,
    this.readOnly = false,
    this.errorMessage = "",
    this.maxLength,
    this.infoColor,
    this.borderType = ZTextFieldBorderType.rounded,
    this.autoFocus = true,
    this.compactMode,
    this.vertical,
    this.isEnabled = true,
    this.securePassword = false,
    this.end,
    this.focusNode,
    this.isRequired = false,
    this.icon,
    this.inputFormat,
    this.validator,
    this.onSubmit,
    this.controller,
    this.onChanged,
    this.width = .5,
    this.trailing,
    this.keyboardInputType,
    this.inputAction,
    this.suggestions, // 👈 added
  });

  @override
  Widget build(BuildContext context) {
    final textController = controller ?? TextEditingController();
    final node = focusNode ?? FocusNode();

    Widget buildField(TextEditingController ctrl, FocusNode focus) {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: ctrl,
        builder: (context, value, _) {
          return TextFormField(
            readOnly: readOnly,
            focusNode: focus,
            autofocus: autoFocus,
            enabled: isEnabled,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmit,
            obscureText: securePassword,
            inputFormatters: inputFormat,
            keyboardType: keyboardInputType,
            controller: ctrl,
            maxLength: maxLength,
            maxLines:
            keyboardInputType == TextInputType.multiline ? null : 1,
            minLines:
            keyboardInputType == TextInputType.multiline ? 3 : 1,
            decoration: InputDecoration(
              filled: !isEnabled,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showClearButton && value.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        ctrl.clear();
                        if (onChanged != null) onChanged!('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.close, size: 18),
                      ),
                    ),

                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: trailing!,
                    ),
                ],
              ),
              suffix: end,
              counterText: '',
              suffixIconConstraints:
              const BoxConstraints(maxWidth: 80, maxHeight: 40),

              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: .3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: .3),
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
              prefixIcon: icon != null ? Icon(icon, size: 18) : null,
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.outline,
              ),
              isDense: compactMode ?? true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 5,
                vertical: vertical ?? 12.0,
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0),
      child: Column(
        children: [
          Row(
            children: [
              if (title.isNotEmpty)
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .outline,
                      ),
                    ),
                    isRequired
                        ? Text(
                      " *",
                      style: TextStyle(
                          color: Colors.red.shade900),
                    )
                        : const SizedBox(),
                  ],
                ),
            ],
          ),

          if (title.isNotEmpty)
            const SizedBox(height: 4),

          Row(
            children: [
              Flexible(
                child: suggestions != null &&
                    suggestions!.isNotEmpty
                    ? RawAutocomplete<String>(
                  textEditingController:
                  textController,
                  focusNode: node,

                  optionsBuilder: (value) {
                    if (value.text.isEmpty) {
                      return suggestions!;
                    }
                    return suggestions!.where(
                          (item) => item
                          .toLowerCase()
                          .contains(value.text
                          .toLowerCase()),
                    );
                  },

                  onSelected: (val) {
                    textController.text = val;
                    if (onChanged != null) {
                      onChanged!(val);
                    }
                  },

                  fieldViewBuilder:
                      (context, ctrl, focusNode,
                      onFieldSubmitted) {
                    return buildField(
                        ctrl, focusNode);
                  },

                  optionsViewBuilder:
                      (context, onSelected,
                      options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: SizedBox(
                          width: 300,
                          child: ListView.builder(
                            padding:
                            EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount:
                            options.length,
                            itemBuilder:
                                (context, index) {
                              final option =
                              options
                                  .elementAt(
                                  index);

                              return InkWell(
                                onTap: () =>
                                    onSelected(
                                        option),
                                child: Padding(
                                  padding:
                                  const EdgeInsets
                                      .all(10),
                                  child:
                                  Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                )
                    : buildField(textController, node),
              ),
            ],
          ),

          errorMessage.isNotEmpty
              ? Padding(
            padding:
            const EdgeInsets.symmetric(
                vertical: 4.0),
            child: Row(
              children: [
                Text(
                  errorMessage,
                  style: TextStyle(
                    color: infoColor ??
                        Theme.of(context)
                            .colorScheme
                            .primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
              : const SizedBox(),
        ],
      ),
    );
  }
}