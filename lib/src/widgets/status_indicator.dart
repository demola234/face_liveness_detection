import 'package:flutter/material.dart';

import '../config/theme_config.dart';

/// Widget for displaying status indicators (face detected, lighting, etc.)
class StatusIndicator extends StatelessWidget {
  /// Whether the status is active
  final bool isActive;
  
  /// Icon to show when active
  final IconData activeIcon;
  
  /// Icon to show when inactive
  final IconData inactiveIcon;
  
  /// Color to use when active
  final Color activeColor;
  
  /// Color to use when inactive
  final Color inactiveColor;
  
  /// Theme for styling
  final LivenessTheme theme;
  
  /// Optional label to display
  final String? label;
  
  /// Size of the indicator
  final double size;
  
  /// Whether to animate the status change
  final bool animate;
  
  /// Optional tooltip text
  final String? tooltip;

  /// Constructor
  const StatusIndicator({
    Key? key,
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.red,
    this.theme = const LivenessTheme(),
    this.label,
    this.size = 24.0,
    this.animate = true,
    this.tooltip,
  }) : super(key: key);
  
  /// Convenience constructor for face detection status
  factory StatusIndicator.faceDetection({
    bool isActive = false,
    LivenessTheme theme = const LivenessTheme(),
    String? label,
    double size = 24.0,
    bool animate = true,
  }) {
    return StatusIndicator(
      isActive: isActive,
      activeIcon: Icons.face,
      inactiveIcon: Icons.face_retouching_off,
      activeColor: theme.successColor,
      inactiveColor: theme.errorColor,
      theme: theme,
      label: label ?? 'Face',
      size: size,
      animate: animate,
      tooltip: isActive ? 'Face detected' : 'No face detected',
    );
  }
  
  /// Convenience constructor for lighting status
  factory StatusIndicator.lighting({
    bool isActive = false,
    LivenessTheme theme = const LivenessTheme(),
    String? label,
    double size = 24.0,
    bool animate = true,
  }) {
    return StatusIndicator(
      isActive: isActive,
      activeIcon: Icons.light_mode,
      inactiveIcon: Icons.light_mode_outlined,
      activeColor: theme.successColor,
      inactiveColor: theme.warningColor,
      theme: theme,
      label: label ?? 'Lighting',
      size: size,
      animate: animate,
      tooltip: isActive ? 'Good lighting' : 'Poor lighting',
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget indicator = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withOpacity(0.7)
            : inactiveColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : inactiveIcon,
            color: Colors.white,
            size: size,
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
    
    final Widget result = animate
        ? AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<bool>(isActive),
              child: indicator,
            ),
          )
        : indicator;
        
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: result,
      );
    } else {
      return result;
    }
  }
}

/// Widget for displaying multiple status indicators
class StatusIndicatorRow extends StatelessWidget {
  /// List of status indicators to display
  final List<StatusIndicator> indicators;
  
  /// Spacing between indicators
  final double spacing;
  
  /// Alignment of the row
  final MainAxisAlignment alignment;
  
  /// Background color
  final Color? backgroundColor;
  
  /// Padding around the row
  final EdgeInsetsGeometry padding;

  /// Constructor
  const StatusIndicatorRow({
    Key? key,
    required this.indicators,
    this.spacing = 8.0,
    this.alignment = MainAxisAlignment.center,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: indicators.isEmpty
          ? []
          : List.generate(
              indicators.length * 2 - 1,
              (index) {
                if (index.isEven) {
                  return indicators[index ~/ 2];
                } else {
                  return SizedBox(width: spacing);
                }
              },
            ),
    );
    
    if (backgroundColor != null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: row,
      );
    } else {
      return Padding(
        padding: padding,
        child: row,
      );
    }
  }
}