import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/theme_config.dart';

/// Custom painter for drawing the oval face guide with adjacent progress circle
class OvalOverlayPainter extends CustomPainter {
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

  /// Progress track color (background)
  final Color progressTrackColor;

  /// Progress indicator color (foreground)
  final Color progressIndicatorColor;

  /// Width of the progress indicator
  final double progressWidth;

  /// Size of the progress circle
  final double progressCircleSize;

  /// Position of the progress circle (0 = top, 1 = right, 2 = bottom, 3 = left)
  final int progressPosition;

  /// Constructor
  OvalOverlayPainter({
    this.isFaceDetected = false,
    this.config = const LivenessConfig(),
    this.theme = const LivenessTheme(),
    this.animationValue,
    this.progress = 0.0,
    this.progressTrackColor = Colors.grey,
    this.progressIndicatorColor = Colors.blue,
    this.progressWidth = 6.0,
    this.progressCircleSize = 50.0,
    this.progressPosition = 1, // Default to right side
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

    // Draw the main overlay
    final paint = Paint()
      ..color = theme.overlayColor.withValues(alpha: theme.overlayOpacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw oval border
    final borderPaint = Paint()
      ..color = theme.ovalGuideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Use a different color if face is detected and centered
    if (isFaceDetected) {
      borderPaint.color = theme.successColor;
    }

    canvas.drawOval(ovalRect, borderPaint);

    // Calculate progress circle position adjacent to the oval
    Offset progressCenter;
    switch (progressPosition) {
      case 0: // Top
        progressCenter = Offset(center.dx,
            center.dy - ovalHeight / 2 - progressCircleSize / 2 - 10);
        break;
      case 1: // Right
        progressCenter = Offset(
            center.dx + ovalWidth / 2 + progressCircleSize / 2 + 10, center.dy);
        break;
      case 2: // Bottom
        progressCenter = Offset(center.dx,
            center.dy + ovalHeight / 2 + progressCircleSize / 2 + 10);
        break;
      case 3: // Left
        progressCenter = Offset(
            center.dx - ovalWidth / 2 - progressCircleSize / 2 - 10, center.dy);
        break;
      default:
        progressCenter = Offset(
            center.dx + ovalWidth / 2 + progressCircleSize / 2 + 10, center.dy);
    }

    // Draw progress track (background)
    final trackPaint = Paint()
      ..color = progressTrackColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(progressCenter, progressCircleSize / 2, trackPaint);

    // Draw progress indicator (foreground)
    if (progress > 0.0) {
      final progressPaint = Paint()
        ..color = progressIndicatorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = progressWidth
        ..strokeCap = StrokeCap.round;

      // Draw an arc for the progress
      final rect = Rect.fromCircle(
          center: progressCenter, radius: progressCircleSize / 2);
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start from top
        progress * math.pi * 2, // Sweep angle based on progress
        false,
        progressPaint,
      );

      // Optionally draw progress percentage text
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: progressCircleSize * 0.3,
        fontWeight: FontWeight.bold,
      );
      final textSpan = TextSpan(
        text: '${(progress * 100).toInt()}%',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          progressCenter.dx - textPainter.width / 2,
          progressCenter.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(OvalOverlayPainter oldDelegate) =>
      oldDelegate.isFaceDetected != isFaceDetected ||
      oldDelegate.config != config ||
      oldDelegate.theme != theme ||
      oldDelegate.animationValue != animationValue ||
      oldDelegate.progress != progress ||
      oldDelegate.progressTrackColor != progressTrackColor ||
      oldDelegate.progressIndicatorColor != progressIndicatorColor ||
      oldDelegate.progressWidth != progressWidth ||
      oldDelegate.progressCircleSize != progressCircleSize ||
      oldDelegate.progressPosition != progressPosition;
}

/// Animated version of the oval overlay with progress indicator
class AnimatedOvalOverlay extends StatefulWidget {
  /// Whether a face is detected
  final bool isFaceDetected;

  /// Liveness config
  final LivenessConfig config;

  /// Liveness theme
  final LivenessTheme theme;

  /// Current progress (0.0-1.0)
  final double progress;

  /// Progress track color (background)
  final Color? progressTrackColor;

  /// Progress indicator color (foreground)
  final Color? progressIndicatorColor;

  /// Width of the progress indicator
  final double progressWidth;

  /// Constructor
  const AnimatedOvalOverlay({
    super.key,
    this.isFaceDetected = false,
    this.config = const LivenessConfig(),
    this.theme = const LivenessTheme(),
    this.progress = 0.0,
    this.progressTrackColor,
    this.progressIndicatorColor,
    this.progressWidth = 6.0,
  });

  @override
  State<AnimatedOvalOverlay> createState() => _AnimatedOvalOverlayState();
}

class _AnimatedOvalOverlayState extends State<AnimatedOvalOverlay>
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
    // Get colors from theme if not provided
    final trackColor = widget.progressTrackColor ?? Colors.grey.shade700;
    final indicatorColor =
        widget.progressIndicatorColor ?? widget.theme.primaryColor;

    if (widget.theme.useOvalPulseAnimation) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: OvalOverlayPainter(
              isFaceDetected: widget.isFaceDetected,
              config: widget.config,
              theme: widget.theme,
              animationValue: _animation.value,
              progress: widget.progress,
              progressTrackColor: trackColor,
              progressIndicatorColor: indicatorColor,
              progressWidth: widget.progressWidth,
            ),
          );
        },
      );
    } else {
      return CustomPaint(
        size: Size.infinite,
        painter: OvalOverlayPainter(
          isFaceDetected: widget.isFaceDetected,
          config: widget.config,
          theme: widget.theme,
          progress: widget.progress,
          progressTrackColor: trackColor,
          progressIndicatorColor: indicatorColor,
          progressWidth: widget.progressWidth,
        ),
      );
    }
  }
}
