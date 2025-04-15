import 'package:flutter/material.dart';

/// Theme configuration for the Face Liveness Detection package
class LivenessTheme {
  /// App bar background color
  final Color appBarBackgroundColor;

  /// App bar text color
  final Color appBarTextColor;

  /// Background color of the screen
  final Color backgroundColor;

  /// Primary color for accents and highlights
  final Color primaryColor;

  /// Color for success indicators
  final Color successColor;

  /// Color for error indicators
  final Color errorColor;

  /// Color for warning indicators
  final Color warningColor;

  /// Color for the oval face guide
  final Color ovalGuideColor;

  /// Color for the overlay around the oval guide
  final Color overlayColor;

  /// Opacity of the overlay (0.0-1.0)
  final double overlayOpacity;

  /// Text style for instructions
  final TextStyle instructionTextStyle;

  /// Text style for status messages
  final TextStyle statusTextStyle;

  /// Text style for the face center guidance
  final TextStyle guidanceTextStyle;

  /// Text style for the success screen title
  final TextStyle successTitleStyle;

  /// Text style for the session ID on success screen
  final TextStyle sessionIdStyle;

  /// Button style for the reset button
  final ButtonStyle? resetButtonStyle;

  /// Custom progress indicator color
  final Color progressIndicatorColor;

  /// Custom progress indicator background color
  final Color progressIndicatorBackgroundColor;

  /// Custom progress indicator height
  final double progressIndicatorHeight;

  /// Whether to use pulse animation on the oval guide
  final bool useOvalPulseAnimation;

  const LivenessTheme({
    this.appBarBackgroundColor = Colors.black38,
    this.appBarTextColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.primaryColor = const Color(0xFF8A8DDF),
    this.successColor = Colors.green,
    this.errorColor = Colors.red,
    this.warningColor = Colors.orange,
    this.ovalGuideColor = const Color(0xFF8A8DDF),
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.8,
    this.instructionTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    this.statusTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    this.guidanceTextStyle = const TextStyle(
      color: Color(0xFF2E38B7),
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    this.successTitleStyle = const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    this.sessionIdStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 14,
    ),
    this.resetButtonStyle,
    this.progressIndicatorColor = Colors.blue,
    this.progressIndicatorBackgroundColor = Colors.grey,
    this.progressIndicatorHeight = 10,
    this.useOvalPulseAnimation = false,
  });

  /// Create a copy of this theme with some values replaced
  LivenessTheme copyWith({
    Color? appBarBackgroundColor,
    Color? appBarTextColor,
    Color? backgroundColor,
    Color? primaryColor,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? ovalGuideColor,
    Color? overlayColor,
    double? overlayOpacity,
    TextStyle? instructionTextStyle,
    TextStyle? statusTextStyle,
    TextStyle? guidanceTextStyle,
    TextStyle? successTitleStyle,
    TextStyle? sessionIdStyle,
    ButtonStyle? resetButtonStyle,
    Color? progressIndicatorColor,
    Color? progressIndicatorBackgroundColor,
    double? progressIndicatorHeight,
    bool? useOvalPulseAnimation,
  }) {
    return LivenessTheme(
      appBarBackgroundColor: appBarBackgroundColor ?? this.appBarBackgroundColor,
      appBarTextColor: appBarTextColor ?? this.appBarTextColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      primaryColor: primaryColor ?? this.primaryColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
      ovalGuideColor: ovalGuideColor ?? this.ovalGuideColor,
      overlayColor: overlayColor ?? this.overlayColor,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      instructionTextStyle: instructionTextStyle ?? this.instructionTextStyle,
      statusTextStyle: statusTextStyle ?? this.statusTextStyle,
      guidanceTextStyle: guidanceTextStyle ?? this.guidanceTextStyle,
      successTitleStyle: successTitleStyle ?? this.successTitleStyle,
      sessionIdStyle: sessionIdStyle ?? this.sessionIdStyle,
      resetButtonStyle: resetButtonStyle ?? this.resetButtonStyle,
      progressIndicatorColor: progressIndicatorColor ?? this.progressIndicatorColor,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor ?? this.progressIndicatorBackgroundColor,
      progressIndicatorHeight: progressIndicatorHeight ?? this.progressIndicatorHeight,
      useOvalPulseAnimation: useOvalPulseAnimation ?? this.useOvalPulseAnimation,
    );
  }

  /// Create a theme based on Material color scheme
  factory LivenessTheme.fromMaterialColor(
    Color primaryColor, {
    Brightness brightness = Brightness.dark,
  }) {
    final bool isDark = brightness == Brightness.dark;
    
    // Generate a color scheme from the primary color
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    );
    
    return LivenessTheme(
      appBarBackgroundColor: colorScheme.surface.withValues(alpha: 0.8),
      appBarTextColor: colorScheme.onSurface,
      backgroundColor: colorScheme.surface,
      primaryColor: colorScheme.primary,
      successColor: colorScheme.secondary,
      errorColor: colorScheme.error,
      warningColor: colorScheme.tertiary,
      ovalGuideColor: colorScheme.primary,
      overlayColor: isDark ? Colors.black : Colors.white,
      overlayOpacity: 0.7,
      instructionTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      statusTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      guidanceTextStyle: TextStyle(
        color: colorScheme.primary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      progressIndicatorColor: colorScheme.primary,
      progressIndicatorBackgroundColor: colorScheme.surfaceContainerHighest,
    );
  }
}