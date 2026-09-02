import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';

enum HasomiAction { turnOn, turnOff, unknown }

class HasomiIntent {
  final HasomiAction action;
  final List<String> roomNames;
  final List<String> deviceTypes;
  final String rawText;

  const HasomiIntent({
    required this.action,
    required this.roomNames,
    required this.deviceTypes,
    required this.rawText,
  });
}

class HasomiDeviceActionResult {
  final Device device;
  final String actionName; // 'on' or 'off'
  final bool success;
  final String? errorMessage;

  const HasomiDeviceActionResult({
    required this.device,
    required this.actionName,
    required this.success,
    this.errorMessage,
  });
}

class HasomiExecutionResult {
  final String userQuery;
  final HasomiIntent intent;
  final List<HasomiDeviceActionResult> actionResults;
  final List<String> notFoundMessages;
  final String spokenResponse;
  final bool overallSuccess;

  const HasomiExecutionResult({
    required this.userQuery,
    required this.intent,
    required this.actionResults,
    required this.notFoundMessages,
    required this.spokenResponse,
    required this.overallSuccess,
  });
}

class HasomiVoiceService {
  HasomiVoiceService._internal();
  static final HasomiVoiceService instance = HasomiVoiceService._internal();

  FlutterTts? _tts;
  bool _ttsInitialized = false;
  Completer<void>? _speakCompleter;

  Future<void> _initTts() async {
    try {
      _tts ??= FlutterTts();

      _tts?.setCompletionHandler(() {
        debugPrint('[HasomiVoiceService TTS Completion Handler Fired]');
        if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
          _speakCompleter!.complete();
        }
      });

      _tts?.setErrorHandler((msg) {
        debugPrint('[HasomiVoiceService TTS Error Handler] $msg');
        if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
          _speakCompleter!.complete();
        }
      });

