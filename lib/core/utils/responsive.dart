import 'package:flutter/material.dart';

/// Centralised breakpoints and layout helpers for phone vs iPad.
class Responsive {
  Responsive._();

  /// iPad: width ≥ 600 dp
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  /// Large iPad / landscape: width ≥ 900 dp
  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  /// Max content width — centres content on wide screens.
  static double maxContentWidth(BuildContext context) =>
      isLargeTablet(context) ? 900 : double.infinity;

  /// Horizontal padding: more breathing room on iPad.
  static double horizontalPadding(BuildContext context) =>
      isTablet(context) ? 40 : 24;

  /// Number of columns for a cuisine/dish square grid.
  static int cuisineGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 4;
    if (w >= 600) return 3;
    return 2;
  }

  /// Number of columns for a dish card list-grid (meals screen).
  static int dishGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 3;
    if (w >= 600) return 2;
    return 1;
  }

  /// Whether to use a two-pane master/detail layout.
  static bool useTwoPane(BuildContext context) => isLargeTablet(context);
}
