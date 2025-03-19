import 'package:flutter/material.dart';

import '../config/theme_config.dart';

/// Widget for displaying liveness detection instructions
class InstructionOverlay extends StatelessWidget {
  /// Instruction text to display
  final String instruction;
  
  /// Theme for styling
  final LivenessTheme theme;
  
  /// Optional icon to display
  final IconData? icon;
  
  /// Whether to animate the instruction
  final bool animate;
  
  /// Optional padding around the instruction
  final EdgeInsetsGeometry padding;
  
  /// Optional shape of the instruction container
  final ShapeBorder? shape;

  /// Constructor
  const InstructionOverlay({
    Key? key,
    required this.instruction,
    this.theme = const LivenessTheme(),
    this.icon,
    this.animate = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: theme.instructionTextStyle.color ?? Colors.white,
            size: theme.instructionTextStyle.fontSize != null 
                ? theme.instructionTextStyle.fontSize! * 1.5 
                : 24,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            instruction,
            style: theme.instructionTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: shape != null ? null : BorderRadius.circular(16),
      ),
      child: content,
    );

    if (animate) {
      return _AnimatedInstruction(
        child: container,
        shape: shape,
      );
    } else {
      return container;
    }
  }
}

/// Animated version of instruction overlay
class _AnimatedInstruction extends StatefulWidget {
  final Widget child;
  final ShapeBorder? shape;

  const _AnimatedInstruction({
    Key? key,
    required this.child,
    this.shape,
  }) : super(key: key);

  @override
  State<_AnimatedInstruction> createState() => _AnimatedInstructionState();
}

class _AnimatedInstructionState extends State<_AnimatedInstruction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.05),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 60.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Animated status message with transition
class AnimatedStatusMessage extends StatelessWidget {
  /// Current status message
  final String message;
  
  /// Theme for styling
  final LivenessTheme theme;
  
  /// Optional icon to display
  final IconData? icon;

  /// Constructor
  const AnimatedStatusMessage({
    Key? key,
    required this.message,
    this.theme = const LivenessTheme(),
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, -0.5),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: InstructionOverlay(
        key: ValueKey<String>(message),
        instruction: message,
        theme: theme,
        icon: icon,
      ),
    );
  }
}