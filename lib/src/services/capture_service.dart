import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Service for capturing a single image at the end of verification
class CaptureService {
  /// Camera controller reference
  final CameraController? cameraController;

  /// Callback when image is captured
  final Function(XFile image)? onImageCaptured;

  /// Constructor
  CaptureService({
    required this.cameraController,
    this.onImageCaptured,
  });

  /// Capture a single image
  Future<XFile?> captureImage() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      debugPrint('Camera not initialized, cannot capture image');
      return null;
    }

    try {
      final XFile image = await cameraController!.takePicture();
      debugPrint('Image captured: ${image.path}');

      // Notify via callback
      onImageCaptured?.call(image);

      return image;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    // No resources to dispose
  }
}
