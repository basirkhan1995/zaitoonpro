import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';

class WhatsAppShareHelper {
  final BuildContext context;

  WhatsAppShareHelper(this.context);

  bool get mounted => context.mounted;

  String _getAccountPosition(double? balance) {
    if (balance == null || balance == 0) {
      return AppLocalizations.of(context)!.noBalance;
    }

    return balance > 0
        ? AppLocalizations.of(context)!.creditor
        : AppLocalizations.of(context)!.debtor;
  }

  String _formatAmount(double? amount) {
    if (amount == null) return "0";

    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  /// Generate account message
  String getMessage({
    required String accountNumber,
    required String accountName,
    double? currentBalance,
    double? availableBalance,
    String? currencySymbol,
    String? signatory,
  }) {
    final pos = _getAccountPosition(availableBalance);

    final formattedAvailable = _formatAmount(availableBalance);
    final formattedCurrent = _formatAmount(currentBalance);

    final symbol = currencySymbol ?? '';
    final availableBalanceLine = formattedAvailable != formattedCurrent
        ? "${AppLocalizations.of(context)!.availableBalance}: $symbol $formattedAvailable\n"
        : '';
    return "${AppLocalizations.of(context)!.dearCustomer}\n\n"
        "${AppLocalizations.of(context)!.balanceMessageShare}\n\n"
        "${AppLocalizations.of(context)!.accountName}: $accountName\n"
        "${AppLocalizations.of(context)!.accountNumber}: $accountNumber\n"
        "${AppLocalizations.of(context)!.currentBalance}: $symbol $formattedCurrent\n"
        "$availableBalanceLine"
        "${AppLocalizations.of(context)!.accountPosition}: $pos\n\n"
        "${signatory != null ? '${AppLocalizations.of(context)!.regardsTitle},\n$signatory' : ''}";
  }

  /// Check if WhatsApp installed
  Future<bool> _isWhatsAppInstalled() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final uri = Uri.parse("whatsapp://send");
        return await canLaunchUrl(uri);
      } else if (Platform.isIOS) {
        final uri = Uri.parse("whatsapp://");
        return await canLaunchUrl(uri);
      }
    } catch (e) {
      debugPrint('WhatsApp check error: $e');
    }

    return false;
  }

  /// Share via WhatsApp
  Future<void> shareViaWhatsApp({
    required String accountNumber,
    required String accountName,
    double? currentBalance,
    double? availableBalance,
    String? currencySymbol,
    String? signatory,
    String? phoneNumber,
  }) async {
    final message = getMessage(
      accountNumber: accountNumber,
      accountName: accountName,
      currentBalance: currentBalance,
      availableBalance: availableBalance,
      currencySymbol: currencySymbol,
      signatory: signatory,
    );

    // Show edit dialog first
    final editedMessage = await _showEditMessageDialog(
      message: message,
      accountNumber: accountNumber,
      accountName: accountName,
      currentBalance: currentBalance,
      availableBalance: availableBalance,
      currencySymbol: currencySymbol,
      signatory: signatory,
    );

    // User cancelled
    if (editedMessage == null) return;

    final encodedMessage = Uri.encodeComponent(editedMessage);

    try {
      if (!kIsWeb) {
        final installed = await _isWhatsAppInstalled();

        if (installed) {
          String url;

          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            String clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

            if (Platform.isAndroid) {
              url = "whatsapp://send?phone=$clean&text=$encodedMessage";
            } else {
              url = "https://wa.me/$clean?text=$encodedMessage";
            }
          } else {
            url = "whatsapp://send?text=$encodedMessage";
          }

          final uri = Uri.parse(url);

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
      }

      /// fallback web
      String webUrl;

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        String clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        webUrl = "https://wa.me/$clean?text=$encodedMessage";
      } else {
        webUrl = "https://web.whatsapp.com/send?text=$encodedMessage";
      }

      final webUri = Uri.parse(webUrl);

      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }

      /// final fallback
      await shareViaSharePlus(
        accountNumber: accountNumber,
        accountName: accountName,
        currentBalance: currentBalance,
        availableBalance: availableBalance,
        currencySymbol: currencySymbol,
        signatory: signatory,
      );
    } catch (e) {
      debugPrint('WhatsApp error: $e');

      await Clipboard.setData(ClipboardData(text: editedMessage));

      if (mounted) {
        _showErrorMessage(
            'Could not open WhatsApp. Message copied to clipboard.');
      }
    }
  }

  /// Show edit message dialog from right side
  Future<String?> _showEditMessageDialog({
    required String message,
    required String accountNumber,
    required String accountName,
    double? currentBalance,
    double? availableBalance,
    String? currencySymbol,
    String? signatory,
  }) async {
    final messageController = TextEditingController(text: message);
    final locale = AppLocalizations.of(context)!;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _EditMessageDialog(
          messageController: messageController,
          accountNumber: accountNumber,
          accountName: accountName,
          currentBalance: currentBalance,
          availableBalance: availableBalance,
          currencySymbol: currencySymbol,
          signatory: signatory,
          onCancel: () {
            Navigator.pop(dialogContext);
          },
          onShare: (editedMessage) {
            Navigator.pop(dialogContext, editedMessage);
          },
          onCopy: (editedMessage) {
            Clipboard.setData(ClipboardData(text: editedMessage));
            _showSuccessMessage(locale.copied);
          },
        );
      },
    );
  }

  /// Share text using share_plus (NEW API)
  Future<void> shareViaSharePlus({
    required String accountNumber,
    required String accountName,
    double? currentBalance,
    double? availableBalance,
    String? currencySymbol,
    String? signatory,
  }) async {
    final message = getMessage(
      accountNumber: accountNumber,
      accountName: accountName,
      currentBalance: currentBalance,
      availableBalance: availableBalance,
      currencySymbol: currencySymbol,
      signatory: signatory,
    );

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'Account Information',
        ),
      );

      if (result.status == ShareResultStatus.success) {
        debugPrint('Message shared successfully');
      }
    } catch (e) {
      debugPrint('Share error: $e');

      await Clipboard.setData(ClipboardData(text: message));

      if (mounted) {
        _showErrorMessage('Message copied to clipboard');
      }
    }
  }

  /// Share single file
  Future<void> shareFile({
    required XFile file,
    String? text,
    String? subject,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: text,
          subject: subject,
        ),
      );

      if (result.status == ShareResultStatus.success) {
        debugPrint('File shared successfully');
      }
    } catch (e) {
      debugPrint('File share error: $e');

      if (mounted) {
        _showErrorMessage('Error sharing file');
      }
    }
  }

  /// Share multiple files
  Future<void> shareMultipleFiles({
    required List<XFile> files,
    String? text,
    String? subject,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: text,
          subject: subject,
        ),
      );

      if (result.status == ShareResultStatus.success) {
        debugPrint('Files shared successfully');
      }
    } catch (e) {
      debugPrint('Multiple share error: $e');

      if (mounted) {
        _showErrorMessage('Error sharing files');
      }
    }
  }

  /// Open WhatsApp chat
  Future<void> openWhatsAppChat({
    required String phoneNumber,
    String? message,
  }) async {
    final encodedMessage =
    message != null ? Uri.encodeComponent(message) : '';

    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    try {
      String url;

      if (!kIsWeb && Platform.isAndroid) {
        url = "whatsapp://send?phone=$cleanNumber&text=$encodedMessage";
      } else {
        url = "https://wa.me/$cleanNumber?text=$encodedMessage";
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      final webUri = Uri.parse(
          "https://web.whatsapp.com/send?phone=$cleanNumber&text=$encodedMessage");

      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }

      throw Exception("WhatsApp not available");
    } catch (e) {
      debugPrint("Open chat error: $e");

      if (mounted) {
        _showErrorMessage("Could not open WhatsApp chat");
      }
    }
  }

  void _showErrorMessage(String message) {
    ToastManager.show(context: context, message: message, type: ToastType.error);
  }

  void _showSuccessMessage(String message) {
    ToastManager.show(context: context, message: message, type: ToastType.success);
  }
}

