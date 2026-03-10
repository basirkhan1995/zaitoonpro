import 'package:flutter/material.dart';

class ZNavigator {
  /// 1️⃣ Global navigator key (static)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// GOTO
  static Future<T?> goto<T>(Widget page, {BuildContext? context}) {
    final navigator = context != null
        ? Navigator.of(context)
        : navigatorKey.currentState!;

    return navigator.push<T>(_animatedRouting<T>(page));
  }

  /// GOTO + CLEAR STACK
  static Future<T?> gotoReplacement<T>(Widget page, {BuildContext? context}) {
    final navigator = context != null
        ? Navigator.of(context)
        : navigatorKey.currentState!;

    return navigator.pushAndRemoveUntil<T>(
      _animatedRouting<T>(page),
          (route) => false,
    );
  }

  /// ROUTE ANIMATION
  static Route<T> _animatedRouting<T>(Widget page) {
    return PageRouteBuilder<T>(
      allowSnapshotting: true,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.ease));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}