      _tts?.setCancelHandler(() {
        debugPrint('[HasomiVoiceService TTS Cancel Handler]');
        if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
          _speakCompleter!.complete();
        }
      });

      // Try setting Indian English voice locale ('en-IN')
      final dynamic isIndianAvailable = await _tts?.isLanguageAvailable(
        "en-IN",
      );
      if (isIndianAvailable == true || isIndianAvailable == 1) {
        await _tts?.setLanguage("en-IN");
      } else {
        await _tts?.setLanguage("en-US");
      }

      // Scan system voices for an Indian accent voice (en-IN)
      try {
        final dynamic voices = await _tts?.getVoices;
        if (voices is List) {
          for (final voice in voices) {
            if (voice is Map) {
              final String locale = (voice['locale'] ?? '')
                  .toString()
                  .toLowerCase();
              final String name = (voice['name'] ?? '')
                  .toString()
                  .toLowerCase();
              if (locale.contains('en-in') ||
                  locale.contains('en_in') ||
                  name.contains('india') ||
                  name.contains('en-in')) {
                await _tts?.setVoice({
                  "name": voice['name'],
                  "locale": voice['locale'],
                });
                debugPrint(
                  '[HasomiVoiceService Selected Indian Voice] ${voice['name']} (${voice['locale']})',
                );
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[HasomiVoiceService Voice Scan Error] $e');
      }

      await _tts?.setSpeechRate(0.48);
      await _tts?.setVolume(1.0);
      await _tts?.setPitch(1.0);
      await _tts?.awaitSpeakCompletion(true);
      _ttsInitialized = true;
    } catch (e) {
      debugPrint('[HasomiVoiceService TTS Init Error] $e');
    }
  }

  /// Speaks out loud using the device's Text-to-Speech engine and awaits completion.
  Future<void> speak(String text) async {
    final String cleanText = text.trim();
    if (cleanText.isEmpty) return;
    try {
      if (!_ttsInitialized || _tts == null) {
        await _initTts();
      }
      await _tts?.stop();
      if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
        _speakCompleter!.complete();
      }
      _speakCompleter = Completer<void>();

      debugPrint('[HasomiVoiceService Speaking Aloud] "$cleanText"');
      final dynamic result = await _tts?.speak(cleanText);
      debugPrint('[HasomiVoiceService Speak Result] $result');

      // Fallback timeout in case platform TTS doesn't trigger completion callback
      final int wordCount = cleanText.split(RegExp(r'\s+')).length;
      final int estimatedMs = math.max(2500, wordCount * 350 + 1500);

      Future.delayed(Duration(milliseconds: estimatedMs), () {
        if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
          debugPrint('[HasomiVoiceService TTS Fallback Timeout Fired]');
          _speakCompleter!.complete();
        }
      });

      await _speakCompleter!.future;
    } catch (e) {
      debugPrint('[HasomiVoiceService Speak Exception] $e');
    }
  }

  /// Stops TTS voice playback if active.
  Future<void> stopSpeaking() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  /// Checks if the speech input contains the wake word phrase ("Hey HASOMI" or "HASOMI").
  bool isWakeWordDetected(String input) {
    final String lower = input.trim().toLowerCase();
    return lower.contains('hey hasomi') ||
        lower.contains('hasomi') ||
        lower.contains('hey hazomi') ||
        lower.contains('hazomi') ||
        lower.contains('hey hasomi.') ||
        lower.contains('hey, hasomi');
  }

  /// Removes the wake word prefix/phrases from user speech so command parsing receives clean intent text.
  String stripWakeWord(String input) {
    String clean = input.trim();
    final RegExp regex = RegExp(
      r'^(hey\s+)?(hasomi|hazomi)[\s,.]*',
      caseSensitive: false,
    );
    clean = clean.replaceFirst(regex, '').trim();
    if (clean.isEmpty && isWakeWordDetected(input)) {
      return '';
    }
    return clean;
  }

  /// Formats the wake-word greeting dynamically using the logged in user's profile name.
  String generateGreeting(String? userFullName) {
    final String cleanName = userFullName?.trim() ?? '';
    final String firstName = cleanName.split(' ').first;
    final String displayName =
        (firstName.isNotEmpty && !firstName.toLowerCase().contains('otp'))
            ? firstName
            : 'Friend';
    return 'Hi $displayName, what can I help you with?';
  }

  /// Parses natural language input into a structured HasomiIntent.
  HasomiIntent parseCommand(String text, List<Device> availableDevices) {
    final String input = text.trim().toLowerCase();

    // 1. Determine Action (ON / OFF)
    HasomiAction action = HasomiAction.unknown;
    final bool isOffCommand =
        input.contains('off') ||
        input.contains('switch off') ||
        input.contains('turn off') ||
        input.contains('shutdown') ||
        input.contains('disable') ||
        input.contains('stop');

    final bool isOnCommand =
        input.contains('on') ||
        input.contains('switch on') ||
        input.contains('turn on') ||
        input.contains('enable') ||
        input.contains('start');

    if (isOffCommand) {
      action = HasomiAction.turnOff;
    } else if (isOnCommand) {
      action = HasomiAction.turnOn;
    }

    // 2. Extract Room Names
    final Set<String> extractedRooms = <String>{};

    // Extract room names from available devices first
    for (final device in availableDevices) {
      final String roomName = device.roomName ?? device.zone;
      if (roomName.trim().isNotEmpty) {
        final String cleanRoom = roomName.trim().toLowerCase();
        if (input.contains(cleanRoom)) {
          extractedRooms.add(roomName.trim());
        }
      }
    }

    // Check common standard room names if no match from devices
    final Map<String, String> standardRooms = {
      'living room': 'Living Room',
      'livingroom': 'Living Room',
      'drawing room': 'Living Room',
      'bedroom': 'Bedroom',
      'bed room': 'Bedroom',
      'master bedroom': 'Master Bedroom',
      'guest room': 'Guest Room',
      'kitchen': 'Kitchen',
      'dining room': 'Dining Room',
      'dining': 'Dining Room',
      'balcony': 'Balcony',
      'bathroom': 'Bathroom',
      'washroom': 'Bathroom',
      'study': 'Study Room',
      'office': 'Office',
      'hall': 'Hall',
      'garage': 'Garage',
    };

    standardRooms.forEach((key, canonicalName) {
      if (input.contains(key)) {
        extractedRooms.add(canonicalName);
      }
    });

    // 3. Extract Device Types
    final Set<String> extractedDeviceTypes = <String>{};
    final Map<String, String> deviceTypeKeywords = {
      'light': 'light',
      'lights': 'light',
      'lamp': 'light',
      'lamps': 'light',
      'bulb': 'light',
      'bulbs': 'light',
      'tubelight': 'light',
      'fan': 'fan',
      'fans': 'fan',
      'ac': 'ac',
      'air conditioner': 'ac',
      'aircon': 'ac',
      'cooler': 'ac',
      'pump': 'pump',
      'water pump': 'pump',
      'tv': 'tv',
      'television': 'tv',
      'plug': 'plug',
      'switch': 'switch',
    };

    deviceTypeKeywords.forEach((key, canonicalType) {
      if (input.contains(key)) {
        extractedDeviceTypes.add(canonicalType);
      }
    });

    return HasomiIntent(
      action: action,
      roomNames: extractedRooms.toList(),
      deviceTypes: extractedDeviceTypes.toList(),
      rawText: text,
    );
  }

  /// Resolves target devices and executes the API requests asynchronously.
  Future<HasomiExecutionResult> processVoiceCommand({
    required String text,
    required DeviceProvider deviceProvider,
  }) async {
    final List<Device> allDevices = deviceProvider.devices;
    final HasomiIntent intent = parseCommand(text, allDevices);

    final List<HasomiDeviceActionResult> actionResults = [];
    final List<String> notFoundMessages = [];

    if (intent.action == HasomiAction.unknown) {
      return HasomiExecutionResult(
        userQuery: text,
        intent: intent,
        actionResults: const [],
        notFoundMessages: const [],
        spokenResponse:
            "I couldn't understand if you want to turn devices on or off. Please say, for example: 'Turn off the living room light'.",
        overallSuccess: false,
      );
    }

    final String lowerInput = text.trim().toLowerCase();
    final bool turnOn = intent.action == HasomiAction.turnOn;
    final String actionStr = turnOn ? 'on' : 'off';

    final List<Device> matchedDevices = [];

    // Check if command is asking for ALL devices explicitly (e.g. "turn off all lights")
    final bool isAllCommand =
        lowerInput.contains('all lights') ||
        lowerInput.contains('all fans') ||
        lowerInput.contains('all devices') ||
        lowerInput.contains('all the lights');

    if (!isAllCommand) {
      // 1. Use token score matching to find the specific target device (e.g., "Abhishek Dimable Light")
      final List<Device> bestMatches = _findBestDeviceMatches(text, allDevices);
      if (bestMatches.isNotEmpty) {
        matchedDevices.addAll(bestMatches);
      }
    }

    // 2. Fallback to room/device type matching if no specific device name matched or if it's an "all" command
    if (matchedDevices.isEmpty) {
      final List<String> targetRooms = intent.roomNames;
      final List<String> targetDeviceTypes = intent.deviceTypes;

      if (targetRooms.isNotEmpty) {
        for (final room in targetRooms) {
          final List<Device> roomDevices = allDevices.where((d) {
            final String dRoom = (d.roomName ?? d.zone).toLowerCase();
            final String targetR = room.toLowerCase();
            return dRoom.contains(targetR) || targetR.contains(dRoom);
          }).toList();

          if (targetDeviceTypes.isNotEmpty) {
            for (final devType in targetDeviceTypes) {
              final List<Device> typeMatches = roomDevices.where((d) {
                final String dName = d.name.toLowerCase();
                final String dTypeStr = d.type.name.toLowerCase();
                return dName.contains(devType) ||
                    dTypeStr.contains(devType) ||
                    (devType == 'light' &&
                        (dTypeStr == 'light' || dName.contains('light'))) ||
                    (devType == 'fan' &&
                        (dTypeStr == 'fan' || dName.contains('fan'))) ||
                    (devType == 'ac' &&
                        (dTypeStr == 'ac' || dName.contains('ac')));
              }).toList();

              if (typeMatches.isEmpty) {
                notFoundMessages.add(
                  "I couldn't find ${devType == 'ac' ? 'an AC' : 'a $devType'} in the $room.",
                );
              } else {
                matchedDevices.addAll(typeMatches);
              }
            }
          } else {
            matchedDevices.addAll(roomDevices);
          }
        }
      } else if (targetDeviceTypes.isNotEmpty && isAllCommand) {
        // Only turn on/off all devices of a type if user explicitly said "all"
        for (final devType in targetDeviceTypes) {
          final List<Device> typeMatches = allDevices.where((d) {
            final String dName = d.name.toLowerCase();
            final String dTypeStr = d.type.name.toLowerCase();
            return dName.contains(devType) ||
                dTypeStr.contains(devType) ||
                (devType == 'light' &&
                    (dTypeStr == 'light' || dName.contains('light'))) ||
                (devType == 'fan' &&
                    (dTypeStr == 'fan' || dName.contains('fan'))) ||
                (devType == 'ac' && (dTypeStr == 'ac' || dName.contains('ac')));
          }).toList();

          if (typeMatches.isEmpty) {
            notFoundMessages.add(
              "I couldn't find any ${devType == 'ac' ? 'AC' : devType} devices.",
            );
          } else {
            matchedDevices.addAll(typeMatches);
          }
        }
      } else {
        // Specific device requested but not found
        final String requestedName = text
            .replaceAll(
              RegExp(
                r'(turn|switch|on|off|please|the|hasomi|hey)',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
        notFoundMessages.add(
          "I couldn't find a device named '$requestedName'.",
        );
      }
    }

    // Deduplicate matched devices
    final Set<String> seenIds = {};
    final List<Device> uniqueMatchedDevices = matchedDevices.where((d) {
      return seenIds.add(d.deviceId);
    }).toList();

    // If no devices were found at all
    if (uniqueMatchedDevices.isEmpty && notFoundMessages.isNotEmpty) {
      return HasomiExecutionResult(
        userQuery: text,
        intent: intent,
        actionResults: const [],
        notFoundMessages: notFoundMessages,
        spokenResponse: notFoundMessages.first,
        overallSuccess: false,
      );
    }

    // Execute API requests via DeviceProvider for each matched device
    for (final device in uniqueMatchedDevices) {
      try {
        final bool success = await deviceProvider.setDevicePower(
          device,
          turnOn,
        );
        actionResults.add(
          HasomiDeviceActionResult(
            device: device,
            actionName: actionStr,
            success: success,
          ),
        );
      } catch (e) {
        actionResults.add(
          HasomiDeviceActionResult(
            device: device,
            actionName: actionStr,
            success: false,
            errorMessage: e.toString(),
          ),
        );
      }
    }

    // Build Spoken Voice Feedback Response
    final String spokenResponse = _generateSpokenResponse(
      actionResults: actionResults,
      notFoundMessages: notFoundMessages,
      actionStr: actionStr,
      targetRooms: intent.roomNames,
      targetDeviceTypes: intent.deviceTypes,
    );

    final bool overallSuccess = actionResults.any((r) => r.success);

    return HasomiExecutionResult(
      userQuery: text,
      intent: intent,
      actionResults: actionResults,
      notFoundMessages: notFoundMessages,
      spokenResponse: spokenResponse,
      overallSuccess: overallSuccess,
    );
  }

  String _generateSpokenResponse({
    required List<HasomiDeviceActionResult> actionResults,
    required List<String> notFoundMessages,
    required String actionStr,
    required List<String> targetRooms,
    required List<String> targetDeviceTypes,
  }) {
    if (actionResults.isEmpty) {
      if (notFoundMessages.isNotEmpty) return notFoundMessages.first;
      return "No matching devices found.";
    }

    final List<HasomiDeviceActionResult> succeeded = actionResults
        .where((r) => r.success)
        .toList();
    final List<HasomiDeviceActionResult> failed = actionResults
        .where((r) => !r.success)
        .toList();

    // 1. All Succeeded
    if (failed.isEmpty) {
      final List<String> devNames = succeeded
          .map((r) => r.device.name)
          .toSet()
          .toList();
      final String deviceListStr = _formatNameList(devNames);
      final String prefix = targetRooms.isNotEmpty
          ? 'Your ${targetRooms.first}'
          : 'Your';
      return "$prefix $deviceListStr ${devNames.length > 1 ? 'are' : 'is'} $actionStr.";
    }

    // 2. Partial Failure
    if (succeeded.isNotEmpty && failed.isNotEmpty) {
      final List<String> succDevs = succeeded
          .map((r) => r.device.name)
          .toSet()
          .toList();
      final List<String> failDevs = failed
          .map((r) => r.device.name)
          .toSet()
          .toList();

      final String succStr = _formatNameList(succDevs);
      final String failStr = _formatNameList(failDevs);

      return "The $succStr ${succDevs.length > 1 ? 'are' : 'is'} $actionStr, but I couldn't turn $actionStr the $failStr.";
    }

    // 3. All Failed
    final List<String> failDevs = failed
        .map((r) => r.device.name)
        .toSet()
        .toList();
    final String failStr = _formatNameList(failDevs);
    return "I couldn't turn $actionStr the $failStr. Please try again.";
  }

  String _formatNameList(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  List<Device> _findBestDeviceMatches(String text, List<Device> allDevices) {
    final String lowerInput = text.trim().toLowerCase();

    final Set<String> stopWords = {
      'turn',
      'switch',
      'on',
      'off',
      'please',
      'the',
      'of',
      'in',
      'and',
      'can',
      'you',
      'my',
      'all',
      'a',
      'an',
      'to',
      'set',
      'hasomi',
      'hey',
    };

    final List<String> queryTokens = lowerInput
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !stopWords.contains(w))
        .toList();

    if (queryTokens.isEmpty) return [];

    int maxScore = 0;
    final Map<Device, int> deviceScores = {};

    for (final device in allDevices) {
      final String cleanName = device.name.toLowerCase();
      final String cleanRoom = (device.roomName ?? device.zone).toLowerCase();

      final List<String> deviceTokens = '$cleanName $cleanRoom'
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      int score = 0;
      for (final qToken in queryTokens) {
        for (final dToken in deviceTokens) {
          if (qToken == dToken) {
            score += 10;
          } else if (qToken.contains(dToken) || dToken.contains(qToken)) {
            score += 5;
          } else if ((qToken == 'dimable' && dToken == 'dimmable') ||
              (qToken == 'dimmable' && dToken == 'dimable')) {
            score += 10;
          }
        }
      }

      if (score > 0) {
        deviceScores[device] = score;
        if (score > maxScore) {
          maxScore = score;
        }
      }
    }

    if (maxScore == 0) return [];

    // Only return top scoring device matches (score >= 80% of maxScore and at least 10)
    final List<Device> bestMatches = deviceScores.entries
        .where((entry) => entry.value >= maxScore * 0.8 && entry.value >= 10)
        .map((entry) => entry.key)
        .toList();

    return bestMatches;
  }
}
