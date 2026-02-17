/// Responsive layout constants and utilities for LeoBook.
/// Centralizes breakpoints and scaling logic so layout-critical widgets
/// never use raw hardcoded pixel values.
library;

import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  // ── Breakpoints ──
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1024;
  static const double breakpointWide = 1400;

  // ── Horizontal Page Padding ──
  static double horizontalPadding(double width) {
    if (width > breakpointDesktop) return 40;
    if (width > breakpointTablet) return 24;
    return 16;
  }

  // ── Horizontal-Scroll Card Width (e.g. odds cards, news cards) ──
  /// Returns a width that's ~28% of available space, clamped to stay readable.
  static double cardWidth(double availableWidth,
      {double minWidth = 240, double maxWidth = 360}) {
    final w = availableWidth * 0.28;
    return w.clamp(minWidth, maxWidth);
  }

  // ── Horizontal-Scroll List Height ──
  /// Proportional list height, clamped for readability.
  static double listHeight(double availableWidth,
      {double min = 180, double max = 240}) {
    final h = availableWidth * 0.15;
    return h.clamp(min, max);
  }

  // ── Bottom Nav Margin (mobile-only) ──
  static EdgeInsets bottomNavMargin(double width) {
    final horizontal = (width * 0.08).clamp(24.0, 58.0);
    final bottom = (width * 0.05).clamp(20.0, 40.0);
    return EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottom);
  }

  // ── Helpers ──
  static bool isMobile(double width) => width < breakpointTablet;
  static bool isTablet(double width) =>
      width >= breakpointTablet && width < breakpointDesktop;
  static bool isDesktop(double width) => width >= breakpointDesktop;
}
