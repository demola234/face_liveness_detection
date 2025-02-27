import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  final cameras = await availableCameras();

  runApp(FaceLivenessApp(cameras: cameras));
}

class FaceLivenessApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const FaceLivenessApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Liveness Detection',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: LivenessDetectionScreen(cameras: cameras),
    );
  }
}

class AppConstants {
  static const Duration maxSessionDuration = Duration(minutes: 2);

  static const double minFaceSize = 0.15;
  static const double eyeBlinkThresholdOpen = 0.7;
  static const double eyeBlinkThresholdClosed = 0.3;
  static const double smileThresholdNeutral = 0.3;
  static const double smileThresholdSmiling = 0.7;
  static const double headTurnThreshold = 20.0;

  static const double minLightingThreshold = 0.25;

  static const int brightPixelThreshold = 230;
  static const double minBrightPercentage = 0.05;
  static const double maxBrightPercentage = 0.30;

  static const double cameraZoomLevel = 1.5;

  static const int maxMotionReadings = 100;
  static const int maxHeadAngleReadings = 30;
  static const double significantHeadAngleRange = 20.0;
  static const double minDeviceMovementThreshold = 0.5;

  static const double ovalHeightRatio = 0.9;
  static const double ovalWidthRatio = 0.9;
  static const double strokeWidth = 4.0;
  static const double guideMarkerRatio = 0.55;
  static const double guideMarkerInnerRatio = 0.35;
}

enum ChallengeType { blink, turnLeft, turnRight, smile, nod }

enum LivenessState {
  initial,
  centeringFace,
  performingChallenges,
  completed,
}

class Challenge {
  final ChallengeType type;
  bool isCompleted;

  Challenge(this.type, {this.isCompleted = false});

  String get instruction {
    switch (type) {
      case ChallengeType.blink:
        return 'Please blink your eyes slowly';
      case ChallengeType.turnLeft:
        return 'Turn your head to the left';
      case ChallengeType.turnRight:
        return 'Turn your head to the right';
      case ChallengeType.smile:
        return 'Please smile';
      case ChallengeType.nod:
        return 'Nod your head up and down';
    }
  }
}

class LivenessSession {
  final String sessionId;
  final DateTime startTime;
  final List<Challenge> challenges;
  int currentChallengeIndex;
  LivenessState state;

  LivenessSession({
    required this.challenges,
    this.currentChallengeIndex = 0,
    this.state = LivenessState.initial,
  })  : sessionId = const Uuid().v4(),
        startTime = DateTime.now();

  Challenge? get currentChallenge {
    if (currentChallengeIndex < challenges.length) {
      return challenges[currentChallengeIndex];
    }
    return null;
  }

  bool get isComplete =>
      state == LivenessState.completed ||
      (state == LivenessState.performingChallenges &&
          currentChallengeIndex >= challenges.length);

  double getProgressPercentage() {
    switch (state) {
      case LivenessState.initial:
        return 0.0;
      case LivenessState.centeringFace:
        return 0.2;
      case LivenessState.performingChallenges:
        if (challenges.isEmpty) return 0.2;
        double baseProgress = 0.2;
        double challengeProgress = 0.6;
        return baseProgress +
            (challengeProgress * currentChallengeIndex / challenges.length);
      case LivenessState.completed:
        return 1.0;
    }
  }

  static List<Challenge> generateRandomChallenges() {
    final random = math.Random();
    final allChallenges = [
      ChallengeType.blink,
      ChallengeType.turnLeft,
      ChallengeType.turnRight,
      ChallengeType.smile,
      ChallengeType.nod
    ];

    final challenges = [Challenge(ChallengeType.blink)];

    allChallenges.remove(ChallengeType.blink);
    allChallenges.shuffle(random);
    challenges.addAll(allChallenges.take(2).map((type) => Challenge(type)));

    challenges.shuffle(random);

    return challenges;
  }

