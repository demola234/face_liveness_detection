import 'package:flutter/material.dart';

import '../config/theme_config.dart';

/// Widget displayed when liveness verification is complete
class SuccessOverlay extends StatefulWidget {
  /// Session ID
  final String sessionId;

  /// Callback for reset button
  final VoidCallback onReset;

  /// Theme for styling
  final LivenessTheme theme;

  /// Whether verification was successful
  final bool isSuccessful;

  /// Custom success message
  final String? successMessage;

  /// Custom failure message
  final String? failureMessage;

  /// Custom button text
  final String? buttonText;

  /// Whether to show session ID
  final bool showSessionId;

  /// Number of characters of session ID to show (0 for all)
  final int sessionIdCharacters;

  /// Custom widget to display inside the overlay
  final Widget? customContent;

  /// Whether to show the capture image button
  final bool showCaptureImageButton;

  /// Callback when image capture is requested
  final Function(String sessionId)? onCaptureImage;

  /// Button text for image capture
  final String? captureButtonText;

  /// Constructor
  const SuccessOverlay({
    super.key,
    required this.sessionId,
    required this.onReset,
    this.theme = const LivenessTheme(),
    this.isSuccessful = true,
    this.successMessage,
    this.failureMessage,
    this.buttonText,
    this.showSessionId = true,
    this.sessionIdCharacters = 8,
    this.customContent,
    this.showCaptureImageButton = false,
    this.onCaptureImage,
    this.captureButtonText,
  });

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 40.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If custom content is provided, use it with animation
    if (widget.customContent != null) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeInAnimation.value,
            child: widget.customContent,
          );
        },
      );
    }

    final String message = widget.isSuccessful
        ? widget.successMessage ?? 'Verification Complete!'
        : widget.failureMessage ?? 'Verification Failed';

    final IconData icon =
        widget.isSuccessful ? Icons.check_circle : Icons.error;
    final Color iconColor = widget.isSuccessful
        ? widget.theme.successColor
        : widget.theme.errorColor;
    final String buttonText = widget.buttonText ?? 'Start Again';

    String displaySessionId = widget.sessionId;
    if (widget.sessionIdCharacters > 0 &&
        widget.sessionIdCharacters < widget.sessionId.length) {
      displaySessionId =
          '${widget.sessionId.substring(0, widget.sessionIdCharacters)}...';
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: widget.theme.successTitleStyle,
                    ),
                    if (widget.showSessionId) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Session ID: $displaySessionId',
                        style: widget.theme.sessionIdStyle,
                      ),
                    ],
                    const SizedBox(height: 30),
                    if (widget.showCaptureImageButton &&
                        widget.isSuccessful) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          if (widget.onCaptureImage != null) {
                            widget.onCaptureImage!(widget.sessionId);
                          }
                        },
                        child:
                            Text(widget.captureButtonText ?? 'Capture Image'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      style: widget.theme.resetButtonStyle ??
                          ElevatedButton.styleFrom(
                            backgroundColor: widget.isSuccessful
                                ? widget.theme.successColor
                                : widget.theme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                      onPressed: widget.onReset,
                      child: Text(buttonText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget for displaying challenge completion animation
class ChallengeCompletedAnimation extends StatefulWidget {
  /// Type of challenge completed
  final String challengeType;

  /// Theme for styling
  final LivenessTheme theme;

  /// Duration of the animation
  final Duration duration;

  /// Size of the animation
  final double size;

  /// Custom message to display
  final String? message;

  /// Constructor
  const ChallengeCompletedAnimation({
    super.key,
    required this.challengeType,
    this.theme = const LivenessTheme(),
    this.duration = const Duration(milliseconds: 1500),
    this.size = 80.0,
    this.message,
  });

  @override
  State<ChallengeCompletedAnimation> createState() =>
      _ChallengeCompletedAnimationState();
}

class _ChallengeCompletedAnimationState
    extends State<ChallengeCompletedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20.0,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20.0,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String message = widget.message ?? 'Great!';
    final IconData icon;

    // Choose icon based on challenge type
    switch (widget.challengeType.toLowerCase()) {
      case 'blink':
      case 'challengetype.blink':
        icon = Icons.visibility;
        break;
      case 'turnleft':
      case 'challengetype.turnleft':
        icon = Icons.rotate_left;
        break;
      case 'turnright':
      case 'challengetype.turnright':
        icon = Icons.rotate_right;
        break;
      case 'smile':
      case 'challengetype.smile':
        icon = Icons.sentiment_very_satisfied;
        break;
      case 'nod':
      case 'challengetype.nod':
        icon = Icons.height;
        break;
      default:
        icon = Icons.check_circle;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: widget.size * 0.5,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
