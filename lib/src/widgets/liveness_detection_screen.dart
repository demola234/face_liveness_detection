import 'package:camera/camera.dart';
import 'package:face_liveness_detection/face_liveness_detection.dart';
import 'package:face_liveness_detection/src/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'instruction_overlay.dart';
import 'liveness_progress_bar.dart';
import 'oval_overlay_painter.dart';
import 'status_indicator.dart';
import 'success_overlay.dart';

/// Main widget for liveness detection
class LivenessDetectionScreen extends StatefulWidget {
  /// Available cameras
  final List<CameraDescription> cameras;

  /// Configuration
  final LivenessConfig? config;

  /// Theme
  final LivenessTheme? theme;

  /// Callback for when a challenge is completed
  final ChallengeCompletedCallback? onChallengeCompleted;

  /// Callback for when liveness verification is completed
  final LivenessCompletedCallback? onLivenessCompleted;

  /// Whether to show app bar
  final bool showAppBar;

  /// Custom app bar
  final PreferredSizeWidget? customAppBar;

  /// Custom success overlay
  final Widget? customSuccessOverlay;

  /// Whether to show status indicators
  final bool showStatusIndicators;

  /// Whether to show the capture image button
  final bool showCaptureImageButton;

  /// Callback when image is captured
  final Function(String sessionId, XFile imageFile)? onImageCaptured;

  /// Text for the capture button
  final String? captureButtonText;

  /// Constructor
  const LivenessDetectionScreen({
    super.key,
    required this.cameras,
    this.config,
    this.theme,
    this.onChallengeCompleted,
    this.onLivenessCompleted,
    this.showAppBar = true,
    this.customAppBar,
    this.customSuccessOverlay,
    this.showStatusIndicators = true,
    this.showCaptureImageButton = false,
    this.onImageCaptured,
    this.captureButtonText,
  });

  @override
  State<LivenessDetectionScreen> createState() =>
      _LivenessDetectionScreenState();
}

class _LivenessDetectionScreenState extends State<LivenessDetectionScreen>
    with WidgetsBindingObserver {
  late LivenessController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LivenessController(
      cameras: widget.cameras,
      config: widget.config,
      theme: widget.theme,
      onChallengeCompleted: widget.onChallengeCompleted,
      onLivenessCompleted: widget.onLivenessCompleted,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _controller = LivenessController(
        cameras: widget.cameras,
        config: widget.config,
        theme: widget.theme,
        onChallengeCompleted: widget.onChallengeCompleted,
        onLivenessCompleted: widget.onLivenessCompleted,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: LivenessDetectionView(
        showAppBar: widget.showAppBar,
        customAppBar: widget.customAppBar,
        customSuccessOverlay: widget.customSuccessOverlay,
        showStatusIndicators: widget.showStatusIndicators,
        showCaptureImageButton: widget.showCaptureImageButton,
        onImageCaptured: widget.onImageCaptured,
        captureButtonText: widget.captureButtonText,
      ),
    );
  }
}

/// View component of the liveness detection screen
class LivenessDetectionView extends StatelessWidget {
  /// Whether to show app bar
  final bool showAppBar;

  /// Custom app bar
  final PreferredSizeWidget? customAppBar;

  /// Custom success overlay
  final Widget? customSuccessOverlay;

  /// Whether to show status indicators
  final bool showStatusIndicators;

  /// Whether to show the capture image button
  final bool showCaptureImageButton;

  /// Callback when image is captured
  final Function(String sessionId, XFile imageFile)? onImageCaptured;

  /// Text for the capture button
  final String? captureButtonText;

  /// Constructor
  const LivenessDetectionView({
    super.key,
    this.showAppBar = true,
    this.customAppBar,
    this.customSuccessOverlay,
    this.showStatusIndicators = true,
    this.showCaptureImageButton = false,
    this.onImageCaptured,
    this.captureButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LivenessController>(context);
    final mediaQuery = MediaQuery.of(context);
    final theme = controller.theme;

    // Show loading screen until initialized
    if (!controller.isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Initializing camera...',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.statusTextStyle.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build app bar if enabled
    final appBar = showAppBar
        ? customAppBar ??
            AppBar(
              title: const Text('Face Liveness Detection'),
              backgroundColor: theme.appBarBackgroundColor,
              foregroundColor: theme.appBarTextColor,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.resetSession,
                ),
              ],
            )
        : null;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                _buildCameraPreview(controller),

                // Oval overlay
                AnimatedOvalOverlay(
                  isFaceDetected: controller.isFaceDetected,
                  config: controller.config,
                  theme: controller.theme,
                ),

                // Status indicators
                if (showStatusIndicators) ...[
                  Positioned(
                    top: showAppBar ? 100 : 40,
                    right: 20,
                    child: StatusIndicator.faceDetection(
                      isActive: controller.isFaceDetected,
                      theme: theme,
                    ),
                  ),
                  Positioned(
                    top: showAppBar ? 100 : 40,
                    left: 20,
                    child: StatusIndicator.lighting(
                      isActive: controller.isLightingGood,
                      theme: theme,
                    ),
                  ),
                ],

                // Status message
                Positioned(
                  top: (showAppBar ? kToolbarHeight : 0) +
                      mediaQuery.padding.top +
                      20,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: AnimatedStatusMessage(
                      message: controller.statusMessage,
                      theme: theme,
                    ),
                  ),
                ),

                // Face centering message
                if (controller.currentState == LivenessState.centeringFace)
                  Positioned(
                    bottom: 100 + mediaQuery.padding.bottom,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Text(
                        controller.faceCenteringMessage,
                        style: theme.guidanceTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Progress bar
                Positioned(
                  bottom: 40 + mediaQuery.padding.bottom,
                  left: 20,
                  right: 20,
                  child: LivenessProgressBar(
                    progress: controller.progress,
                  ),
                ),

                // Success overlay
                if (controller.currentState == LivenessState.completed)
                  customSuccessOverlay ??
                      SuccessOverlay(
                        sessionId: controller.sessionId,
                        onReset: controller.resetSession,
                        theme: theme,
                        isSuccessful: controller.isVerificationSuccessful,
                        showCaptureImageButton: showCaptureImageButton,
                        captureButtonText: captureButtonText,
                        onCaptureImage: showCaptureImageButton
                            ? (sessionId) async {
                                final imageFile =
                                    await controller.captureImage();
                                if (imageFile != null &&
                                    onImageCaptured != null) {
                                  onImageCaptured!(sessionId, imageFile);
                                }
                              }
                            : null,
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraPreview(LivenessController controller) {
    if (controller.isInitialized && controller.cameraController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.cameraController!.value.previewSize!.height,
          height: controller.cameraController!.value.previewSize!.width,
          child: CameraPreview(controller.cameraController!),
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