  LivenessSession reset() {
    return LivenessSession(
      challenges: LivenessSession.generateRandomChallenges(),
    );
  }

  bool isExpired(Duration maxDuration) {
    return DateTime.now().difference(startTime) > maxDuration;
  }
}

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;

  double _lightingValue = 0.0;
  bool _isLightingGood = true;

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
          final minZoom = await _controller!.getMinZoomLevel();
          final maxZoom = await _controller!.getMaxZoomLevel();

          if (maxZoom > 1.0) {
            double targetZoom = math.min(AppConstants.cameraZoomLevel, maxZoom);
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

  void calculateLightingCondition(CameraImage image) {
    final Uint8List yPlane = image.planes[0].bytes;

    int totalBrightness = 0;
    for (int i = 0; i < yPlane.length; i++) {
      totalBrightness += yPlane[i];
    }

    final double avgBrightness = totalBrightness / yPlane.length;

    _lightingValue = avgBrightness / 255;

    _isLightingGood = _lightingValue > AppConstants.minLightingThreshold;
  }

  bool detectScreenGlare(CameraImage image) {
    final yPlane = image.planes[0].bytes;

    int brightPixels = 0;
    int totalPixels = yPlane.length;

    for (int i = 0; i < totalPixels; i++) {
      if (yPlane[i] > AppConstants.brightPixelThreshold) {
        brightPixels++;
      }
    }

    double brightPercent = brightPixels / totalPixels;

    return brightPercent > AppConstants.minBrightPercentage &&
        brightPercent < AppConstants.maxBrightPercentage;
  }

  bool get isInitialized => _isInitialized && _controller != null;
  bool get isLightingGood => _isLightingGood;
  double get lightingValue => _lightingValue;
  CameraController? get controller => _controller;

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}

class FaceDetectionService {
  late FaceDetector _faceDetector;
  bool _isProcessingImage = false;

  double? _lastEyeOpenProbability;
  double? _lastSmileProbability;
  bool _isFaceCentered = false;
  double? _lastHeadEulerAngleX;
  final List<double> _headAngleReadings = [];

  FaceDetectionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: AppConstants.minFaceSize,
      ),
    );
  }

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

  bool _detectLeftTurn(Face face) {
    if (face.headEulerAngleY != null) {
      _storeHeadAngle(face.headEulerAngleY!);
      return face.headEulerAngleY! < -AppConstants.headTurnThreshold;
    }
    return false;
  }

  bool _detectRightTurn(Face face) {
    if (face.headEulerAngleY != null) {
      _storeHeadAngle(face.headEulerAngleY!);
      return face.headEulerAngleY! > AppConstants.headTurnThreshold;
    }
    return false;
  }

  bool _detectBlink(Face face) {
    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      final double avgEyeOpenProbability =
          (face.leftEyeOpenProbability! + face.rightEyeOpenProbability!) / 2;

      if (_lastEyeOpenProbability != null) {
        if (_lastEyeOpenProbability! > AppConstants.eyeBlinkThresholdOpen &&
            avgEyeOpenProbability < AppConstants.eyeBlinkThresholdClosed) {
          _lastEyeOpenProbability = avgEyeOpenProbability;
          return true;
        }
      }

      _lastEyeOpenProbability = avgEyeOpenProbability;
    }
    return false;
  }

  bool _detectSmile(Face face) {
    if (face.smilingProbability != null) {
      final smileProbability = face.smilingProbability!;

      if (_lastSmileProbability != null) {
        if (_lastSmileProbability! < AppConstants.smileThresholdNeutral &&
            smileProbability > AppConstants.smileThresholdSmiling) {
          _lastSmileProbability = smileProbability;
          return true;
        }
      }

      _lastSmileProbability = smileProbability;
    }
    return false;
  }

  bool _detectNod(Face face) {
    if (face.headEulerAngleX != null) {
      final headAngleX = face.headEulerAngleX!;
      print('Nod angle: $headAngleX');

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

  void _storeHeadAngle(double angle) {
    _headAngleReadings.add(angle);
    if (_headAngleReadings.length > AppConstants.maxHeadAngleReadings) {
      _headAngleReadings.removeAt(0);
    }
  }

  List<double> get headAngleReadings => _headAngleReadings;

  bool get isFaceCentered => _isFaceCentered;

  void resetTracking() {
    _lastEyeOpenProbability = null;
    _lastSmileProbability = null;
    _lastHeadEulerAngleX = null;
    _headAngleReadings.clear();
    _isFaceCentered = false;
  }

  void dispose() {
    _faceDetector.close();
  }
}

class MotionService {
  final List<AccelerometerEvent> _accelerometerReadings = [];
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  void startAccelerometerTracking() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerReadings.add(event);
      if (_accelerometerReadings.length > AppConstants.maxMotionReadings) {
        _accelerometerReadings.removeAt(0);
      }
    });
  }

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

    return !(headAngleRange > AppConstants.significantHeadAngleRange &&
        deviceAngleRange < AppConstants.minDeviceMovementThreshold);
  }

  void resetTracking() {
    _accelerometerReadings.clear();
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
  }
}

