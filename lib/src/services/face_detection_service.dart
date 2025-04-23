import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:smart_liveliness_detection/src/utils/enums.dart';

import '../config/app_config.dart';

/// Service for face detection and gesture recognition
class FaceDetectionService {
  /// ML Kit face detector
  late FaceDetector _faceDetector;

  /// Whether currently processing an image
  bool _isProcessingImage = false;

  /// Last measured eye open probability
  double? _lastEyeOpenProbability;

  /// Last measured smile probability
  double? _lastSmileProbability;

  /// Whether face is properly centered
  bool _isFaceCentered = false;

  /// Last measured head angle X (for nodding)
  double? _lastHeadEulerAngleX;

  /// History of head angle readings
  final List<double> _headAngleReadings = [];

  /// Configuration for liveness detection
  final LivenessConfig _config;

  /// Constructor with optional configuration
  FaceDetectionService({
    LivenessConfig? config,
  }) : _config = config ?? const LivenessConfig() {
    _initializeDetector();
  }

  /// Initialize the face detector with current configuration
  void _initializeDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: _config.minFaceSize,
      ),
    );
  }

  /// Update configuration
  void updateConfig(LivenessConfig config) {
    if (_config.minFaceSize != config.minFaceSize) {
      // Dispose and reinitialize with new settings
      _faceDetector.close();
      _initializeDetector();
    }
  }

  /// Check if face is centered in the oval guide
  bool checkFaceCentering(Face face, Size screenSize) {
    final screenCenterX = screenSize.width / 2;
    final screenCenterY = screenSize.height / 2 - screenSize.height * 0.05;

    final faceBox = face.boundingBox;
    final faceCenterX = faceBox.left + faceBox.width / 2;
    final faceCenterY = faceBox.top + faceBox.height / 2;

    final maxHorizontalOffset = screenSize.width * 0.1;
    final maxVerticalOffset = screenSize.height * 0.1;

    final ovalHeight = screenSize.height * 0.55;
    final ovalWidth = ovalHeight * 0.75;

    const minFaceWidthRatio = 0.5;
    const maxFaceWidthRatio = 0.9;

    final faceWidthRatio = faceBox.width / ovalWidth;

    final isHorizontallyCentered =
        (faceCenterX - screenCenterX).abs() < maxHorizontalOffset;
    final isVerticallyCentered =
        (faceCenterY - screenCenterY).abs() < maxVerticalOffset;

    final isRightSize = faceWidthRatio >= minFaceWidthRatio &&
        faceWidthRatio <= maxFaceWidthRatio;

    debugPrint(
        'Face centering: H=$isHorizontallyCentered, V=$isVerticallyCentered, Size=$isRightSize');
    debugPrint('Face width ratio: $faceWidthRatio');

    _isFaceCentered =
        isHorizontallyCentered && isVerticallyCentered && isRightSize;
    return _isFaceCentered;
  }

  /// Process camera image to detect faces
  Future<List<Face>> processImage(
      CameraImage image, CameraDescription camera) async {
    if (_isProcessingImage) return [];

    _isProcessingImage = true;
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.values[camera.sensorOrientation ~/ 90],
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      debugPrint('Error processing image: $e');
      return [];
    } finally {
      _isProcessingImage = false;
    }
  }

  /// Detect if a challenge has been completed
  bool detectChallengeCompletion(Face face, ChallengeType challengeType) {
    switch (challengeType) {
      case ChallengeType.blink:
        return _detectBlink(face);
      case ChallengeType.turnLeft:
        return _detectLeftTurn(face);
      case ChallengeType.turnRight:
        return _detectRightTurn(face);
      case ChallengeType.smile:
        return _detectSmile(face);
      case ChallengeType.nod:
        return _detectNod(face);
    }
  }

  /// Detect left head turn
  bool _detectLeftTurn(Face face) {
    if (face.headEulerAngleY != null) {
      _storeHeadAngle(face.headEulerAngleY!);
      return face.headEulerAngleY! < -_config.headTurnThreshold;
    }
    return false;
  }

  /// Detect right head turn
  bool _detectRightTurn(Face face) {
    if (face.headEulerAngleY != null) {
      _storeHeadAngle(face.headEulerAngleY!);
      return face.headEulerAngleY! > _config.headTurnThreshold;
    }
    return false;
  }

  /// Detect eye blink
  bool _detectBlink(Face face) {
    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      final double avgEyeOpenProbability =
          (face.leftEyeOpenProbability! + face.rightEyeOpenProbability!) / 2;

      if (_lastEyeOpenProbability != null) {
        if (_lastEyeOpenProbability! > _config.eyeBlinkThresholdOpen &&
            avgEyeOpenProbability < _config.eyeBlinkThresholdClosed) {
          _lastEyeOpenProbability = avgEyeOpenProbability;
          return true;
        }
      }

      _lastEyeOpenProbability = avgEyeOpenProbability;
    }
    return false;
  }

  /// Detect smile
  bool _detectSmile(Face face) {
    if (face.smilingProbability != null) {
      final smileProbability = face.smilingProbability!;

      if (_lastSmileProbability != null) {
        if (_lastSmileProbability! < _config.smileThresholdNeutral &&
            smileProbability > _config.smileThresholdSmiling) {
          _lastSmileProbability = smileProbability;
          return true;
        }
      }

      _lastSmileProbability = smileProbability;
    }
    return false;
  }

  /// Detect head nod
  bool _detectNod(Face face) {
    if (face.headEulerAngleX != null) {
      final headAngleX = face.headEulerAngleX!;
      debugPrint('Nod angle: $headAngleX');

      if (_lastHeadEulerAngleX != null) {
        if ((_lastHeadEulerAngleX! < -10 && headAngleX > 10) ||
            (_lastHeadEulerAngleX! > 10 && headAngleX < -10)) {
          _lastHeadEulerAngleX = headAngleX;
          return true;
        }
      }

      _lastHeadEulerAngleX = headAngleX;
    }
    return false;
  }

  /// Store head angle reading
  void _storeHeadAngle(double angle) {
    _headAngleReadings.add(angle);
    if (_headAngleReadings.length > _config.maxHeadAngleReadings) {
      _headAngleReadings.removeAt(0);
    }
  }

  /// Get head angle readings
  List<double> get headAngleReadings => _headAngleReadings;

  /// Whether face is properly centered
  bool get isFaceCentered => _isFaceCentered;

  /// Reset all tracking data
  void resetTracking() {
    _lastEyeOpenProbability = null;
    _lastSmileProbability = null;
    _lastHeadEulerAngleX = null;
    _headAngleReadings.clear();
    _isFaceCentered = false;
  }

  /// Clean up resources
  void dispose() {
    _faceDetector.close();
  }
}
