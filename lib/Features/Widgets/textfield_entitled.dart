import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZTextFieldEntitled extends StatelessWidget {
  final String title;
  final String? hint;
  final bool isRequired;
  final bool isEnabled;
  final bool readOnly;
  final double? vertical;
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

  const ZTextFieldEntitled({
    super.key,
    required this.title,
    this.hint,
    this.readOnly = false,
    this.errorMessage = "",
    this.maxLength,
    this.infoColor,
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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0),
      child: SizedBox(
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if(title.isNotEmpty)
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12,color: Theme.of(context).colorScheme.outline),
                        ),
                        isRequired
                            ? Text(
                              " *",
                              style: TextStyle(color: Colors.red.shade900),
                            )
                            : const SizedBox(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if(title.isNotEmpty)
            const SizedBox(height: 4),
            SizedBox(
              child: Row(
                children: [
                  Flexible(
                    child: TextFormField(
                      readOnly: readOnly,
                      focusNode: focusNode,
                      autofocus: autoFocus,
                      enabled: isEnabled,
                      validator: validator,
                      onChanged: onChanged,
                      onFieldSubmitted: onSubmit,
                      obscureText: securePassword,
                      inputFormatters: inputFormat,
                      keyboardType: keyboardInputType,
                      controller: controller,
                      maxLength: maxLength,
                      maxLines: keyboardInputType == TextInputType.multiline ? null : 1,
                      minLines: keyboardInputType == TextInputType.multiline ? 3 : 1,
                      decoration: InputDecoration(
                         filled: !isEnabled,
                        suffixIcon: trailing,
                        suffix: end,
                        counterText: '',
                        suffixIconConstraints: BoxConstraints(maxWidth: 35,maxHeight: 35),
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
                    ),
                  ),
                ],
              ),
            ),
            errorMessage.isNotEmpty
                ? Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        errorMessage,
                        style: TextStyle(
                          color: infoColor ?? Theme.of(context).colorScheme.primary,
                          fontSize: 13
                        ),
                      ),
                    ],
                  ),
                ) : SizedBox(),
          ],
        ),
      ),
    );
  }
}
