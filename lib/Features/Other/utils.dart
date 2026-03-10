import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';

class Utils{

  static String getRole({required int role, required BuildContext context}) {
    switch (role) {
      case 0:return AppLocalizations.of(context)!.adminstrator;
      case 1:return AppLocalizations.of(context)!.admin;
      case 2:return AppLocalizations.of(context)!.manager;
      case 3:return AppLocalizations.of(context)!.viewer;
      default: return "";
    }
  }



  static Future<void> launchWhatsApp({required String phoneNumber, String? message}) async {
    final encodedMessage = Uri.encodeComponent(message ?? '');
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$encodedMessage");
    final success = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!success) {
      throw 'Could not launch WhatsApp';
    }
  }

  static Future<Uint8List?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      return result.files.single.bytes;
    } else if (result != null && result.files.single.path != null) {
      return await File(
        result.files.single.path!,
      ).readAsBytes();
    }
    return null;
  }



  static void showOverlayMessage(
      BuildContext context, {
        required String message,
        String? title,
        required bool isError,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 10,
        left: width * 0.1,
        right: width * 0.1,
        child: MediaQuery(
          data: mediaQuery,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: -30, end: 0),
              builder: (context, value, child) =>
                  Transform.translate(offset: Offset(0, value), child: child),
              child: _OverlayContent(
                title: title,
                message: message,
                color: color,
                icon: icon,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration, entry.remove);
  }


  //Goto
  static Future<dynamic> goto(BuildContext context, Widget page) {
    return Navigator.of(context).push(_animatedRouting(page));
  }

  //Push and remove previous routes
  static void gotoReplacement(BuildContext context, Widget page) {
    Navigator.of(context).popUntil((route) => false);
    Navigator.push(context, _animatedRouting(page));
  }

  //Part of GOTO Widget
  static Route _animatedRouting(Widget route) {
    return PageRouteBuilder(
      allowSnapshotting: true,
      pageBuilder: (context, animation, secondaryAnimation) => route,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from the right
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  static String? validatePassword({required String value, context}) {
    final locale = AppLocalizations.of(context)!;
    if (value.length < 8) {
      return locale.password8Char;
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return locale.passwordUpperCase;
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return locale.passwordLowerCase;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return locale.passwordWithDigit;
    }
    if (!RegExp(r'[!@#$%^&*()_+{}\[\]:;<>,.?/~`]').hasMatch(value)) {
      return locale.passwordWithSpecialChar;
    }

    return null; // Password is valid
  }

  static String? validateUsername({required String value, context}) {
    final locale = AppLocalizations.of(context)!;

    // Minimum length
    if (value.length < 4) {
      return locale.usernameMinLength; // "Username must be at least 4 characters"
    }

    // Cannot start with a digit
    if (RegExp(r'^[0-9]').hasMatch(value)) {
      return locale.usernameNoStartDigit; // "Username cannot start with a number"
    }

    // Allowed characters: letters, digits, underscore, dot
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
      return locale.usernameInvalidChars; // "Username can only contain letters, numbers, . or _"
    }

    // No spaces
    if (value.contains(' ')) {
      return locale.usernameNoSpaces; // "Username cannot contain spaces"
    }

    return null; // Username is valid
  }

  static Widget zBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).maybePop();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: .6),
              blurRadius: 0,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_rounded,
          size: 13,
        ),
      ),
    );
  }

  static String? validateEmail({required String email, context}) {
    final locale = AppLocalizations.of(context)!;
    if (email.isNotEmpty) {
      // Regular expression for validating an email
      final RegExp emailRegex = RegExp(
        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
      );
      if (!emailRegex.hasMatch(email)) {
        return locale.emailValidationMessage;
      }
    } else {
      return null;
    }

    return null;
  }

  static String glCategories({required int category, required AppLocalizations locale}) {
    if (category == 1) {
      return locale.asset;
    } else if (category == 2) {
      return locale.liability;
    } else if (category == 3) {
      return locale.income;
    } else if (category == 4) {
      return locale.expense;
    } else {
      return "not found";
    }
  }


  static Future<void> copyToClipboard(String text) async {
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }
  static String genderType({required String gender, AppLocalizations? locale}) {
    if (gender == "Male") {
      return locale!.male;
    } else if (gender == "Female") {
      return locale!.female;
    } else {
      return "";
    }
  }
  static Color currencyColors(String ccy) {
    final lowerCurrency = ccy.toLowerCase();
    final Map<String, Color> colorMap = {
      'usd': Color(0xFF1E88E5), // Bright Blue
      'afn': Color(0xFF26C6DA), // Cyan
      'eur': Color(0xFFAB47BC), // Purple
      'gbp': Color(0xFF66BB6A), // Green
      'inr': Color(0xFFEF5350), // Indian Red/Orange
      'cad': Color(0xFF42A5F5), // Canadian Blue
      'pkr': Color(0xFF9CCC65), // Light Green
      'aud': Color(0xFFFFCA28), // Gold
      'jpy': Color(0xFFFF7043), // Deep Orange
      'cny': Color(0xFFE53935), // Chinese Red
      'rub': Color(0xFF8E24AA), // Russian Purple
      'aed': Color(0xFF00897B), // Emirates Green
      'sar': Color(0xFFFF8F00), // Saudi Gold
      'try': Color(0xFFFFA726), // Turkish Orange
    };

    return colorMap[lowerCurrency]?.withValues(alpha: .9) ??
        Color(0xFF78909C).withValues(alpha: .8); // Default Blue Gray
  }

  static String getTxnName({required String txn, required BuildContext context}) {
    switch (txn) {
      case "Authorized":return AppLocalizations.of(context)!.authorizedTransactions;
      case "Pending":return AppLocalizations.of(context)!.pendingTransactions;
      case "Reversed":return AppLocalizations.of(context)!.reversed;
      default: return "";
    }
  }

  static String getInvoiceType({required String txn, required BuildContext context}) {
    switch (txn) {
      case "Purchase":return AppLocalizations.of(context)!.purchaseTitle;
      case "Sale":return AppLocalizations.of(context)!.saleTitle;
      case "Return Sale":return AppLocalizations.of(context)!.returnGoods;
      default: return "";
    }
  }

  static String getTxnCode({required String txn, required BuildContext context}) {
    switch (txn) {
      case "CHDP":return AppLocalizations.of(context)!.deposit;
      case "PRJT":return AppLocalizations.of(context)!.projectEntry;
      case "PLCL":return AppLocalizations.of(context)!.pandl;
      case "SLRY":return AppLocalizations.of(context)!.postSalary;
      case "CHWL":return AppLocalizations.of(context)!.withdraw;
      case "XPNS":return AppLocalizations.of(context)!.expense;
      case "INCM":return AppLocalizations.of(context)!.income;
      case "GLCR":return AppLocalizations.of(context)!.glCreditTitle;
      case "GLDR":return AppLocalizations.of(context)!.glDebitTitle;
      case "ATAT":return AppLocalizations.of(context)!.accountTransfer;
      case "CRFX":return AppLocalizations.of(context)!.fxTransaction;
      case "TRPT":return AppLocalizations.of(context)!.transportEntry;
      case "GLAT":return AppLocalizations.of(context)!.assetEntry;
      case "SALE":return AppLocalizations.of(context)!.saleTitle;
      case "PRCH":return AppLocalizations.of(context)!.purchaseTitle;
      default: return txn;
    }
  }

}


class _OverlayContent extends StatelessWidget {
  final String? title;
  final String message;
  final Color color;
  final IconData icon;

  const _OverlayContent({
    this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3)),
        color: color,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 1, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.surface, size: 35),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
