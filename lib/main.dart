import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/services/api_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/ride_provider.dart';
import 'providers/location_provider.dart';
import 'providers/driver_provider.dart';
import 'screens/splash_screen.dart';

// Firebase — only imported when configured
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  ApiService.init();

  // Initialize Firebase (requires google-services.json)
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured yet — push notifications will be unavailable
  }

  await NotificationService.init();

  // Handle notification taps — store data + navigate to the right screen
  NotificationService.setNotificationTapHandler((data) {
    // Store so the target screen can consume it and act
    NotificationService.storePendingNotification(data);
    final type = data['type'] as String?;
    if (type == 'new_ride_request') {
      NavigationService.navigateTo(AppRoutes.riderMain);
    } else if (type == 'ride_accepted' || type == 'trip_confirmation_needed') {
      NavigationService.navigateTo(AppRoutes.passengerMain);
    } else if (type == 'chat_message') {
      NavigationService.navigateTo(AppRoutes.passengerMain);
    }
  });

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const KuboChainApp());
}

class KuboChainApp extends StatelessWidget {
  const KuboChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: MaterialApp(
        title: 'KuboChain',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: NavigationService.navigatorKey,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}
