import 'package:latlong2/latlong.dart';

class AppConstants {
  // Currency
  static const String currencySymbol = 'FC';
  static const String currencyCode = 'CDF';

  // Default map center — Goma, DRC
  static const LatLng defaultLocation = LatLng(-1.6792, 29.2228);
  static const double defaultZoom = 14.0;

  // Pricing (Congolese Francs)
  static const double basePriceCDF = 1000.0; // FC per ride base fare
  static const double pricePerKmCDF = 500.0; // FC per km

  static String formatPrice(double amount) =>
      '${AppConstants.currencySymbol} ${amount.toStringAsFixed(0)}';
}