class LivenessController extends ChangeNotifier {
  final CameraService _cameraService;
  final FaceDetectionService _faceDetectionService;
  final MotionService _motionService;
  final List<CameraDescription> _cameras;

  LivenessSession _session;
  String _faceCenteringMessage = '';
  bool _isFaceDetected = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing...';

  LivenessController({
    required List<CameraDescription> cameras,
    CameraService? cameraService,
    FaceDetectionService? faceDetectionService,
    MotionService? motionService,
  })  : _cameras = cameras,
        _cameraService = cameraService ?? CameraService(),
        _faceDetectionService = faceDetectionService ?? FaceDetectionService(),
        _motionService = motionService ?? MotionService(),
        _session = LivenessSession(
          challenges: LivenessSession.generateRandomChallenges(),
        ) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _cameraService.initialize(_cameras);
      _motionService.startAccelerometerTracking();

      _cameraService.controller?.startImageStream(_processCameraImage);

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing liveness controller: $e');
      _statusMessage = 'Error initializing camera: $e';
      notifyListeners();
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !_cameraService.isInitialized) return;

    _isProcessing = true;

    try {
      if (_session.isExpired(AppConstants.maxSessionDuration)) {
        _session = _session.reset();
        _faceDetectionService.resetTracking();
        _motionService.resetTracking();
        notifyListeners();
        _isProcessing = false;
        return;
      }

      _cameraService.calculateLightingCondition(image);

      final hasScreenGlare = _cameraService.detectScreenGlare(image);
      if (hasScreenGlare) {
        debugPrint(
            'Detected potential screen glare, possible spoofing attempt');
      }

      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      final faces = await _faceDetectionService.processImage(image, camera);

      if (faces.isNotEmpty) {
        final face = faces.first;
        _isFaceDetected = true;

        final screenSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );

        bool isCentered =
            _faceDetectionService.checkFaceCentering(face, screenSize);

        _updateFaceCenteringGuidance(face, screenSize);

        if (_session.state == LivenessState.centeringFace && isCentered) {
          _processLivenessDetection(face);
        } else if (_session.state != LivenessState.centeringFace) {
          _processLivenessDetection(face);
        }
      } else {
        _isFaceDetected = false;
        _faceCenteringMessage = 'No face detected';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _updateFaceCenteringGuidance(Face face, Size screenSize) {
    final screenCenterX = screenSize.width / 2;
    final screenCenterY = screenSize.height / 2 - screenSize.height * 0.05;

    final faceBox = face.boundingBox;
    final faceCenterX = faceBox.left + faceBox.width / 2;
    final faceCenterY = faceBox.top + faceBox.height / 2;

    final ovalHeight = screenSize.height * 0.55;
    final ovalWidth = ovalHeight * 0.75;
    final faceWidthRatio = faceBox.width / ovalWidth;

    final isHorizontallyOff =
        (faceCenterX - screenCenterX).abs() > screenSize.width * 0.1;
    final isVerticallyOff =
        (faceCenterY - screenCenterY).abs() > screenSize.height * 0.1;
    final isTooBig = faceWidthRatio > 0.9;
    final isTooSmall = faceWidthRatio < 0.5;

    if (isTooBig) {
      _faceCenteringMessage = 'Move farther away';
    } else if (isTooSmall) {
      _faceCenteringMessage = 'Move closer';
    } else if (isHorizontallyOff) {
      if (faceCenterX < screenCenterX) {
        _faceCenteringMessage = 'Move right';
      } else {
        _faceCenteringMessage = 'Move left';
      }
    } else if (isVerticallyOff) {
      if (faceCenterY < screenCenterY) {
        _faceCenteringMessage = 'Move down';
      } else {
        _faceCenteringMessage = 'Move up';
      }
    } else {
      _faceCenteringMessage = 'Perfect! Hold still';
    }
  }

  void _processLivenessDetection(Face face) {
    if (!_cameraService.isLightingGood) {
      _statusMessage = 'Please move to a better lit area';
      return;
    }

    switch (_session.state) {
      case LivenessState.initial:
        _session.state = LivenessState.centeringFace;
        _statusMessage = 'Position your face within the oval';
        break;

      case LivenessState.centeringFace:
        if (_faceDetectionService.isFaceCentered) {
          _session.state = LivenessState.performingChallenges;
          _updateStatusMessage();
        } else {
          _statusMessage = _faceCenteringMessage;
        }
        break;

      case LivenessState.performingChallenges:
        if (_session.currentChallengeIndex >= _session.challenges.length) {
          _session.state = LivenessState.completed;

          bool motionValid = _motionService
              .verifyMotionCorrelation(_faceDetectionService.headAngleReadings);

          if (!motionValid) {
            debugPrint(
                'Potential spoofing detected: Face moved but device didn\'t');
          }

          _statusMessage = 'Liveness verification complete!';
          break;
        }

        final currentChallenge = _session.currentChallenge!;
        bool challengePassed = _faceDetectionService.detectChallengeCompletion(
            face, currentChallenge.type);

        if (challengePassed) {
          currentChallenge.isCompleted = true;
          _session.currentChallengeIndex++;
          _updateStatusMessage();
        }
        break;

      case LivenessState.completed:
        break;
    }
  }

  String get faceCenteringMessage => _faceCenteringMessage;

  void _updateStatusMessage() {
    if (_session.currentChallenge != null) {
      _statusMessage = _session.currentChallenge!.instruction;
    } else {
      _statusMessage = 'Processing verification...';
    }
  }

  void resetSession() {
    _session = _session.reset();
    _faceDetectionService.resetTracking();
    _motionService.resetTracking();
    _statusMessage = 'Initializing...';
    notifyListeners();
  }

  bool get isInitialized => _cameraService.isInitialized;
  bool get isFaceDetected => _isFaceDetected;
  bool get isLightingGood => _cameraService.isLightingGood;
  String get statusMessage => _statusMessage;
  LivenessState get currentState => _session.state;
  double get progress => _session.getProgressPercentage();
  String get sessionId => _session.sessionId;
  CameraController? get cameraController => _cameraService.controller;

  @override
  void dispose() {
    _cameraService.dispose();
    _faceDetectionService.dispose();
    _motionService.dispose();
    super.dispose();
  }
}

