import 'package:face_liveness_detection/src/utils/enums.dart';

import '../utils/constants.dart';

/// Configuration class for customizing the Face Liveness Detection package
class LivenessConfig {
  /// Duration after which the session expires and resets
  final Duration maxSessionDuration;

  /// Minimum relative size a face must be to be detected
  final double minFaceSize;

  /// Threshold value for eyes to be considered open (0.0-1.0)
  final double eyeBlinkThresholdOpen;

  /// Threshold value for eyes to be considered closed (0.0-1.0)
  final double eyeBlinkThresholdClosed;

  /// Threshold value for face to be considered neutral/not smiling (0.0-1.0)
  final double smileThresholdNeutral;

  /// Threshold value for face to be considered smiling (0.0-1.0)
  final double smileThresholdSmiling;

  /// Angle in degrees for head to be considered turned
  final double headTurnThreshold;

  /// Minimum threshold for adequate lighting (0.0-1.0)
  final double minLightingThreshold;

  /// Pixel value (0-255) for detecting overly bright regions
  final int brightPixelThreshold;

  /// Minimum percentage of bright pixels to detect screen glare
  final double minBrightPercentage;

  /// Maximum percentage of bright pixels to detect screen glare
  final double maxBrightPercentage;

  /// Camera zoom level for better face visibility
  final double cameraZoomLevel;

  /// Maximum number of motion sensor readings to store
  final int maxMotionReadings;

  /// Maximum number of head angle readings to store
  final int maxHeadAngleReadings;

  /// Range of head angles considered significant for spoofing detection
  final double significantHeadAngleRange;

  /// Minimum device movement threshold for spoofing detection
  final double minDeviceMovementThreshold;

  /// Height ratio of the oval face guide relative to screen height
  final double ovalHeightRatio;

  /// Width ratio of the oval face guide relative to its height
  final double ovalWidthRatio;

  /// Stroke width of the oval face guide
  final double strokeWidth;

  /// Ratio for the outer guide markers
  final double guideMarkerRatio;

  /// Ratio for the inner guide markers
  final double guideMarkerInnerRatio;

  /// List of challenge types to use
  /// If null, random challenges will be generated
  final List<ChallengeType>? challengeTypes;

  /// Number of challenges to present to the user
  /// Only used if challengeTypes is null
  final int numberOfRandomChallenges;

  /// Always include blink challenge (as it's harder to spoof)
  final bool alwaysIncludeBlink;

  /// Custom messages for each challenge type
  final Map<ChallengeType, String>? challengeInstructions;

  const LivenessConfig({
    this.maxSessionDuration = LivenessConstants.defaultMaxSessionDuration,
    this.minFaceSize = LivenessConstants.defaultMinFaceSize,
    this.eyeBlinkThresholdOpen = LivenessConstants.defaultEyeBlinkThresholdOpen,
    this.eyeBlinkThresholdClosed =
        LivenessConstants.defaultEyeBlinkThresholdClosed,
    this.smileThresholdNeutral = LivenessConstants.defaultSmileThresholdNeutral,
    this.smileThresholdSmiling = LivenessConstants.defaultSmileThresholdSmiling,
    this.headTurnThreshold = LivenessConstants.defaultHeadTurnThreshold,
    this.minLightingThreshold = LivenessConstants.defaultMinLightingThreshold,
    this.brightPixelThreshold = LivenessConstants.defaultBrightPixelThreshold,
    this.minBrightPercentage = LivenessConstants.defaultMinBrightPercentage,
    this.maxBrightPercentage = LivenessConstants.defaultMaxBrightPercentage,
    this.cameraZoomLevel = LivenessConstants.defaultCameraZoomLevel,
    this.maxMotionReadings = LivenessConstants.defaultMaxMotionReadings,
    this.maxHeadAngleReadings = LivenessConstants.defaultMaxHeadAngleReadings,
    this.significantHeadAngleRange =
        LivenessConstants.defaultSignificantHeadAngleRange,
    this.minDeviceMovementThreshold =
        LivenessConstants.defaultMinDeviceMovementThreshold,
    this.ovalHeightRatio = LivenessConstants.defaultOvalHeightRatio,
    this.ovalWidthRatio = LivenessConstants.defaultOvalWidthRatio,
    this.strokeWidth = LivenessConstants.defaultStrokeWidth,
    this.guideMarkerRatio = LivenessConstants.defaultGuideMarkerRatio,
    this.guideMarkerInnerRatio = LivenessConstants.defaultGuideMarkerInnerRatio,
    this.challengeTypes,
    this.numberOfRandomChallenges = 3,
    this.alwaysIncludeBlink = true,
    this.challengeInstructions,
  });

