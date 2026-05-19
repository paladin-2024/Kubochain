import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_routes.dart';
import 'core/services/api_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/connectivity_banner.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  ApiService.init();

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  await NotificationService.init();

  NotificationService.setNotificationTapHandler((data) {
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

  runApp(const ProviderScope(child: KuboChainApp()));
}

class KuboChainApp extends StatelessWidget {
  const KuboChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KuboChain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const ConnectivityBanner(child: SplashScreen()),
      builder: (context, child) => ConnectivityBanner(child: child ?? const SizedBox()),
    );
  }
}
