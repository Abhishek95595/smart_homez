import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/alert_provider.dart';
import 'providers/automation_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/client_dashboard_provider.dart';
import 'providers/energy_provider.dart';
import 'providers/property_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/water_provider.dart';
import 'features/home_setup/providers/home_setup_provider.dart';
import 'features/home_setup/screens/home_setup_screen.dart';
import 'features/integrations/alexa/alexa_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase phone authentication is used on supported mobile platforms.
  // Windows uses the app's API OTP flow, so startup does not depend on a
  // machine-specific Firebase desktop configuration.
  if (defaultTargetPlatform != TargetPlatform.windows) {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
  }
  await Hive.initFlutter();
  runApp(const SmartBuildingApp());
}

class SmartBuildingApp extends StatelessWidget {
  const SmartBuildingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ClientDashboardProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => AutomationProvider()),
        ChangeNotifierProxyProvider<DeviceProvider, RoutineProvider>(
          create: (_) => RoutineProvider(),
          update: (_, deviceProvider, routineProvider) {
            final provider = routineProvider ?? RoutineProvider();
            provider.setDeviceProvider(deviceProvider);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => EnergyProvider()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => AlexaProvider()),
        ChangeNotifierProvider(create: (_) => HomeSetupProvider()),
      ],
      child: MaterialApp(
        title: 'Hasomi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const VideoSplashScreen(),
        routes: {'/homes/setup': (context) => const HomeSetupScreen()},
      ),
    );
  }
}
