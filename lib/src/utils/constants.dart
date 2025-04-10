// Default values that can be overridden by AppConfig
class LivenessConstants {
  // Session duration
  static const Duration defaultMaxSessionDuration = Duration(minutes: 2);

  // Face detection thresholds
  static const double defaultMinFaceSize = 0.15;
  static const double defaultEyeBlinkThresholdOpen = 0.7;
  static const double defaultEyeBlinkThresholdClosed = 0.3;
  static const double defaultSmileThresholdNeutral = 0.3;
  static const double defaultSmileThresholdSmiling = 0.7;
  static const double defaultHeadTurnThreshold = 20.0;

  // Lighting thresholds
  static const double defaultMinLightingThreshold = 0.25;
  static const int defaultBrightPixelThreshold = 230;
  static const double defaultMinBrightPercentage = 0.05;
  static const double defaultMaxBrightPercentage = 0.30;

  // Camera settings
  static const double defaultCameraZoomLevel = 0.5;

  // Motion detection
  static const int defaultMaxMotionReadings = 100;
  static const int defaultMaxHeadAngleReadings = 30;
  static const double defaultSignificantHeadAngleRange = 20.0;
  static const double defaultMinDeviceMovementThreshold = 0.5;

  // UI settings
  static const double defaultOvalHeightRatio = 0.55;
  static const double defaultOvalWidthRatio = 0.75;
  static const double defaultStrokeWidth = 4.0;
  static const double defaultGuideMarkerRatio = 0.55;
  static const double defaultGuideMarkerInnerRatio = 0.35;
}

enum ChallengeType { blink, turnLeft, turnRight, smile, nod }

enum LivenessState {
  initial,
  centeringFace,
  performingChallenges,
  completed,
}
