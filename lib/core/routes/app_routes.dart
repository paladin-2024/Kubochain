import 'package:flutter/material.dart';
import '../../screens/splash_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/onboarding.dart';
import '../../screens/Auth/login.dart';
import '../../screens/Auth/signup.dart';
import '../../screens/passenger/passenger_main.dart';
import '../../screens/passenger/home_screen.dart';
import '../../screens/passenger/book_ride_screen.dart';
import '../../screens/passenger/searching_driver_screen.dart';
import '../../screens/passenger/driver_arriving_screen.dart';
import '../../screens/passenger/trip_screen.dart';
import '../../screens/passenger/rate_driver_screen.dart';
import '../../screens/passenger/bookings_screen.dart';
import '../../screens/passenger/profile_screen.dart';
import '../../screens/passenger/payment_screen.dart';
import '../../screens/rider/rider_main.dart';
import '../../screens/rider/earnings_screen.dart';
import '../../screens/rider/rider_profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String signup = '/signup';

  // Passenger
  static const String passengerMain = '/passenger';
  static const String home = '/passenger/home';
  static const String bookRide = '/passenger/book';
  static const String searchingDriver = '/passenger/searching';
  static const String driverArriving = '/passenger/arriving';
  static const String trip = '/passenger/trip';
  static const String rateDriver = '/passenger/rate';
  static const String bookings = '/passenger/bookings';
  static const String passengerProfile = '/passenger/profile';
  static const String payment = '/passenger/payment';

  // Rider
  static const String riderMain = '/rider';
  static const String riderEarnings = '/rider/earnings';
  static const String riderProfile = '/rider/profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (_) => const SplashScreen(),
      onboarding: (_) => const OnBoardingScreen(),
      landing: (_) => const OnBoardingPage(),
      login: (_) => const LoginPage(),
      signup: (_) => const SignUpPage(),
      passengerMain: (_) => const PassengerMain(),
      home: (_) => const HomeScreen(),
      bookRide: (_) => const BookRideScreen(),
      searchingDriver: (_) => const SearchingDriverScreen(),
      driverArriving: (_) => const DriverArrivingScreen(),
      trip: (_) => const TripScreen(),
      rateDriver: (_) => const RateDriverScreen(),
      bookings: (_) => const BookingsScreen(),
      passengerProfile: (_) => const PassengerProfileScreen(),
      payment: (_) => const PaymentScreen(),
      riderMain: (_) => const RiderMain(),
      riderEarnings: (_) => const EarningsScreen(),
      riderProfile: (_) => const RiderProfileScreen(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('No route defined for ${settings.name}')),
      ),
    );
  }
}
