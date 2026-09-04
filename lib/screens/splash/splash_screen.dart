import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../auth/login_screen.dart';
import '../main_shell.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  bool _isFadingOut = false;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _initializeVideo();
    _restoreUserSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up and pre-cache heavy images into GPU memory while splash video plays
    precacheImage(
      const AssetImage('assets/images/app_logo_white_transparent.png'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/app_logo_teal_transparent.png'),
      context,
    );
    precacheImage(const AssetImage('assets/images/app_icon.png'), context);
    precacheImage(const AssetImage('assets/images/drawer_bg.png'), context);
    precacheImage(
      const AssetImage('assets/images/home_hero_banner.png'),
      context,
    );
    precacheImage(const AssetImage('assets/images/new_robot.png'), context);
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/smarthome_splash_screen.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _videoController.initialize();
      _videoController.setLooping(false);
      _videoController.addListener(_videoListener);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        await _videoController.play();
        _fadeController.forward(); // Smooth Fade IN on start
      }
    } catch (e) {
      debugPrint('[SplashScreen] Video initialization error: $e');
      _triggerFadeOutAndNavigate();
    }
  }

  void _videoListener() {
    if (!mounted || _isFadingOut || _navigationTriggered) return;

    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    if (duration > Duration.zero) {
      // Start Fade OUT 350ms before video finishes
      final fadeOutThreshold = duration > const Duration(milliseconds: 700)
          ? duration - const Duration(milliseconds: 350)
          : duration;

      if (position >= fadeOutThreshold) {
        _triggerFadeOutAndNavigate();
      }
    }
  }

  Future<void> _restoreUserSession() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final propertyProvider = context.read<PropertyProvider>();
      final deviceProvider = context.read<DeviceProvider>();

      await authProvider.restoreSession(
        propertyProvider: propertyProvider,
        deviceProvider: deviceProvider,
      );
    } catch (e) {
      debugPrint('[SplashScreen] Restore session notice: $e');
    }
  }

  Future<void> _triggerFadeOutAndNavigate() async {
    if (_isFadingOut || _navigationTriggered) return;
    _isFadingOut = true;

    // Smooth Fade OUT
    if (mounted) {
      await _fadeController.reverse();
    }

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (_navigationTriggered) return;
    _navigationTriggered = true;

    if (mounted) {
      final authProvider = context.read<AuthProvider>();
      final bool isLoggedIn = authProvider.isLoggedIn;

      // Direct destination: LoginScreen if unauthenticated, MainShell if logged in (No extra landing page)
      final Widget targetScreen = isLoggedIn
          ? const MainShell()
          : const LoginScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap:
            _triggerFadeOutAndNavigate, // Tap to immediately fade out and proceed
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox.expand(
            child: _isInitialized && _videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover, // Universal full-screen coverage
                    child: SizedBox(
                      width: _videoController.value.size.width > 0
                          ? _videoController.value.size.width
                          : MediaQuery.of(context).size.width,
                      height: _videoController.value.size.height > 0
                          ? _videoController.value.size.height
                          : MediaQuery.of(context).size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : const SizedBox.expand(child: ColoredBox(color: Colors.black)),
          ),
        ),
      ),
    );
  }
}
