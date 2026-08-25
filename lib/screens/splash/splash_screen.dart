import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../landing/landing_screen.dart';
import '../main_shell.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _restoreUserSession();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(
      'assets/smarthome_splash_screen.mp4',
    );

    try {
      await _controller.initialize();
      _controller.setLooping(false);
      _controller.addListener(_videoListener);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('[SplashScreen] Video initialization failed: $e');
      // If video fails to load, fallback to immediate navigation after a short delay
      Future.delayed(const Duration(seconds: 3), _navigateToNextScreen);
    }
  }

  void _videoListener() {
    if (!mounted || _navigationTriggered) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    // Check if the video has completed playing
    if (position >= duration && duration > Duration.zero) {
      _navigateToNextScreen();
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
      debugPrint('[SplashScreen] Restore session error: $e');
    }
  }

  void _navigateToNextScreen() {
    if (_navigationTriggered) return;
    _navigationTriggered = true;

    if (mounted) {
      final authProvider = context.read<AuthProvider>();
      final bool isLoggedIn = authProvider.isLoggedIn;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isLoggedIn ? const MainShell() : const LandingScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 600,
            ),
            child: _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
          ),
        ),
      ),
    );
  }
}
