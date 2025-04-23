import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/theme_config.dart';

/// Custom painter for drawing the oval face guide with color progress
class OvalColorProgressPainter extends CustomPainter {
  /// Whether a face is detected
  final bool isFaceDetected;

  /// Liveness config
  final LivenessConfig config;

  /// Liveness theme
  final LivenessTheme theme;

  /// Animation value for pulsing effect
  final double? animationValue;

  /// Current progress (0.0-1.0)
  final double progress;

  /// Start color for the progress gradient
  final Color startColor;

  /// End color for the progress gradient
  final Color endColor;

  /// Constructor
  OvalColorProgressPainter({
    this.isFaceDetected = false,
    this.config = const LivenessConfig(),
    this.theme = const LivenessTheme(),
    this.animationValue,
    this.progress = 0.0,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.height * 0.05);

    // Larger oval
    final ovalHeight = size.height * config.ovalHeightRatio;
    final ovalWidth = ovalHeight * config.ovalWidthRatio;

    // Apply animation if enabled and available
    final double strokeWidth =
        theme.useOvalPulseAnimation && animationValue != null
            ? config.strokeWidth * (1.0 + animationValue! * 0.5)
            : config.strokeWidth;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Draw overlay
    final paint = Paint()
      ..color = theme.overlayColor.withOpacity(theme.overlayOpacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Determine the oval border color based on progress
    Color ovalColor;

    if (isFaceDetected) {
      // Interpolate between startColor and endColor based on progress
      ovalColor = Color.lerp(startColor, endColor, progress) ?? startColor;
    } else {
      // Use the default oval guide color if face isn't detected
      ovalColor = theme.ovalGuideColor;
    }

    // Draw oval border
    final borderPaint = Paint()
      ..color = ovalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawOval(ovalRect, borderPaint);

    // Optional: Draw a small progress arc on the oval itself
    if (progress > 0 && isFaceDetected) {
      const double arcPadding = 5.0; // Small gap from the main oval

      // Create a slightly larger oval for the progress arc
      final progressOvalRect = Rect.fromCenter(
        center: center,
        width: ovalWidth + arcPadding * 2,
        height: ovalHeight + arcPadding * 2,
      );

      final progressPaint = Paint()
        ..color = endColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth / 2
        ..strokeCap = StrokeCap.round;

      // Draw an arc representing progress
      canvas.drawArc(
        progressOvalRect,
        -math.pi / 2, // Start from top
        progress * math.pi * 2, // Sweep angle based on progress
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(OvalColorProgressPainter oldDelegate) =>
      oldDelegate.isFaceDetected != isFaceDetected ||
      oldDelegate.config != config ||
      oldDelegate.theme != theme ||
      oldDelegate.animationValue != animationValue ||
      oldDelegate.progress != progress ||
      oldDelegate.startColor != startColor ||
      oldDelegate.endColor != endColor;
}

/// Animated version of the oval overlay with color progress indicator
class OvalColorProgressOverlay extends StatefulWidget {
  /// Whether a face is detected
  final bool isFaceDetected;

  /// Liveness config
  final LivenessConfig config;

  /// Liveness theme
  final LivenessTheme theme;

  /// Current progress (0.0-1.0)
  final double progress;

  /// Start color for the progress gradient (typically a neutral color)
  final Color? startColor;

  /// End color for the progress gradient (typically success color when complete)
  final Color? endColor;

  /// Constructor
  const OvalColorProgressOverlay({
    super.key,
    this.isFaceDetected = false,
    this.config = const LivenessConfig(),
    this.theme = const LivenessTheme(),
    this.progress = 0.0,
    this.startColor,
    this.endColor,
  });

  @override
  State<OvalColorProgressOverlay> createState() =>
      _OvalColorProgressOverlayState();
}

class _OvalColorProgressOverlayState extends State<OvalColorProgressOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Only create animation if pulse effect is enabled
    if (widget.theme.useOvalPulseAnimation) {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);

      _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (widget.theme.useOvalPulseAnimation) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default colors if not provided
    final startColor = widget.startColor ?? widget.theme.ovalGuideColor;
    final endColor = widget.endColor ?? widget.theme.successColor;

    if (widget.theme.useOvalPulseAnimation) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: OvalColorProgressPainter(
              isFaceDetected: widget.isFaceDetected,
              config: widget.config,
              theme: widget.theme,
              animationValue: _animation.value,
              progress: widget.progress,
              startColor: startColor,
              endColor: endColor,
            ),
          );
        },
      );
    } else {
      return CustomPaint(
        size: Size.infinite,
        painter: OvalColorProgressPainter(
          isFaceDetected: widget.isFaceDetected,
          config: widget.config,
          theme: widget.theme,
          progress: widget.progress,
          startColor: startColor,
          endColor: endColor,
        ),
      );
    }
  }
}
