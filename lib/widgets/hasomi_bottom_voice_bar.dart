import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../services/hasomi_voice_service.dart';

enum HasomiVoiceBarState {
  idle,
  listeningForWakeWord,
  wakeWordDetected,
  listeningForCommand,
  processing,
  controlling,
  success,
  error,
}

class HasomiBottomVoiceBar extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onClose;

  const HasomiBottomVoiceBar({super.key, this.isActive = true, this.onClose});

  @override
  State<HasomiBottomVoiceBar> createState() => HasomiBottomVoiceBarState();
}

class HasomiBottomVoiceBarState extends State<HasomiBottomVoiceBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final stt.SpeechToText _speech;

  HasomiVoiceBarState _barState = HasomiVoiceBarState.idle;
  bool _isSpeechAvailable = false;

  String _spokenText = '';
  String _assistantGreeting = '';
  String _statusText = '';
  Timer? _silenceTimer;
  Timer? _fadeTimer;

  Timer? _commandTimeoutTimer;
  bool _isStartingListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _initSpeechAndWakeWordMode();
  }

  Future<void> _initSpeechAndWakeWordMode() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[Hasomi VoiceBar STT Status] $status');
          if ((status == 'done' || status == 'notListening') && mounted) {
            _isStartingListening = false;
            if (_barState == HasomiVoiceBarState.listeningForCommand &&
                _spokenText.trim().isNotEmpty) {
              _processCommand(_spokenText);
            }
          }
        },
        onError: (errorNotification) {
          debugPrint(
            '[Hasomi VoiceBar STT Error] ${errorNotification.errorMsg}',
          );
          _isStartingListening = false;
        },
      );

      if (!mounted) return;
      setState(() => _isSpeechAvailable = available);

      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      _assistantGreeting = HasomiVoiceService.instance.generateGreeting(
        user?.name,
      );
    } catch (e) {
      debugPrint('[Hasomi VoiceBar Init Error] $e');
    }
  }

  /// Toggles HASOMI voice control when the microphone button is clicked
  void triggerVoiceListening() {
    if (_barState != HasomiVoiceBarState.idle) {
      _stopAndResetToIdle();
    } else {
      _activateAndListenCommand();
    }
  }

  /// Activates HASOMI, speaks "Hi {name}, how can I help you?", and listens for command
  Future<void> _activateAndListenCommand() async {
    _silenceTimer?.cancel();
    _commandTimeoutTimer?.cancel();
    _fadeTimer?.cancel();

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final String greeting = HasomiVoiceService.instance.generateGreeting(
      user?.name,
    );
    _assistantGreeting = greeting.isNotEmpty
        ? greeting
        : 'Hi! How can I help you?';

    // Speak dynamic greeting aloud: "Hi {name}, how can I help you?"
    HasomiVoiceService.instance.speak(_assistantGreeting);

    if (!mounted) return;
    setState(() {
      _barState = HasomiVoiceBarState.listeningForCommand;
      _spokenText = '';
      _statusText = _assistantGreeting;
    });

    _startCommandListening();
  }

  /// Stops voice listening and resets to idle (turns OFF)
  Future<void> _stopAndResetToIdle() async {
    _silenceTimer?.cancel();
    _commandTimeoutTimer?.cancel();
    _fadeTimer?.cancel();
    if (_speech.isListening) {
      await _speech.stop();
    }
    if (!mounted) return;
    setState(() {
      _barState = HasomiVoiceBarState.idle;
      _spokenText = '';
      _statusText = '';
    });
  }

  /// Listens for user's command during a 7-second active listening window
  Future<void> _startCommandListening() async {
    if (!mounted || !_isSpeechAvailable || _isStartingListening) return;

    _isStartingListening = true;
    if (_speech.isListening) {
      await _speech.stop();
    }

    _silenceTimer?.cancel();
    _commandTimeoutTimer?.cancel();

    // 12-second max listening window timer (increased by 5s)
    _commandTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _barState == HasomiVoiceBarState.listeningForCommand) {
        if (_spokenText.trim().isNotEmpty) {
          _processCommand(_spokenText);
        } else {
          _onCommandTimeout();
        }
      }
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final String text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            setState(() {
              _spokenText = text;
              _statusText = '"$text"';
            });

            _silenceTimer?.cancel();
            if (result.finalResult) {
              _processCommand(text);
            } else {
              // Auto-execute 1.5s after user stops speaking
              _silenceTimer = Timer(const Duration(milliseconds: 1500), () {
                if (mounted &&
                    _barState == HasomiVoiceBarState.listeningForCommand &&
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
    } catch (e) {
      debugPrint('[Hasomi STT Command Exception] $e');
    } finally {
      _isStartingListening = false;
    }
  }

  /// Handles timeout if no command is heard after 7 seconds
  Future<void> _onCommandTimeout() async {
    _silenceTimer?.cancel();
    _commandTimeoutTimer?.cancel();
    await _speech.stop();

    if (!mounted) return;
    setState(() {
      _barState = HasomiVoiceBarState.error;
      _statusText = 'No command heard. Tap microphone button to try again.';
    });

    await HasomiVoiceService.instance.speak(
      "No command heard. Please tap the microphone button to try again.",
    );

    _fadeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _stopAndResetToIdle();
      }
    });
  }

  /// Processes command, calls existing device APIs, speaks result, and turns OFF
  Future<void> _processCommand(String text) async {
    if (_barState == HasomiVoiceBarState.controlling || !mounted) return;

    final deviceProvider = context.read<DeviceProvider>();
    _silenceTimer?.cancel();
    _commandTimeoutTimer?.cancel();
    _fadeTimer?.cancel();
    await _speech.stop();

    final String cleanText = HasomiVoiceService.instance.stripWakeWord(text);
    final String textToProcess = cleanText.isNotEmpty ? cleanText : text;

    setState(() {
      _barState = HasomiVoiceBarState.controlling;
      _spokenText = textToProcess;
      _statusText = 'Controlling devices...';
    });

    final result = await HasomiVoiceService.instance.processVoiceCommand(
      text: textToProcess,
      deviceProvider: deviceProvider,
    );

    if (!mounted) return;

    setState(() {
      _barState = result.overallSuccess
          ? HasomiVoiceBarState.success
          : HasomiVoiceBarState.error;
      _statusText = result.spokenResponse;
    });

    // Speak confirmation result aloud
    await HasomiVoiceService.instance.speak(result.spokenResponse);

    // Fade out and turn OFF (reset to idle) after 8 seconds (increased by 5s)
    _fadeTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        _stopAndResetToIdle();
      }
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _commandTimeoutTimer?.cancel();
    _fadeTimer?.cancel();
    HasomiVoiceService.instance.stopSpeaking();
    _animController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_barState == HasomiVoiceBarState.idle && !widget.isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Text Banner immediately above the blue voice line
          if (_statusText.isNotEmpty)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _barState == HasomiVoiceBarState.idle ? 0.0 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _getBarColor().withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getBarColor(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Alexa-Style Thin Glowing Animated Blue Line
          SizedBox(
            height: 12,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _VoiceLinePainter(
                    animationValue: _animController.value,
                    state: _barState,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor() {
    switch (_barState) {
      case HasomiVoiceBarState.listeningForCommand:
        return const Color(0xFF00E5FF);
      case HasomiVoiceBarState.wakeWordDetected:
        return const Color(0xFF38BDF8);
      case HasomiVoiceBarState.controlling:
        return const Color(0xFFF59E0B);
      case HasomiVoiceBarState.success:
        return const Color(0xFF10B981);
      case HasomiVoiceBarState.error:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

class _VoiceLinePainter extends CustomPainter {
  final double animationValue;
  final HasomiVoiceBarState state;

  _VoiceLinePainter({required this.animationValue, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    if (state == HasomiVoiceBarState.idle) return;

    final double width = size.width;
    final double midY = size.height / 2;

    // Determine colors based on state
    Color primaryColor = const Color(0xFF00E5FF); // Electric Cyan
    Color secondaryColor = const Color(0xFF3B82F6); // Deep Blue

    double amplitude = 3.0;
    double frequency = 3.0;

    switch (state) {
      case HasomiVoiceBarState.listeningForWakeWord:
        primaryColor = const Color(0xFF00E5FF);
        secondaryColor = const Color(0xFF3B82F6);
        amplitude = 2.0;
        frequency = 2.5;
        break;
      case HasomiVoiceBarState.wakeWordDetected:
        primaryColor = const Color(0xFF38BDF8);
        secondaryColor = const Color(0xFF00E5FF);
        amplitude = 5.0;
        frequency = 4.0;
        break;
      case HasomiVoiceBarState.listeningForCommand:
        primaryColor = const Color(0xFF00E5FF);
        secondaryColor = const Color(0xFF10B981);
        amplitude = 4.5;
        frequency = 3.5;
        break;
      case HasomiVoiceBarState.controlling:
        primaryColor = const Color(0xFFF59E0B);
        secondaryColor = const Color(0xFF3B82F6);
        amplitude = 3.0;
        frequency = 5.0;
        break;
      case HasomiVoiceBarState.success:
        primaryColor = const Color(0xFF10B981);
        secondaryColor = const Color(0xFF34D399);
        amplitude = 2.0;
        frequency = 2.0;
        break;
      case HasomiVoiceBarState.error:
        primaryColor = const Color(0xFFEF4444);
        secondaryColor = const Color(0xFFF87171);
        amplitude = 2.0;
        frequency = 2.0;
        break;
      default:
        break;
    }

    final double phase = animationValue * 2 * math.pi * frequency;

    // 1. Draw Ambient Soft Outer Glow
    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.0),
          primaryColor.withValues(alpha: 0.8),
          secondaryColor.withValues(alpha: 0.8),
          primaryColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, size.height))
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final Path path = Path();
    path.moveTo(0, midY);

    for (double x = 0; x <= width; x += 3) {
      // Gaussian window envelope so line tapers softly at left and right screen edges
      final double normalizedX = x / width;
      final double envelope = math.sin(normalizedX * math.pi);

      final double y =
          midY +
          math.sin(normalizedX * math.pi * 6 + phase) * amplitude * envelope;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, glowPaint);

    // 2. Draw Sharp Center Core Line
    final Paint corePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          primaryColor,
          Colors.white,
          secondaryColor,
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, size.height))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _VoiceLinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.state != state;
  }
}
