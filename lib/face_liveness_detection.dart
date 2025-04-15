library smart_liveness_detection;

// Configuration
export 'src/config/app_config.dart';
export 'src/config/theme_config.dart';
// Controllers
export 'src/controllers/liveness_controller.dart';
// Models
export 'src/models/challenge.dart';
export 'src/models/liveness_session.dart';
// Utilities
export 'src/utils/constants.dart';
// Export public APIs

// Main widgets
export 'src/widgets/liveness_detection_screen.dart';

// Callback types
typedef LivenessCompletedCallback = void Function(
    String sessionId, bool isSuccessful, Map<String, dynamic>? metadata);
typedef ChallengeCompletedCallback = void Function(String challengeType);
