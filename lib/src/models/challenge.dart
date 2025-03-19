import '../utils/constants.dart';

/// Represents a liveness detection challenge that the user must complete
class Challenge {
  /// The type of challenge
  final ChallengeType type;
  
  /// Whether the challenge has been completed
  bool isCompleted;
  
  /// Custom instruction text (overrides default)
  final String? customInstruction;
  
  /// Map of default challenge instructions
  static final Map<ChallengeType, String> _defaultInstructions = {
    ChallengeType.blink: 'Please blink your eyes slowly',
    ChallengeType.turnLeft: 'Turn your head to the left',
    ChallengeType.turnRight: 'Turn your head to the right',
    ChallengeType.smile: 'Please smile',
    ChallengeType.nod: 'Nod your head up and down',
  };

  Challenge(
    this.type, {
    this.isCompleted = false,
    this.customInstruction,
  });

  /// Get the instruction text for this challenge
  String get instruction => customInstruction ?? _defaultInstructions[type]!;
  
  /// Get the default instruction for a challenge type
  static String getDefaultInstruction(ChallengeType type) {
    return _defaultInstructions[type]!;
  }
  
  /// Create a copy of this challenge with some values replaced
  Challenge copyWith({
    ChallengeType? type,
    bool? isCompleted,
    String? customInstruction,
  }) {
    return Challenge(
      type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      customInstruction: customInstruction ?? this.customInstruction,
    );
  }
}