/// Edit Message Dialog - Slides from right
class _EditMessageDialog extends StatefulWidget {
  final TextEditingController messageController;
  final String accountNumber;
  final String accountName;
  final double? currentBalance;
  final double? availableBalance;
  final String? currencySymbol;
  final String? signatory;
  final VoidCallback onCancel;
  final Function(String) onShare;
  final Function(String) onCopy;

  const _EditMessageDialog({
    required this.messageController,
    required this.accountNumber,
    required this.accountName,
    required this.currentBalance,
    required this.availableBalance,
    required this.currencySymbol,
    required this.signatory,
    required this.onCancel,
    required this.onShare,
    required this.onCopy,
  });

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeWithAnimation() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Semi-transparent barrier
            GestureDetector(
              onTap: _closeWithAnimation,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),

            // Dialog panel sliding from right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: size.width * 0.3, // 45% of screen width
              child: SlideTransition(
                position: _slideAnimation,
                child: Material(
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.whatsapp,
                                  color: const Color(0xFF25D366),
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.share,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      widget.accountName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: _closeWithAnimation,
                              icon: const Icon(Icons.close),
                              tooltip: locale.cancel,
                            ),
                          ],
                        ),
                      ),

                      // Account info summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.signatory != null)
                                    _buildInfoRow(
                                      locale.signatory,
                                      widget.signatory!,
                                      colorScheme,
                                      theme,
                                    ),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(
                                    locale.accountNumber,
                                    widget.accountNumber,
                                    colorScheme,
                                    theme,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(
                                    locale.currentBalance,
                                    '${widget.currencySymbol ?? ''} ${_formatAmount(widget.currentBalance)}',
                                    colorScheme,
                                    theme,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(
                                    locale.availableBalance,
                                    '${widget.currencySymbol ?? ''} ${_formatAmount(widget.availableBalance)}',
                                    colorScheme,
                                    theme,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Message editor
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: TextField(
                            controller: widget.messageController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.typeMessageHere,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),

                      // Bottom actions
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Copy button
                            Expanded(
                              child: ZOutlineButton(
                                onPressed: () {
                                  final editedMessage = widget.messageController.text;
                                  widget.onCopy(editedMessage);
                                  setState(() {
                                    _isCopied = true;
                                  });
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (mounted) {
                                      setState(() {
                                        _isCopied = false;
                                      });
                                    }
                                  });
                                },
                                icon: _isCopied ? Icons.check : Icons.copy,
                                label: Text(
                                  _isCopied ? locale.copied : locale.copyClipboard,
                                ),

                              ),
                            ),
                            const SizedBox(width: 8),

                            // Share button
                            Expanded(
                              flex: 1,
                              child: ZOutlineButton(
                                isActive: true,
                                onPressed: () {
                                  final editedMessage = widget.messageController.text;
                                  widget.onShare(editedMessage);
                                },
                                icon: FontAwesomeIcons.whatsapp,
                                label: Text(
                                  locale.share.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                               backgroundHover: const Color(0xFF25D366),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      ColorScheme colorScheme,
      ThemeData theme,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double? amount) {
    if (amount == null) return "0";
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }
}