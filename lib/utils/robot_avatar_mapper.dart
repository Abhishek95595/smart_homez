import '../models/robot_avatar.dart';
import '../screens/voice/hasomi_screen.dart';
import '../widgets/hasomi_bottom_voice_bar.dart';

/// Central mapping utility connecting application & voice assistant states to [RobotAvatarType].
abstract class RobotAvatarMapper {
  /// Maps [HasomiState] from HASOMI voice screen to the appropriate [RobotAvatarType].
  static RobotAvatarType mapHasomiState(
    HasomiState state, {
    bool overallSuccess = true,
    bool isSpeaking = false,
  }) {
    if (isSpeaking) {
      return RobotAvatarType.speaking;
    }

    switch (state) {
      case HasomiState.ready:
        return RobotAvatarType.neutral;
      case HasomiState.listeningForWakeWord:
        return RobotAvatarType.listening;
      case HasomiState.wakeWordDetected:
        return RobotAvatarType.happy;
      case HasomiState.listeningForCommand:
        return RobotAvatarType.listening;
      case HasomiState.controllingDevices:
        return RobotAvatarType.thinking;
      case HasomiState.displayResult:
        return overallSuccess
            ? RobotAvatarType.success
            : RobotAvatarType.concerned;
    }
  }

  /// Maps [HasomiVoiceBarState] from bottom voice bar to the appropriate [RobotAvatarType].
  static RobotAvatarType mapVoiceBarState(
    HasomiVoiceBarState state, {
    bool isSpeaking = false,
  }) {
    if (isSpeaking) {
      return RobotAvatarType.speaking;
    }

    switch (state) {
      case HasomiVoiceBarState.idle:
        return RobotAvatarType.neutral;
      case HasomiVoiceBarState.listeningForWakeWord:
        return RobotAvatarType.listening;
      case HasomiVoiceBarState.wakeWordDetected:
        return RobotAvatarType.happy;
      case HasomiVoiceBarState.listeningForCommand:
        return RobotAvatarType.listening;
      case HasomiVoiceBarState.processing:
      case HasomiVoiceBarState.controlling:
        return RobotAvatarType.thinking;
      case HasomiVoiceBarState.success:
        return RobotAvatarType.success;
      case HasomiVoiceBarState.error:
        return RobotAvatarType.concerned;
    }
  }

  /// Maps safety alert count and severity string to the appropriate [RobotAvatarType].
  static RobotAvatarType mapAlertSeverity({
    required int activeAlertCount,
    String? maxSeverity,
  }) {
    if (activeAlertCount == 0) {
      return RobotAvatarType.confident;
    }

    final String sev = maxSeverity?.toUpperCase() ?? '';
    if (sev == 'CRITICAL' || sev == 'HIGH' || sev == 'EMERGENCY') {
      return RobotAvatarType.alert;
    }

    if (sev == 'WARNING' || sev == 'MEDIUM' || sev == 'FAULT') {
      return RobotAvatarType.concerned;
    }

    return RobotAvatarType.neutral;
  }
}
