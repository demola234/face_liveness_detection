# Face Liveness Detection

A highly customizable Flutter package for face liveness detection with multiple challenge types. This package helps you verify that a real person is present in front of the camera, not a photo, video, or mask.

## Features

- 💯 Multiple liveness challenge types (blinking, smiling, head turns, nodding)
- 🔄 Random challenge sequence generation for enhanced security
- 🎯 Face centering guidance with visual feedback
- 🔍 Anti-spoofing measures (screen glare detection, motion correlation)
- 🎨 Fully customizable UI with theming support
- 🌈 Animated progress indicators, status displays, and overlays
- 📱 Simple integration with Flutter apps
- 📸 Optional image capture capability

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  smart_liveliness_detection: ^0.0.1-beta.6
```

Then run:

```
flutter pub get
```

Make sure to add camera permissions to your app:

### iOS

Add the following to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face liveness verification</string>
```

### Android

Add the following to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## Quick Start

Here's how to quickly integrate face liveness detection into your app:

```dart
import 'package:camera/camera.dart';
import 'package:smart_liveliness_detection/smart_liveliness_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/developer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get available cameras
  final cameras = await availableCameras();

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Liveness Detection')),
        body: LivenessDetectionScreen(
          cameras: cameras,
          onLivenessCompleted: (sessionId, isSuccessful) {
            log('Liveness verification completed: $isSuccessful');
            log('Session ID: $sessionId');
          },
        ),
      ),
    );
  }
}
```

## Customization

### Configuration

Customize the detection settings using `LivenessConfig`:

```dart
LivenessConfig config = LivenessConfig(
  // Challenge configuration
  challengeTypes: [ChallengeType.blink, ChallengeType.smile, ChallengeType.turnRight],
  numberOfRandomChallenges: 3,
  alwaysIncludeBlink: true,

  // Custom instructions
  challengeInstructions: {
    ChallengeType.blink: 'Please blink your eyes now',
    ChallengeType.smile: 'Show us your best smile',
  },

  // Detection thresholds
  eyeBlinkThresholdOpen: 0.7,
  eyeBlinkThresholdClosed: 0.3,
  smileThresholdNeutral: 0.3,
  smileThresholdSmiling: 0.7,
  headTurnThreshold: 20.0,

  // UI configuration
  ovalHeightRatio: 0.9,
  ovalWidthRatio: 0.9,
  strokeWidth: 4.0,

  // Session settings
  maxSessionDuration: Duration(minutes: 2),
);
```

### Theming

Customize the appearance using `LivenessTheme`:

```dart
LivenessTheme theme = LivenessTheme(
  // Colors
  primaryColor: Colors.blue,
  successColor: Colors.green,
  errorColor: Colors.red,
  warningColor: Colors.orange,
  ovalGuideColor: Colors.purple,

  // Text styles
  instructionTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  guidanceTextStyle: TextStyle(
    color: Colors.blue,
    fontSize: 16,
  ),

  // Progress indicator
  progressIndicatorColor: Colors.blue,
  progressIndicatorHeight: 12,

  // Animation
  useOvalPulseAnimation: true,
);
```

Or use a theme based on Material Design:

```dart
LivenessTheme theme = LivenessTheme.fromMaterialColor(
  Colors.teal,
  brightness: Brightness.dark,
);
```

### Callbacks

Get notified about challenges and session completion:

```dart
LivenessDetectionScreen(
  cameras: cameras,
  config: config,
  theme: theme,
  onChallengeCompleted: (challengeType) {
    log('Challenge completed: $challengeType');
  },
  onLivenessCompleted: (sessionId, isSuccessful) {
    log('Liveness verification completed:');
    log('Session ID: $sessionId');
    log('Success: $isSuccessful');

    // You can now send this session ID to your backend
    // for verification or proceed with your app flow
  },
);
```

### Custom UI Elements

Customize the UI with your own components:

```dart
LivenessDetectionScreen(
  cameras: cameras,
  showAppBar: false, // Hide default app bar
  customAppBar: AppBar(
    title: const Text('My Custom Verification'),
    backgroundColor: Colors.transparent,
  ),
  customSuccessOverlay: MyCustomSuccessWidget(),
);
```

### Image Capture

Enable capturing the user's image after successful verification:

```dart
LivenessDetectionScreen(
  cameras: cameras,
  showCaptureImageButton: true,
  captureButtonText: 'Take Photo',
  onImageCaptured: (sessionId, imageFile) {
    // imageFile is an XFile that contains the captured image
    log('Image saved to: ${imageFile.path}');

    // You can now:
    // 1. Display the image
    // 2. Upload it to your server
    // 3. Store it locally
    // 4. Process it further
  },
);
```

## Advanced Usage

### Embedding in Custom UI

You can incorporate the liveness detection into a larger flow:

```dart
class VerificationFlow extends StatefulWidget {
  @override
  _VerificationFlowState createState() => _VerificationFlowState();
}

class _VerificationFlowState extends State<VerificationFlow> {
  int _currentStep = 0;
  String? _sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentStep,
        children: [
          // Step 1: Instructions
          InstructionScreen(
            onContinue: () => setState(() => _currentStep = 1),
          ),

          // Step 2: Liveness Detection
          LivenessDetectionScreen(
            cameras: cameras,
            onLivenessCompleted: (sessionId, isSuccessful) {
              if (isSuccessful) {
                setState(() {
                  _sessionId = sessionId;
                  _currentStep = 2;
                });
              }
            },
          ),

          // Step 3: Verification Complete
          VerificationCompleteScreen(
            sessionId: _sessionId,
            onContinue: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
```

### Direct Controller Access

For even more control, you can use the controller directly:

```dart
class CustomLivenessScreen extends StatefulWidget {
  @override
  _CustomLivenessScreenState createState() => _CustomLivenessScreenState();
}

class _CustomLivenessScreenState extends State<CustomLivenessScreen> {
  late LivenessController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LivenessController(
      cameras: cameras,
      config: LivenessConfig(...),
      theme: LivenessTheme(...),
      onLivenessCompleted: (sessionId, isSuccessful) {
        // Handle completion
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<LivenessController>(
        builder: (context, controller, _) {
          return Scaffold(
            body: Stack(
              children: [
                // Your custom UI...

                if (controller.currentState == LivenessState.completed)
                  // Show success UI
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## Available Challenge Types

- `ChallengeType.blink` - Verify that the user can blink
- `ChallengeType.turnLeft` - Verify that the user can turn their head left
- `ChallengeType.turnRight` - Verify that the user can turn their head right
- `ChallengeType.smile` - Verify that the user can smile
- `ChallengeType.nod` - Verify that the user can nod their head

## Anti-Spoofing Measures

This package implements several anti-spoofing measures:

1. **Challenge randomization** - Unpredictable sequence of actions
2. **Screen glare detection** - Detects presentation attacks using screens
3. **Motion correlation** - Ensures device movement correlates with head movement
4. **Timing validation** - Ensures challenges are completed within reasonable times

## Contributing

Contributions are welcome! Feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
