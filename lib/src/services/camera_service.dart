import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Service for camera-related operations in liveness detection
class CameraService {
  /// Camera controller
  CameraController? _controller;

  /// Whether the camera is initialized
  bool _isInitialized = false;

  /// Current lighting value (0.0-1.0)
  double _lightingValue = 0.0;

  /// Whether lighting conditions are good
  bool _isLightingGood = true;

  /// Configuration for liveness detection
  final LivenessConfig _config;

  /// Constructor with optional configuration
  CameraService({
    LivenessConfig? config,
  }) : _config = config ?? const LivenessConfig();

  /// Initialize the camera
  Future<CameraController> initialize(List<CameraDescription> cameras) async {
    if (_isInitialized && _controller != null) {
      return _controller!;
    }

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      await Future.delayed(const Duration(milliseconds: 300));

      if (_controller!.value.isInitialized) {
        try {
          final maxZoom = await _controller!.getMaxZoomLevel();

          if (maxZoom > 1.0) {
            double targetZoom = math.min(_config.cameraZoomLevel, maxZoom);
            await _controller!.setZoomLevel(targetZoom);
          }
        } catch (e) {
          debugPrint('Zoom control not supported: $e');
        }
      }

      _isInitialized = true;
      return _controller!;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      rethrow;
    }
  }

  /// Calculate lighting conditions from camera image
  void calculateLightingCondition(CameraImage image) {
    final Uint8List yPlane = image.planes[0].bytes;

    int totalBrightness = 0;
    for (int i = 0; i < yPlane.length; i++) {
      totalBrightness += yPlane[i];
    }

    final double avgBrightness = totalBrightness / yPlane.length;

    _lightingValue = avgBrightness / 255;

    _isLightingGood = _lightingValue > _config.minLightingThreshold;
  }

  /// Detect potential screen glare (anti-spoofing)
  bool detectScreenGlare(CameraImage image) {
    final yPlane = image.planes[0].bytes;

    int brightPixels = 0;
    int totalPixels = yPlane.length;

    for (int i = 0; i < totalPixels; i++) {
      if (yPlane[i] > _config.brightPixelThreshold) {
        brightPixels++;
      }
    }

    double brightPercent = brightPixels / totalPixels;

    return brightPercent > _config.minBrightPercentage &&
        brightPercent < _config.maxBrightPercentage;
  }

  /// Whether the camera is initialized
  bool get isInitialized => _isInitialized && _controller != null;

  /// Whether lighting conditions are good
  bool get isLightingGood => _isLightingGood;

  /// Current lighting value (0.0-1.0)
  double get lightingValue => _lightingValue;

  /// Camera controller
  CameraController? get controller => _controller;

  /// Clean up resources
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  /// Update configuration
  void updateConfig(LivenessConfig config) async {
    // Only update zoom if camera is initialized and zoom level changed
    if (_isInitialized &&
        _controller != null &&
        _config.cameraZoomLevel != config.cameraZoomLevel) {
      try {
        final maxZoom = await _controller!.getMaxZoomLevel();
        if (maxZoom > 1.0) {
          double targetZoom = math.min(config.cameraZoomLevel, maxZoom);
          await _controller!.setZoomLevel(targetZoom);
        }
      } catch (e) {
        debugPrint('Zoom control not supported: $e');
      }
    }
  }
}
