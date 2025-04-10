import 'package:camera/camera.dart';
import 'package:face_liveness_detection/face_liveness_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            print('Challenge completed: $challengeType');
          },
          onLivenessCompleted: (sessionId, isSuccessful, metadata) {
            print('Liveness verification completed:');
            print('Session ID: $sessionId');
            print('Success: $isSuccessful');
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
            numberOfRandomChallenges: 2,
          ),
          theme: LivenessTheme.fromMaterialColor(
            Colors.blue,
            brightness: Brightness.dark,
          ),
          showCaptureImageButton: true,
          showStatusIndicators: false,
          showAppBar: false,
          captureButtonText: 'Take Photo',
          onImageCaptured: (sessionId, imageFile) {
            // Show a dialog with the captured image
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Image Captured'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Session ID: $sessionId'),
                    const SizedBox(height: 8),
                    Text('Image saved to: ${imageFile.path}'),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        imageFile.path,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Could not load image preview'),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          onLivenessCompleted: (sessionId, isSuccessful, metadata) {
            print('Liveness verification completed:');
            print('Session ID: $sessionId');
            print('Success: $isSuccessful');
          },
        ),
      ),
    );
  }
}
