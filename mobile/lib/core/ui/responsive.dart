import 'package:flutter/widgets.dart';

/// Lightweight responsive helpers (no external deps).
abstract final class Responsive {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// App-level breakpoints tuned for mobile → tablet → desktop.
  static bool isPhone(BuildContext context) => width(context) < 600;
  static bool isTablet(BuildContext context) => width(context) >= 600 && width(context) < 1024;
  static bool isDesktop(BuildContext context) => width(context) >= 1024;

  /// Grid columns for marketplace-like layouts (e.g., Shopee).
  static int marketplaceGridColumns(BuildContext context) {
    final w = width(context);
    if (w < 380) return 2;
    if (w < 600) return 2;
    if (w < 900) return 3;
    if (w < 1200) return 4;
    return 5;
  }

  /// Max readable content width on larger screens.
  static double contentMaxWidth(BuildContext context) {
    final w = width(context);
    if (w < 600) return w;
    if (w < 1024) return 900;
    return 1040;
  }

  /// Horizontal page padding that scales up on larger screens.
  static double pageHorizontalPadding(BuildContext context) {
    final w = width(context);
    if (w < 600) return 16;
    if (w < 1024) return 20;
    return 24;
  }
}

