import 'package:flutter/material.dart';

class Responsive {
  static bool isPhone(BuildContext c) => MediaQuery.of(c).size.shortestSide < 600;
  static bool isTablet(BuildContext c) =>
      MediaQuery.of(c).size.shortestSide >= 600 && MediaQuery.of(c).size.shortestSide < 900;
  static bool isDesktop(BuildContext c) => MediaQuery.of(c).size.shortestSide >= 900;

  /// İçerik kutusuna makul bir max genişlik ver: telefon < tablet < desktop
  static double maxContentWidth(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    if (isDesktop(c)) return 720;
    if (isTablet(c)) return 560;
    return w * 0.92; // phone
  }

  /// Etraf boşluk
  static EdgeInsets pagePadding(BuildContext c) {
    if (isDesktop(c)) return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    if (isTablet(c)) return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}
