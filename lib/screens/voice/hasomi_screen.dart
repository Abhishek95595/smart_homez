import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../utils/robot_avatar_mapper.dart';
import '../../widgets/robot_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../services/hasomi_voice_service.dart';
import '../../theme/app_theme.dart';
import '../integrations/integrations_screen.dart';

enum HasomiState {
  ready,
  listeningForWakeWord,
  wakeWordDetected,
  listeningForCommand,
  controllingDevices,
  displayResult,
}

class HasomiScreen extends StatefulWidget {
  const HasomiScreen({super.key});

  @override
  State<HasomiScreen> createState() => _HasomiScreenState();
}

class _HasomiScreenState extends State<HasomiScreen>
    with SingleTickerProviderStateMixin {
  late final stt.SpeechToText _speech;
  late final AnimationController _waveController;

  HasomiState _currentState = HasomiState.ready;
  bool _isSpeechAvailable = false;
  bool _isSpeaking = false;

  String _spokenText = '';
  String _assistantGreeting = '';
  HasomiExecutionResult? _lastResult;
  Timer? _resetTimer;

  final TextEditingController _textController = TextEditingController();

  final List<String> _sampleCommands = const [
    'Switch off the light and fan of the living room',
    'Turn on the bedroom light',
    'Switch off the living room fan',
    'Turn off the living room AC',
    'Turn off the lights in the bedroom and living room',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initSpeechAndStartWakeWordListening();
  }

  Timer? _silenceTimer;

  Future<void> _initSpeechAndStartWakeWordListening() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[Hasomi STT Status] $status');
          if ((status == 'done' || status == 'notListening') && mounted) {
            if (_currentState == HasomiState.listeningForCommand &&
                _spokenText.trim().isNotEmpty) {
              _processCommand(_spokenText);
            } else if (_currentState == HasomiState.listeningForWakeWord) {
              // Restart wake word listener continuously if still in wake word mode
              _startWakeWordListening();
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('[Hasomi STT Error] ${errorNotification.errorMsg}');
          if (mounted && _currentState == HasomiState.listeningForWakeWord) {
            _startWakeWordListening();
          }
        },
      );

      if (!mounted) return;
      setState(() => _isSpeechAvailable = available);

      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      _assistantGreeting = HasomiVoiceService.instance.generateGreeting(
        user?.name,
      );

      if (available) {
        _startWakeWordListening();
      }
    } catch (e) {
      debugPrint('[Hasomi STT Init Exception] $e');
    }
  }

  /// Active hands-free wake word listener: continuously listens for "Hey HASOMI"
  Future<void> _startWakeWordListening() async {
    if (!mounted || !_isSpeechAvailable) return;

    if (_speech.isListening) {
      await _speech.stop();
    }

    setState(() {
      _currentState = HasomiState.listeningForWakeWord;
      _spokenText = '';
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final String recognized = result.recognizedWords.trim();
        setState(() => _spokenText = recognized);

        // Check if wake word ("Hey HASOMI" or "HASOMI") is detected
        if (HasomiVoiceService.instance.isWakeWordDetected(recognized)) {
          _onWakeWordDetected(recognized);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        onDevice: true,
      ),
    );
  }

  /// Triggers when "Hey HASOMI" wake word is recognized
  Future<void> _onWakeWordDetected(String fullText) async {
    if (_currentState == HasomiState.wakeWordDetected ||
        _currentState == HasomiState.listeningForCommand ||
        _currentState == HasomiState.controllingDevices) {
      return;
    }

    await _speech.stop();

    if (!mounted) return;
    setState(() {
      _currentState = HasomiState.wakeWordDetected;
    });

    final String cleanCommand = HasomiVoiceService.instance.stripWakeWord(
      fullText,
    );

    // If the user spoke "Hey HASOMI" AND their command together in one phrase (e.g. "Hey HASOMI turn on bedroom light")
    if (cleanCommand.isNotEmpty) {
      _processCommand(cleanCommand);
      return;
    }

    // Speak dynamic greeting aloud: "Hi {name}, what can I help you with?"
    if (mounted) setState(() => _isSpeaking = true);
    await HasomiVoiceService.instance.speak(_assistantGreeting);
    if (mounted) setState(() => _isSpeaking = false);

    // Transition to listening for user's command after sentence completion
    if (!mounted) return;
    setState(() {
      _currentState = HasomiState.listeningForCommand;
      _spokenText = '';
    });

    _startCommandListening();
  }

  /// Listens for the user's smart home command
  Future<void> _startCommandListening() async {
    if (!mounted || !_isSpeechAvailable) return;

    if (_speech.isListening) {
      await _speech.stop();
    }

    _silenceTimer?.cancel();

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final String text = result.recognizedWords.trim();
        if (text.isNotEmpty) {
          setState(() => _spokenText = text);

          _silenceTimer?.cancel();
          if (result.finalResult) {
            _processCommand(text);
          } else {
            // Automatically execute command 1.5 seconds after user stops speaking
            _silenceTimer = Timer(const Duration(milliseconds: 1500), () {
              if (mounted &&
                  _currentState == HasomiState.listeningForCommand &&
                  _spokenText.trim().isNotEmpty) {
                _processCommand(_spokenText);
              }
            });
          }
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
        onDevice: false,
      ),
    );
  }

  /// Processes the extracted intent, calls existing device APIs, and speaks the confirmation
  Future<void> _processCommand(String text) async {
    if (_currentState == HasomiState.controllingDevices || !mounted) return;

    final deviceProvider = context.read<DeviceProvider>();
    _silenceTimer?.cancel();
    _resetTimer?.cancel();
    await _speech.stop();

    final String cleanText = HasomiVoiceService.instance.stripWakeWord(text);
    final String textToProcess = cleanText.isNotEmpty ? cleanText : text;

    setState(() {
      _currentState = HasomiState.controllingDevices;
      _spokenText = textToProcess;
    });

    final result = await HasomiVoiceService.instance.processVoiceCommand(
      text: textToProcess,
      deviceProvider: deviceProvider,
    );

    if (!mounted) return;

    setState(() {
      _currentState = HasomiState.displayResult;
      _lastResult = result;
      _textController.clear();
    });

    // Speak result confirmation out loud and await sentence completion
    if (mounted) setState(() => _isSpeaking = true);
    await HasomiVoiceService.instance.speak(result.spokenResponse);
    if (mounted) setState(() => _isSpeaking = false);

    // Automatically hear / listen for user's next command after sentence completion!
    if (mounted) {
      setState(() {
        _currentState = HasomiState.listeningForCommand;
        _spokenText = '';
      });
      _startCommandListening();
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _resetTimer?.cancel();
    HasomiVoiceService.instance.stopSpeaking();
    _waveController.dispose();
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final userName = user?.name ?? 'Aditya';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'HASOMI Voice Assistant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Voice Assistant Screen Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Mascot Circle with Glowing Animation
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        final bool isWaveActive =
                            _currentState == HasomiState.listeningForWakeWord ||
                            _currentState == HasomiState.listeningForCommand;

                        final glowScale = isWaveActive
                            ? 1.0 + (_waveController.value * 0.15)
                            : 1.0;
                        return Transform.scale(
                          scale: glowScale,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors:
                                    _currentState ==
                                        HasomiState.listeningForCommand
                                    ? const [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ]
                                    : const [
                                        Color(0xFF00E5FF),
                                        Color(0xFF3B82F6),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_currentState ==
                                                  HasomiState
                                                      .listeningForCommand
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF00E5FF))
                                          .withValues(
                                            alpha: isWaveActive ? 0.6 : 0.25,
                                          ),
                                  blurRadius: isWaveActive ? 35 : 20,
                                  spreadRadius: isWaveActive ? 6 : 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: RobotAvatar(
                                type: RobotAvatarMapper.mapHasomiState(
                                  _currentState,
                                  overallSuccess:
                                      _lastResult?.overallSuccess ?? true,
                                  isSpeaking: _isSpeaking,
                                ),
                                size: 85,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Hands-Free Active Wake Word Status Badge
                    _buildStateBadge(),
                    const SizedBox(height: 18),

                    // Dynamic User Greeting
                    Text(
                      _assistantGreeting.isNotEmpty
                          ? _assistantGreeting
                          : 'Hi $userName, what can I help you with?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // User Spoken Transcript Box
                    if (_spokenText.isNotEmpty ||
                        _currentState == HasomiState.listeningForWakeWord ||
                        _currentState == HasomiState.listeningForCommand)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _currentState == HasomiState.listeningForCommand
                                ? const Color(0xFF10B981)
                                : const Color(0xFF334155),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _currentState ==
                                          HasomiState.listeningForCommand
                                      ? Icons.record_voice_over_rounded
                                      : Icons.mic_rounded,
                                  color:
                                      _currentState ==
                                          HasomiState.listeningForCommand
                                      ? const Color(0xFF10B981)
                                      : AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _currentState ==
                                          HasomiState.listeningForCommand
                                      ? 'Listening for command...'
                                      : 'Listening for "Hey HASOMI"...',
                                  style: TextStyle(
                                    color:
                                        _currentState ==
                                            HasomiState.listeningForCommand
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF94A3B8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _spokenText.isEmpty
                                  ? (_currentState ==
                                            HasomiState.listeningForCommand
                                        ? 'Say a command (e.g. "Switch off light and fan in living room")...'
                                        : 'Say "Hey HASOMI" hands-free...')
                                  : '"$_spokenText"',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_currentState == HasomiState.controllingDevices) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Controlling devices...',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Device Execution Results Card
                    if (_lastResult != null &&
                        _currentState == HasomiState.displayResult) ...[
                      const SizedBox(height: 20),
                      _buildExecutionResultCard(_lastResult!),
                    ],

                    const SizedBox(height: 24),

                    // Quick Preset Command Chips
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Try saying:',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sampleCommands.map((sample) {
                        return InkWell(
                          onTap: () => _processCommand(sample),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF334155),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sample,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Amazon Alexa Integration Banner Card
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const IntegrationsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF00CAFF,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF00CAFF,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.speaker_rounded,
                                color: Color(0xFF00CAFF),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connect with Amazon Alexa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Control your smart devices using Echo & Alexa voice',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFF94A3B8),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Input & Status Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Type voice command or say "Hey HASOMI"...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _processCommand(val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: () {
                          if (_textController.text.trim().isNotEmpty) {
                            _processCommand(_textController.text);
                          } else {
                            _startCommandListening();
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Mic Status Indicator
                  GestureDetector(
                    onTap: () {
                      if (_currentState == HasomiState.listeningForCommand) {
                        _startWakeWordListening();
                      } else {
                        _startCommandListening();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _currentState == HasomiState.listeningForCommand
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              _currentState == HasomiState.listeningForCommand
                              ? const Color(0xFF10B981)
                              : AppColors.primary,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentState == HasomiState.listeningForCommand
                                ? Icons.mic_rounded
                                : Icons.graphic_eq_rounded,
                            color:
                                _currentState == HasomiState.listeningForCommand
                                ? const Color(0xFF34D399)
                                : AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentState == HasomiState.listeningForCommand
                                ? 'Listening to command... Tap to reset'
                                : 'Hands-Free Wake Word Active: Say "Hey HASOMI"',
                            style: TextStyle(
                              color:
                                  _currentState ==
                                      HasomiState.listeningForCommand
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFCBD5E1),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateBadge() {
    String text = 'Active Wake-Word Mode: Say "Hey HASOMI"';
    Color color = AppColors.primary;
    IconData icon = Icons.mic_rounded;

    switch (_currentState) {
      case HasomiState.listeningForWakeWord:
        text = 'Active Hands-Free Mode: Say "Hey HASOMI"';
        color = AppColors.primary;
        icon = Icons.graphic_eq_rounded;
        break;
      case HasomiState.wakeWordDetected:
        text = '"Hey HASOMI" Detected!';
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      case HasomiState.listeningForCommand:
        text = 'Listening for your command...';
        color = const Color(0xFF10B981);
        icon = Icons.record_voice_over_rounded;
        break;
      case HasomiState.controllingDevices:
        text = 'Executing device APIs...';
        color = const Color(0xFFF59E0B);
        icon = Icons.settings_remote_rounded;
        break;
      case HasomiState.displayResult:
        text = 'Command Executed';
        color = const Color(0xFF10B981);
        icon = Icons.task_alt_rounded;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionResultCard(HasomiExecutionResult result) {
    final bool isSuccess = result.overallSuccess;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assistant Spoken Response Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      (isSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: isSuccess
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HASOMI Response:',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${result.spokenResponse}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),

          // Individual Device Actions Checkmarks List
          if (result.actionResults.isNotEmpty) ...[
            const Text(
              'Device Action Results:',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...result.actionResults.map((act) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      act.success
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: act.success
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      act.device.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (act.success
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        act.success ? act.actionName.toUpperCase() : 'FAILED',
                        style: TextStyle(
                          color: act.success
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (result.notFoundMessages.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...result.notFoundMessages.map((msg) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          color: Color(0xFFFCD34D),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
