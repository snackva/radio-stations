import 'dart:ui';

import 'package:flutter/material.dart';

class AppTheme {
  // Screen
  static double get devicePixelRatio => PlatformDispatcher.instance.views.first.devicePixelRatio;
  static double get screenHeight => PlatformDispatcher.instance.views.first.physicalSize.height / devicePixelRatio;
  static double get screenWidth => PlatformDispatcher.instance.views.first.physicalSize.width / devicePixelRatio;
  static double get statusBarHeight => PlatformDispatcher.instance.views.first.padding.top / devicePixelRatio;
  static double get bottomPadding => PlatformDispatcher.instance.views.first.padding.bottom / devicePixelRatio;

  // Colors
  static Color get backgroundColor => Colors.white;
  static Color get primaryColor => const Color(0xFFFF3434);
  static Color get surfaceColor => Colors.black;

  // Text
  static TextStyle get titleLargeStyle => TextStyle(
        fontSize: 40,
        fontVariations: [FontVariation('wght', FontWeight.w500.value.toDouble())],
      );
  static TextStyle get titleMediumStyle => TextStyle(
        fontSize: 32,
        fontVariations: [FontVariation('wght', FontWeight.w500.value.toDouble())],
      );
  static TextStyle get titleSmallStyle => TextStyle(
        fontSize: 24,
        fontVariations: [FontVariation('wght', FontWeight.w500.value.toDouble())],
      );
  static TextStyle get subtitleStyle => TextStyle(
        fontSize: 16,
        fontVariations: [FontVariation('wght', FontWeight.w500.value.toDouble())],
      );

  // Animations
  static Duration get standardAnimationDuration => const Duration(milliseconds: 250);
  static Duration get slowAnimationDuration => const Duration(milliseconds: 450);
  static Curve get standardAnimationCurve => Curves.fastOutSlowIn;

  static ThemeData get data => ThemeData(
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        fontFamily: 'Outfit',
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            height: 1.2,
            color: surfaceColor,
          ),
        ),
      );
}

class AppScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }
}
