
import 'package:flutter/material.dart';

class LivenessProgressBar extends StatelessWidget {
  final double progress;

  const LivenessProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey.withOpacity(0.5),
      valueColor: AlwaysStoppedAnimation<Color>(
        progress == 1.0 ? Colors.green : Colors.blue,
      ),
      minHeight: 10,
    );
  }
}