class OvalOverlayPainter extends CustomPainter {
  final bool isFaceDetected;
  final Color ovalColor;
  final double strokeWidth;

  OvalOverlayPainter({
    this.isFaceDetected = false,
    this.ovalColor = const Color(0xFF8A8DDF),
    this.strokeWidth = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.height * 0.05);

    final ovalHeight = size.height * 0.55;
    final ovalWidth = ovalHeight * 0.75;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = ovalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawOval(ovalRect, borderPaint);

    /*
    canvas.drawLine(
      Offset(center.dx, center.dy - ovalHeight * AppConstants.guideMarkerRatio),
      Offset(center.dx, center.dy - ovalHeight * AppConstants.guideMarkerInnerRatio),
      borderPaint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy + ovalHeight * AppConstants.guideMarkerRatio),
      Offset(center.dx, center.dy + ovalHeight * AppConstants.guideMarkerInnerRatio),
      borderPaint,
    );
    */
  }

  @override
  bool shouldRepaint(OvalOverlayPainter oldDelegate) =>
      oldDelegate.isFaceDetected != isFaceDetected ||
      oldDelegate.ovalColor != ovalColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

class InstructionOverlay extends StatelessWidget {
  final String instruction;

  const InstructionOverlay({
    super.key,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        instruction,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class LivenessDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const LivenessDetectionScreen({
    super.key,
    required this.cameras,
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
    _controller = LivenessController(cameras: widget.cameras);
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _controller = LivenessController(cameras: widget.cameras);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const _LivenessDetectionView(),
    );
  }
}

class _LivenessDetectionView extends StatelessWidget {
  const _LivenessDetectionView();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LivenessController>(context);
    final mediaQuery = MediaQuery.of(context);

    if (!controller.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing camera...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Face Liveness Detection'),
        backgroundColor: Colors.black38,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.resetSession,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildCameraPreview(controller),
                CustomPaint(
                  size: Size.infinite,
                  painter: OvalOverlayPainter(
                    isFaceDetected: controller.isFaceDetected,
                  ),
                ),
                Positioned(
                  top: 100,
                  right: 20,
                  child: StatusIndicator(
                    isActive: controller.isFaceDetected,
                    activeIcon: Icons.face,
                    inactiveIcon: Icons.face_retouching_off,
                    activeColor: Colors.green,
                    inactiveColor: Colors.red,
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 20,
                  child: StatusIndicator(
                    isActive: controller.isLightingGood,
                    activeIcon: Icons.light_mode,
                    inactiveIcon: Icons.light_mode_outlined,
                    activeColor: Colors.green,
                    inactiveColor: Colors.orange,
                  ),
                ),
                Positioned(
                  top: mediaQuery.padding.top + kToolbarHeight + 20,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: InstructionOverlay(
                      instruction: controller.statusMessage,
                    ),
                  ),
                ),
                if (controller.currentState == LivenessState.centeringFace)
                  Positioned(
                    bottom: 100 + mediaQuery.padding.bottom,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Text(
                        controller.faceCenteringMessage,
                        style: const TextStyle(
                          color: Color(0xFF2E38B7),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 40 + mediaQuery.padding.bottom,
                  left: 20,
                  right: 20,
                  child: LivenessProgressBar(
                    progress: controller.progress,
                  ),
                ),
                if (controller.currentState == LivenessState.completed)
                  SuccessOverlay(
                    sessionId: controller.sessionId,
                    onReset: controller.resetSession,
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

class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color activeColor;
  final Color inactiveColor;

  const StatusIndicator({
    super.key,
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withOpacity(0.7)
            : inactiveColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        isActive ? activeIcon : inactiveIcon,
        color: Colors.white,
      ),
    );
  }
}

class LivenessProgressBar extends StatelessWidget {
  final double progress;

  const LivenessProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey.withOpacity(0.5),
      valueColor: AlwaysStoppedAnimation<Color>(
        progress == 1.0 ? Colors.green : Colors.blue,
      ),
      minHeight: 10,
    );
  }
}

class SuccessOverlay extends StatelessWidget {
  final String sessionId;
  final VoidCallback onReset;

  const SuccessOverlay({
    super.key,
    required this.sessionId,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Verification Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session ID: ${sessionId.substring(0, 8)}...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: onReset,
              child: const Text('Start Again'),
            ),
          ],
        ),
      ),
    );
  }
}
