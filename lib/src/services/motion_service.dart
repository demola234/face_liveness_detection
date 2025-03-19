import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../config/app_config.dart';

/// Service for motion tracking and spoofing detection
class MotionService {
  /// Accelerometer readings
  final List<AccelerometerEvent> _accelerometerReadings = [];
  
  /// Subscription to accelerometer events
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  /// Configuration for liveness detection
  LivenessConfig _config;

  /// Constructor with optional configuration
  MotionService({
    LivenessConfig? config,
  }) : _config = config ?? const LivenessConfig();

  /// Start tracking device motion
  void startAccelerometerTracking() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerReadings.add(event);
      if (_accelerometerReadings.length > _config.maxMotionReadings) {
        _accelerometerReadings.removeAt(0);
      }
    });
  }

  /// Update configuration
  void updateConfig(LivenessConfig config) {
    _config = config;
    
    // Trim readings if the max count was reduced
    if (_accelerometerReadings.length > _config.maxMotionReadings) {
      _accelerometerReadings.removeRange(
        0, 
        _accelerometerReadings.length - _config.maxMotionReadings
      );
    }
  }

  /// Check if head motion correlates with device motion (anti-spoofing)
  bool verifyMotionCorrelation(List<double> headAngleReadings) {
    if (headAngleReadings.isEmpty || _accelerometerReadings.isEmpty) {
      debugPrint('Not enough motion data to verify correlation');
      return true;
    }

    double maxHeadAngle = headAngleReadings.reduce(math.max);
    double minHeadAngle = headAngleReadings.reduce(math.min);
    double headAngleRange = maxHeadAngle - minHeadAngle;

    double maxDeviceAngle =
        _accelerometerReadings.map((e) => e.y).reduce(math.max);
    double minDeviceAngle =
        _accelerometerReadings.map((e) => e.y).reduce(math.min);
    double deviceAngleRange = maxDeviceAngle - minDeviceAngle;

    debugPrint(
        'Head angle range: $headAngleRange, Device angle range: $deviceAngleRange');

    return !(headAngleRange > _config.significantHeadAngleRange &&
        deviceAngleRange < _config.minDeviceMovementThreshold);
  }

  /// Reset all motion tracking
  void resetTracking() {
    _accelerometerReadings.clear();
  }

  /// Clean up resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
  
  /// Get raw accelerometer readings
  List<AccelerometerEvent> get accelerometerReadings => 
      List<AccelerometerEvent>.unmodifiable(_accelerometerReadings);
}