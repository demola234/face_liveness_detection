import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../config/theme_config.dart';

/// Widget to draw face landmarks and contours
class FaceLandmarksOverlay extends StatelessWidget {
  /// Detected face
  final Face? face;

  /// Theme for styling
  final LivenessTheme theme;

  /// Size of the image
  final Size imageSize;

  /// Scale factor for the display
  final double scale;

  /// Whether to show face contour
  final bool showContour;

  /// Whether to show facial landmarks
  final bool showLandmarks;

  /// Whether to show bounding box
  final bool showBoundingBox;

  /// Whether to show head rotation angles
  final bool showHeadRotation;

  /// Color for landmarks
  final Color landmarkColor;

  /// Color for contours
  final Color contourColor;

  /// Color for bounding box
  final Color boundingBoxColor;

  /// Width of the stroke
  final double strokeWidth;

  /// Constructor
  const FaceLandmarksOverlay({
    super.key,
    this.face,
    this.theme = const LivenessTheme(),
    required this.imageSize,
    this.scale = 1.0,
    this.showContour = true,
    this.showLandmarks = true,
    this.showBoundingBox = true,
    this.showHeadRotation = true,
    Color? landmarkColor,
    Color? contourColor,
    Color? boundingBoxColor,
    this.strokeWidth = 3.0,
  })  : landmarkColor = landmarkColor ?? Colors.yellow,
        contourColor = contourColor ?? Colors.green,
        boundingBoxColor = boundingBoxColor ?? Colors.red;

  @override
  Widget build(BuildContext context) {
    if (face == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _FaceLandmarksPainter(
        face: face!,
        imageSize: imageSize,
        scale: scale,
        showContour: showContour,
        showLandmarks: showLandmarks,
        showBoundingBox: showBoundingBox,
        showHeadRotation: showHeadRotation,
        landmarkColor: landmarkColor,
        contourColor: contourColor,
        boundingBoxColor: boundingBoxColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _FaceLandmarksPainter extends CustomPainter {
  final Face face;
  final Size imageSize;
  final double scale;
  final bool showContour;
  final bool showLandmarks;
  final bool showBoundingBox;
  final bool showHeadRotation;
  final Color landmarkColor;
  final Color contourColor;
  final Color boundingBoxColor;
  final double strokeWidth;

  _FaceLandmarksPainter({
    required this.face,
    required this.imageSize,
    required this.scale,
    required this.showContour,
    required this.showLandmarks,
    required this.showBoundingBox,
    required this.showHeadRotation,
    required this.landmarkColor,
    required this.contourColor,
    required this.boundingBoxColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scaling factors for different dimensions
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    // Draw bounding box
    if (showBoundingBox) {
      final Rect boundingBox = Rect.fromLTRB(
        face.boundingBox.left * scaleX,
        face.boundingBox.top * scaleY,
        face.boundingBox.right * scaleX,
        face.boundingBox.bottom * scaleY,
      );

      canvas.drawRect(
        boundingBox,
        Paint()
          ..color = boundingBoxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    // Draw facial landmarks
    if (showLandmarks) {
      final landmarkPaint = Paint()
        ..color = landmarkColor
        ..style = PaintingStyle.fill;

      void drawLandmark(FaceLandmarkType type) {
        final landmark = face.landmarks[type];
        if (landmark != null) {
          canvas.drawCircle(
            Offset(
              landmark.position.x * scaleX,
              landmark.position.y * scaleY,
            ),
            strokeWidth * 1.5,
            landmarkPaint,
          );
        }
      }

      // Draw each landmark if available
      drawLandmark(FaceLandmarkType.leftEye);
      drawLandmark(FaceLandmarkType.rightEye);
      drawLandmark(FaceLandmarkType.leftEar);
      drawLandmark(FaceLandmarkType.rightEar);
      drawLandmark(FaceLandmarkType.leftCheek);
      drawLandmark(FaceLandmarkType.rightCheek);
      drawLandmark(FaceLandmarkType.noseBase);
      drawLandmark(FaceLandmarkType.leftMouth);
      drawLandmark(FaceLandmarkType.rightMouth);
      drawLandmark(FaceLandmarkType.bottomMouth);
    }

    // Draw facial contours
    if (showContour) {
      final contourPaint = Paint()
        ..color = contourColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      void drawContour(FaceContourType type) {
        final contour = face.contours[type];
        if (contour != null && contour.points.isNotEmpty) {
          final path = Path();
          final firstPoint = contour.points.first;
          path.moveTo(
            firstPoint.x * scaleX,
            firstPoint.y * scaleY,
          );

          for (final point in contour.points.skip(1)) {
            path.lineTo(
              point.x * scaleX,
              point.y * scaleY,
            );
          }

          // Close the path for certain contours
          if (type == FaceContourType.face ||
              type == FaceContourType.leftEyebrowTop ||
              type == FaceContourType.leftEyebrowBottom ||
              type == FaceContourType.rightEyebrowTop ||
              type == FaceContourType.rightEyebrowBottom ||
              type == FaceContourType.leftEye ||
              type == FaceContourType.rightEye) {
            path.close();
          }

          canvas.drawPath(path, contourPaint);
        }
      }

      // Draw each contour if available
      drawContour(FaceContourType.face);
      drawContour(FaceContourType.leftEyebrowTop);
      drawContour(FaceContourType.leftEyebrowBottom);
      drawContour(FaceContourType.rightEyebrowTop);
      drawContour(FaceContourType.rightEyebrowBottom);
      drawContour(FaceContourType.leftEye);
      drawContour(FaceContourType.rightEye);
      drawContour(FaceContourType.upperLipTop);
      drawContour(FaceContourType.upperLipBottom);
      drawContour(FaceContourType.lowerLipTop);
      drawContour(FaceContourType.lowerLipBottom);
      drawContour(FaceContourType.noseBridge);
      drawContour(FaceContourType.noseBottom);
    }

    // Draw head rotation information
    if (showHeadRotation &&
        (face.headEulerAngleX != null ||
            face.headEulerAngleY != null ||
            face.headEulerAngleZ != null)) {
      const textStyle = TextStyle(
        color: Colors.white,
        backgroundColor: Colors.black54,
        fontSize: 14,
      );
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      String headRotationText = 'Head Rotation:\n';
      if (face.headEulerAngleX != null) {
        headRotationText += 'X: ${face.headEulerAngleX!.toStringAsFixed(1)}°\n';
      }
      if (face.headEulerAngleY != null) {
        headRotationText += 'Y: ${face.headEulerAngleY!.toStringAsFixed(1)}°\n';
      }
      if (face.headEulerAngleZ != null) {
        headRotationText += 'Z: ${face.headEulerAngleZ!.toStringAsFixed(1)}°';
      }

      textPainter.text = TextSpan(
        text: headRotationText,
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          face.boundingBox.right * scaleX + 8,
          face.boundingBox.top * scaleY,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_FaceLandmarksPainter oldDelegate) =>
      face != oldDelegate.face ||
      imageSize != oldDelegate.imageSize ||
      scale != oldDelegate.scale ||
      showContour != oldDelegate.showContour ||
      showLandmarks != oldDelegate.showLandmarks ||
      showBoundingBox != oldDelegate.showBoundingBox ||
      showHeadRotation != oldDelegate.showHeadRotation ||
      landmarkColor != oldDelegate.landmarkColor ||
      contourColor != oldDelegate.contourColor ||
      boundingBoxColor != oldDelegate.boundingBoxColor ||
      strokeWidth != oldDelegate.strokeWidth;
}
