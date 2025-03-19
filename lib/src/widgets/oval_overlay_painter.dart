import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/theme_config.dart';

/// Custom painter for drawing the oval face guide
class OvalOverlayPainter extends CustomPainter {
  /// Whether a face is detected
  final bool isFaceDetected;
  
  /// Liveness config
  final LivenessConfig config;
  
  /// Liveness theme
  final LivenessTheme theme;
  
  /// Animation value for pulsing effect
  final double? animationValue;

  /// Constructor
  OvalOverlayPainter({
    this.isFaceDetected = false,
    this.config = const LivenessConfig(),
    this.theme = const LivenessTheme(),
    this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.height * 0.05);

    final ovalHeight = size.height * config.ovalHeightRatio;
    final ovalWidth = ovalHeight * config.ovalWidthRatio;

    // Apply animation if enabled and available
    final double strokeWidth = theme.useOvalPulseAnimation && animationValue != null
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

    // Optional guide markers
    if (config.guideMarkerRatio > 0 && config.guideMarkerInnerRatio > 0) {
      canvas.drawLine(
        Offset(center.dx, center.dy - ovalHeight * config.guideMarkerRatio),
        Offset(center.dx, center.dy - ovalHeight * config.guideMarkerInnerRatio),
        borderPaint,
      );

      canvas.drawLine(
        Offset(center.dx, center.dy + ovalHeight * config.guideMarkerRatio),
        Offset(center.dx, center.dy + ovalHeight * config.guideMarkerInnerRatio),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(OvalOverlayPainter oldDelegate) =>
      oldDelegate.isFaceDetected != isFaceDetected ||
      oldDelegate.config != config ||
      oldDelegate.theme != theme ||
      oldDelegate.animationValue != animationValue;
}

/// Animated version of the oval overlay
class AnimatedOvalOverlay extends StatefulWidget {
  /// Whether a face is detected
  final bool isFaceDetected;
  
  /// Liveness config
  final LivenessConfig config;
  
  /// Liveness theme
  final LivenessTheme theme;

  /// Constructor
  const AnimatedOvalOverlay({
    Key? key,
    this.isFaceDetected = false,
    this.config = const LivenessConfig(),
    this.theme = const LivenessTheme(),
  }) : super(key: key);

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
        ),
      );
    }
  }
}