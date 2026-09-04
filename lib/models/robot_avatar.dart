/// Central enum representing the 12 Smart Homz / HASOMI robot avatar expressions.
enum RobotAvatarType {
  neutral,
  happy,
  excited,
  thinking,
  listening,
  speaking,
  alert,
  concerned,
  confident,
  pointing,
  sleep,
  success,
}

/// Extension providing centralized getters for asset paths, storage IDs, labels, and descriptions.
extension RobotAvatarTypeX on RobotAvatarType {
  /// Stable storage identifier for preferences and serialization.
  String get storageId {
    switch (this) {
      case RobotAvatarType.neutral:
        return 'robot_neutral';
      case RobotAvatarType.happy:
        return 'robot_happy';
      case RobotAvatarType.excited:
        return 'robot_excited';
      case RobotAvatarType.thinking:
        return 'robot_thinking';
      case RobotAvatarType.listening:
        return 'robot_listening';
      case RobotAvatarType.speaking:
        return 'robot_speaking';
      case RobotAvatarType.alert:
        return 'robot_alert';
      case RobotAvatarType.concerned:
        return 'robot_concerned';
      case RobotAvatarType.confident:
        return 'robot_confident';
      case RobotAvatarType.pointing:
        return 'robot_pointing';
      case RobotAvatarType.sleep:
        return 'robot_sleep';
      case RobotAvatarType.success:
        return 'robot_success';
    }
  }

  /// Relative asset path for loading the avatar image in Flutter.
  String get assetPath {
    return 'assets/images/robot_avatars/$storageId.png';
  }

  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case RobotAvatarType.neutral:
        return 'Neutral';
      case RobotAvatarType.happy:
        return 'Happy';
      case RobotAvatarType.excited:
        return 'Excited';
      case RobotAvatarType.thinking:
        return 'Thinking';
      case RobotAvatarType.listening:
        return 'Listening';
      case RobotAvatarType.speaking:
        return 'Speaking';
      case RobotAvatarType.alert:
        return 'Alert';
      case RobotAvatarType.concerned:
        return 'Concerned';
      case RobotAvatarType.confident:
        return 'Confident';
      case RobotAvatarType.pointing:
        return 'Guide';
      case RobotAvatarType.sleep:
        return 'Sleep';
      case RobotAvatarType.success:
        return 'Success';
    }
  }

  /// Short descriptive subtitle.
  String get description {
    switch (this) {
      case RobotAvatarType.neutral:
        return 'Default Smart Homz Core';
      case RobotAvatarType.happy:
        return 'Warm & Welcoming';
      case RobotAvatarType.excited:
        return 'Energetic & Ready';
      case RobotAvatarType.thinking:
        return 'Analyzing & Processing';
      case RobotAvatarType.listening:
        return 'Awaiting Voice Commands';
      case RobotAvatarType.speaking:
        return 'Responding & Explaining';
      case RobotAvatarType.alert:
        return 'Safety & Danger Guardian';
      case RobotAvatarType.concerned:
        return 'Issue or Warning Detected';
      case RobotAvatarType.confident:
        return 'All Systems Secure';
      case RobotAvatarType.pointing:
        return 'Navigation & Feature Guide';
      case RobotAvatarType.sleep:
        return 'Standby & Night Mode';
      case RobotAvatarType.success:
        return 'Task Completed';
    }
  }

  /// Accessibility semantic description for screen readers.
  String get semanticLabel {
    return 'HASOMI assistant: $displayName ($description)';
  }

  /// Helper parser to resolve a string ID or legacy key to a valid [RobotAvatarType].
  static RobotAvatarType fromStorageId(String? id) {
    if (id == null || id.isEmpty) {
      return RobotAvatarType.neutral;
    }

    // Legacy fallback mapping
    if (id == 'smart_robot') {
      return RobotAvatarType.neutral;
    }
    if (id == 'new_robot') return RobotAvatarType.happy;
    if (id == 'fire_safety' || id == 'fire_assistant') {
      return RobotAvatarType.alert;
    }
    if (id == 'water_robot' || id == 'water_assistant') {
      return RobotAvatarType.confident;
    }

    for (final type in RobotAvatarType.values) {
      if (type.storageId == id || type.name == id) {
        return type;
      }
    }
    return RobotAvatarType.neutral;
  }
}

/// Constant class providing static references to avatar asset paths.
abstract class RobotAvatarAssets {
  static const String neutral = 'assets/images/robot_avatars/robot_neutral.png';
  static const String happy = 'assets/images/robot_avatars/robot_happy.png';
  static const String excited = 'assets/images/robot_avatars/robot_excited.png';
  static const String thinking =
      'assets/images/robot_avatars/robot_thinking.png';
  static const String listening =
      'assets/images/robot_avatars/robot_listening.png';
  static const String speaking =
      'assets/images/robot_avatars/robot_speaking.png';
  static const String alert = 'assets/images/robot_avatars/robot_alert.png';
  static const String concerned =
      'assets/images/robot_avatars/robot_concerned.png';
  static const String confident =
      'assets/images/robot_avatars/robot_confident.png';
  static const String pointing =
      'assets/images/robot_avatars/robot_pointing.png';
  static const String sleep = 'assets/images/robot_avatars/robot_sleep.png';
  static const String success = 'assets/images/robot_avatars/robot_success.png';
}