  /// Create a copy of this configuration with some values replaced
  LivenessConfig copyWith({
    Duration? maxSessionDuration,
    double? minFaceSize,
    double? eyeBlinkThresholdOpen,
    double? eyeBlinkThresholdClosed,
    double? smileThresholdNeutral,
    double? smileThresholdSmiling,
    double? headTurnThreshold,
    double? minLightingThreshold,
    int? brightPixelThreshold,
    double? minBrightPercentage,
    double? maxBrightPercentage,
    double? cameraZoomLevel,
    int? maxMotionReadings,
    int? maxHeadAngleReadings,
    double? significantHeadAngleRange,
    double? minDeviceMovementThreshold,
    double? ovalHeightRatio,
    double? ovalWidthRatio,
    double? strokeWidth,
    double? guideMarkerRatio,
    double? guideMarkerInnerRatio,
    List<ChallengeType>? challengeTypes,
    int? numberOfRandomChallenges,
    bool? alwaysIncludeBlink,
    Map<ChallengeType, String>? challengeInstructions,
  }) {
    return LivenessConfig(
      maxSessionDuration: maxSessionDuration ?? this.maxSessionDuration,
      minFaceSize: minFaceSize ?? this.minFaceSize,
      eyeBlinkThresholdOpen:
          eyeBlinkThresholdOpen ?? this.eyeBlinkThresholdOpen,
      eyeBlinkThresholdClosed:
          eyeBlinkThresholdClosed ?? this.eyeBlinkThresholdClosed,
      smileThresholdNeutral:
          smileThresholdNeutral ?? this.smileThresholdNeutral,
      smileThresholdSmiling:
          smileThresholdSmiling ?? this.smileThresholdSmiling,
      headTurnThreshold: headTurnThreshold ?? this.headTurnThreshold,
      minLightingThreshold: minLightingThreshold ?? this.minLightingThreshold,
      brightPixelThreshold: brightPixelThreshold ?? this.brightPixelThreshold,
      minBrightPercentage: minBrightPercentage ?? this.minBrightPercentage,
      maxBrightPercentage: maxBrightPercentage ?? this.maxBrightPercentage,
      cameraZoomLevel: cameraZoomLevel ?? this.cameraZoomLevel,
      maxMotionReadings: maxMotionReadings ?? this.maxMotionReadings,
      maxHeadAngleReadings: maxHeadAngleReadings ?? this.maxHeadAngleReadings,
      significantHeadAngleRange:
          significantHeadAngleRange ?? this.significantHeadAngleRange,
      minDeviceMovementThreshold:
          minDeviceMovementThreshold ?? this.minDeviceMovementThreshold,
      ovalHeightRatio: ovalHeightRatio ?? this.ovalHeightRatio,
      ovalWidthRatio: ovalWidthRatio ?? this.ovalWidthRatio,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      guideMarkerRatio: guideMarkerRatio ?? this.guideMarkerRatio,
      guideMarkerInnerRatio:
          guideMarkerInnerRatio ?? this.guideMarkerInnerRatio,
      challengeTypes: challengeTypes ?? this.challengeTypes,
      numberOfRandomChallenges:
          numberOfRandomChallenges ?? this.numberOfRandomChallenges,
      alwaysIncludeBlink: alwaysIncludeBlink ?? this.alwaysIncludeBlink,
      challengeInstructions:
          challengeInstructions ?? this.challengeInstructions,
    );
  }
}
