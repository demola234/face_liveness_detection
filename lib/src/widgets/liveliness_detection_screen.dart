import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_liveliness_detection/smart_liveliness_detection.dart';
import 'package:smart_liveliness_detection/src/utils/enums.dart';
import 'package:smart_liveliness_detection/src/widgets/instruction_overlay.dart';
import 'package:smart_liveliness_detection/src/widgets/liveness_progress_bar.dart';
import 'package:smart_liveliness_detection/src/widgets/oval_progress.dart';
import 'package:smart_liveliness_detection/src/widgets/status_indicator.dart';

import 'success_overlay.dart';

/// Callback type for when a challenge is completed
typedef ChallengeCompletedCallback = void Function(String challengeType);

/// Callback type for when liveness verification is completed
typedef LivenessCompletedCallback = void Function(
    String sessionId, bool isSuccessful, Map<String, dynamic> data);

/// Callback type for when final image is captured with metadata
typedef FinalImageCapturedCallback = void Function(
    String sessionId, XFile imageFile, Map<String, dynamic> metadata);

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

  /// Callback when manual image is captured
  final Function(String sessionId, XFile imageFile)? onManualImageCaptured;

  /// Text for the capture button
  final String? captureButtonText;

  /// Whether to use color progress for oval
  final bool useColorProgress;

  /// Whether to capture a single image at the end of verification
  final bool captureFinalImage;

  /// Callback for when final image is captured with metadata
  final FinalImageCapturedCallback? onFinalImageCaptured;

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
    this.onManualImageCaptured,
    this.captureButtonText,
    this.useColorProgress = true,
    this.captureFinalImage = false,
    this.onFinalImageCaptured,
  });

  @override
  State<LivenessDetectionScreen> createState() =>
      _LivenessDetectionScreenState();
}

class _LivenessDetectionScreenState extends State<LivenessDetectionScreen>
    with WidgetsBindingObserver {
  late LivenessController _controller;
  XFile? _finalImage;
  Map<String, dynamic>? _imageMetadata;

  @override
  void initState() {
    super.initState();
    _controller = LivenessController(
      cameras: widget.cameras,
      config: widget.config,
      theme: widget.theme,
      onChallengeCompleted: widget.onChallengeCompleted,
      // Make sure this is using the same type
      onLivenessCompleted: widget.onLivenessCompleted != null
          ? (sessionId, isSuccessful, data) {
              widget.onLivenessCompleted!(sessionId, isSuccessful, data!);
            }
          : null,
      onFinalImageCaptured: _handleFinalImageCaptured,
      captureFinalImage: widget.captureFinalImage,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  void _handleFinalImageCaptured(
      String sessionId, XFile imageFile, Map<String, dynamic> metadata) {
    setState(() {
      _finalImage = imageFile;
      _imageMetadata = metadata;
    });

    if (widget.onFinalImageCaptured != null) {
      widget.onFinalImageCaptured!(sessionId, imageFile, metadata);
    }
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
        // Make sure this is using the same type
        onLivenessCompleted: widget.onLivenessCompleted != null
            ? (sessionId, isSuccessful, data) {
                widget.onLivenessCompleted!(sessionId, isSuccessful, data!);
              }
            : null,
        onFinalImageCaptured: _handleFinalImageCaptured,
        captureFinalImage: widget.captureFinalImage,
      );
      setState(() {
        _finalImage = null;
        _imageMetadata = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Builder(builder: (context) {
        // If we have a final image and custom success overlay isn't provided,
        // use our own success overlay with the captured image
        Widget? successOverlay = widget.customSuccessOverlay;
        if (successOverlay == null &&
            _finalImage != null &&
            widget.captureFinalImage) {
          successOverlay = _buildSuccessWithImage(context);
        }

        // Use the LivenessDetectionView as a widget, not a method
        return LivenessDetectionView(
          showAppBar: widget.showAppBar,
          customAppBar: widget.customAppBar,
          customSuccessOverlay: successOverlay,
          showStatusIndicators: widget.showStatusIndicators,
          showCaptureImageButton: widget.showCaptureImageButton,
          onImageCaptured: _handleManualCapture,
          captureButtonText: widget.captureButtonText,
          useColorProgress: widget.useColorProgress,
        );
      }),
    );
  }

  void _handleManualCapture(String sessionId) async {
    final imageFile = await _controller.captureImage();
    if (imageFile != null && widget.onManualImageCaptured != null) {
      widget.onManualImageCaptured!(sessionId, imageFile);
    }
  }

  Widget _buildSuccessWithImage(BuildContext context) {
    final controller = Provider.of<LivenessController>(context);
    final theme = controller.theme;

    if (_finalImage == null) return const SizedBox.shrink();

    return Stack(
      children: [
        SuccessOverlay(
          sessionId: controller.sessionId,
          onReset: controller.resetSession,
          theme: theme,
          isSuccessful: controller.isVerificationSuccessful,
          showCaptureImageButton: widget.showCaptureImageButton,
          captureButtonText: widget.captureButtonText,
          onCaptureImage:
              widget.showCaptureImageButton ? _handleManualCapture : null,
        ),
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Text(
                "Verification Image Captured",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.successColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.file(
                    File(_finalImage!.path),
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
  final Function(String sessionId)? onImageCaptured;

  /// Text for the capture button
  final String? captureButtonText;

  /// Whether to use color progress for oval
  final bool useColorProgress;

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
    this.useColorProgress = true,
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
              CircularProgressIndicator.adaptive(
                backgroundColor: theme.primaryColor,
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

                // Oval overlay with color progress indicator
                if (useColorProgress)
                  OvalColorProgressOverlay(
                    isFaceDetected: controller.isFaceDetected,
                    config: controller.config,
                    theme: controller.theme,
                    progress: controller.progress,
                    startColor: theme.primaryColor,
                    endColor: theme.successColor,
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

                // Progress bar (if color progress is disabled)
                if (!useColorProgress)
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
                                onImageCaptured?.call(sessionId);
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
      return const Center(child: CircularProgressIndicator.adaptive());
    }
  }
}
