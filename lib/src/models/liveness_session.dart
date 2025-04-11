import 'dart:math' as math;

import 'package:face_liveness_detection/src/utils/enums.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import 'challenge.dart';

/// Represents a liveness detection session
class LivenessSession {
  /// Unique identifier for this session
  final String sessionId;
  
  /// Time when the session started
  final DateTime startTime;
  
  /// List of challenges to complete
  final List<Challenge> challenges;
  
  /// Index of the current challenge
  int currentChallengeIndex;
  
  /// Current state of the liveness detection process
  LivenessState state;
  
  /// Any custom data associated with this session
  final Map<String, dynamic>? metadata;

  LivenessSession({
    required this.challenges,
    this.currentChallengeIndex = 0,
    this.state = LivenessState.initial,
    String? sessionId,
    DateTime? startTime,
    this.metadata,
  })  : sessionId = sessionId ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now();

  /// Get the current challenge, if any
  Challenge? get currentChallenge {
    if (currentChallengeIndex < challenges.length) {
      return challenges[currentChallengeIndex];
    }
    return null;
  }

  /// Whether all challenges have been completed
  bool get isComplete =>
      state == LivenessState.completed ||
      (state == LivenessState.performingChallenges &&
          currentChallengeIndex >= challenges.length);

  /// Get the progress as a percentage (0.0-1.0)
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

  /// Generate random challenges based on configuration
  static List<Challenge> generateRandomChallenges(LivenessConfig config) {
    // If specific challenge types are provided, use those
    if (config.challengeTypes != null && config.challengeTypes!.isNotEmpty) {
      return config.challengeTypes!.map((type) {
        String? customInstruction = config.challengeInstructions?[type];
        return Challenge(type, customInstruction: customInstruction);
      }).toList();
    }

    // Otherwise generate random challenges
    final random = math.Random();
    final allChallenges = [
      ChallengeType.blink,
      ChallengeType.turnLeft,
      ChallengeType.turnRight,
      ChallengeType.smile,
      ChallengeType.nod
    ];

    final List<Challenge> challenges = [];
    
    // Always include blink challenge if configured
    if (config.alwaysIncludeBlink) {
      String? customInstruction = config.challengeInstructions?[ChallengeType.blink];
      challenges.add(Challenge(ChallengeType.blink, customInstruction: customInstruction));
      allChallenges.remove(ChallengeType.blink);
    }

    // Add random challenges
    allChallenges.shuffle(random);
    final int remainingChallenges = config.alwaysIncludeBlink 
        ? config.numberOfRandomChallenges - 1 
        : config.numberOfRandomChallenges;
        
    challenges.addAll(
      allChallenges
        .take(remainingChallenges)
        .map((type) {
          String? customInstruction = config.challengeInstructions?[type];
          return Challenge(type, customInstruction: customInstruction);
        })
    );

    // Shuffle the challenges if blink isn't first
    if (!config.alwaysIncludeBlink || challenges.first.type != ChallengeType.blink) {
      challenges.shuffle(random);
    }

    return challenges;
  }

  /// Create a new session with the same configuration
  LivenessSession reset(LivenessConfig config) {
    return LivenessSession(
      challenges: LivenessSession.generateRandomChallenges(config),
      metadata: metadata,
    );
  }

  /// Check if the session has expired
  bool isExpired(Duration maxDuration) {
    return DateTime.now().difference(startTime) > maxDuration;
  }
  
  /// Create a copy of this session with some values replaced
  LivenessSession copyWith({
    String? sessionId,
    DateTime? startTime,
    List<Challenge>? challenges,
    int? currentChallengeIndex,
    LivenessState? state,
    Map<String, dynamic>? metadata,
  }) {
    return LivenessSession(
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      challenges: challenges ?? this.challenges,
      currentChallengeIndex: currentChallengeIndex ?? this.currentChallengeIndex,
      state: state ?? this.state,
      metadata: metadata ?? this.metadata,
    );
  }
}