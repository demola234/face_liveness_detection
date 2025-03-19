library face_liveness_detection;

// Export public APIs

// Main widgets
export 'src/widgets/liveness_detection_screen.dart';

// Models
export 'src/models/challenge.dart';
export 'src/models/liveness_session.dart';

// Configuration
export 'src/config/app_config.dart';
export 'src/config/theme_config.dart';

// Controllers
export 'src/controllers/liveness_controller.dart';

// Utilities
export 'src/utils/constants.dart';

// Callback types
typedef LivenessCompletedCallback = void Function(String sessionId, bool isSuccessful);
typedef ChallengeCompletedCallback = void Function(String challengeType);