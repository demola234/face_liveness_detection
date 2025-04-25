import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_liveliness_detection/smart_liveliness_detection.dart';
import 'package:smart_liveliness_detection/src/utils/enums.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Optional: Set immersive mode
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Get available cameras
  final cameras = await availableCameras();

  runApp(FaceLivenessExampleApp(cameras: cameras));
}

class FaceLivenessExampleApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const FaceLivenessExampleApp({
    super.key,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Liveness Detection Demo',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(cameras: cameras),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({
    super.key,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Liveness Examples'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a liveness detection example:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            _buildExampleButton(
              context,
              'Default Style',
              'Use the package with default settings',
              () => _navigateToLivenessScreen(
                context,
                const LivenessConfig(),
                const LivenessTheme(),
              ),
            ),
            _buildExampleButton(
              context,
              'Custom Theme',
              'Custom colors and styling',
              () => _navigateToLivenessScreen(
                context,
                const LivenessConfig(),
                const LivenessTheme(
                  primaryColor: Colors.purple,
                  ovalGuideColor: Colors.purpleAccent,
                  successColor: Colors.green,
                  errorColor: Colors.redAccent,
                  overlayOpacity: 0.6,
                  progressIndicatorColor: Colors.purpleAccent,
                  instructionTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  useOvalPulseAnimation: true,
                ),
              ),
            ),
            _buildExampleButton(
              context,
              'Custom Challenges',
              'Specific challenge sequence with custom messages',
              () {
                const customConfig = LivenessConfig(
                  challengeTypes: [
                    ChallengeType.blink,
                    ChallengeType.smile,
                    ChallengeType.turnRight,
                  ],
                  challengeInstructions: {
                    ChallengeType.blink: 'Blink your eyes slowly',
                    ChallengeType.smile: 'Show me your best smile',
                    ChallengeType.turnRight: 'Turn your head to the right side',
                  },
                );
                _navigateToLivenessScreen(
                    context, customConfig, const LivenessTheme());
              },
            ),
            _buildExampleButton(
              context,
              'Material Design',
              'Theme based on Material Design',
              () {
                final materialTheme = LivenessTheme.fromMaterialColor(
                  Colors.teal,
                  brightness: Brightness.dark,
                );
                _navigateToLivenessScreen(
                    context, const LivenessConfig(), materialTheme);
              },
            ),
            _buildExampleButton(
              context,
              'Capture User Image',
              'Take a photo after successful verification',
              () => _navigateToLivenessWithImageCapture(context),
            ),
            _buildExampleButton(
              context,
              'Custom Configuration',
              'Modified thresholds and settings',
              () {
                const customConfig = LivenessConfig(
                  maxSessionDuration: Duration(minutes: 3),
                  eyeBlinkThresholdOpen: 0.8,
                  eyeBlinkThresholdClosed: 0.2,
                  smileThresholdSmiling: 0.8,
                  headTurnThreshold: 15.0,
                  ovalHeightRatio: 0.7,
                  ovalWidthRatio: 0.8,
                  strokeWidth: 5.0,
                  numberOfRandomChallenges: 2,
                );
                _navigateToLivenessScreen(
                    context, customConfig, const LivenessTheme());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleButton(
    BuildContext context,
    String title,
    String description,
    VoidCallback onPressed,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLivenessScreen(
    BuildContext context,
    LivenessConfig config,
    LivenessTheme theme,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivenessDetectionScreen(
          cameras: cameras,
          config: config,
          theme: theme,
          onChallengeCompleted: (challengeType) {
            log('Challenge completed: $challengeType');
          },
          onLivenessCompleted: (sessionId, isSuccessful, metadata) {
            log('Liveness verification completed:');
            log('Session ID: $sessionId');
            log('Success: $isSuccessful');
          },
        ),
      ),
    );
  }

  void _navigateToLivenessWithImageCapture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivenessDetectionScreen(
          cameras: cameras,
          config: const LivenessConfig(
            alwaysIncludeBlink: true,
            challengeTypes: [
              ChallengeType.turnLeft,
              ChallengeType.turnRight,
              ChallengeType.blink,
            ],
          ),
          theme: LivenessTheme.fromMaterialColor(
            Colors.blue,
            brightness: Brightness.dark,
          ),
          // Enable single final image capture
          captureFinalImage: true,
          // Show a button for manual capture as well
          showCaptureImageButton: true,
          showStatusIndicators: false,
          showAppBar: false,
          captureButtonText: 'Take Photo',
          // Process the final verification image
          onFinalImageCaptured: (sessionId, imageFile, metadata) {
            log('Final image captured:');
            log('Session ID: $sessionId');
            log('Image path: ${imageFile.path}');
            log('Metadata: $metadata');

            // Show a dialog with the captured image
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Verification Complete'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Session ID: $sessionId'),
                      const SizedBox(height: 8),
                      Text('Image saved to: ${imageFile.path}'),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imageFile.path),
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            log('Error loading image: $error');
                            return const Text('Could not load image preview');
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Challenge count: ${(metadata['challenges'] as List).length}'),
                      Text('Duration: ${metadata['sessionDuration']} ms'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
          // Handle manual capture separately
          onManualImageCaptured: (sessionId, imageFile) {
            log('Manual image captured:');
            log('Session ID: $sessionId');
            log('Image path: ${imageFile.path}');

            if (context.mounted) {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Manual Image Captured'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Session ID: $sessionId'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imageFile.path),
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            log('Error loading image: $error');
                            return const Text('Could not load image preview');
                          },
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
          onLivenessCompleted: (sessionId, isSuccessful, metadata) {
            log('Liveness verification completed:');
            log('Session ID: $sessionId');
            log('Success: $isSuccessful');
          },
        ),
      ),
    );
  }
}
