import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
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

    return "${AppLocalizations.of(context)!.dearCustomer},\n\n"
        "${AppLocalizations.of(context)!.balanceMessageShare}\n\n"
        "${AppLocalizations.of(context)!.accountName}: $accountName\n"
        "${AppLocalizations.of(context)!.accountNumber}: $accountNumber\n"
        "${AppLocalizations.of(context)!.currentBalance}: $symbol $formattedCurrent\n"
        "${AppLocalizations.of(context)!.availableBalance}: $symbol $formattedAvailable\n"
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

    final encodedMessage = Uri.encodeComponent(message);

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

      await Clipboard.setData(ClipboardData(text: message));

      if (mounted) {
        _showErrorMessage(
            'Could not open WhatsApp. Message copied to clipboard.');
      }
    }
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
}