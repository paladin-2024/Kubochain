import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../providers/providers.dart';
import 'payment_receipt_screen.dart';

class AirtelPaymentScreen extends ConsumerStatefulWidget {
  final String rideId;
  final double amount;
  final String pickupAddress;
  final String destinationAddress;
  final String? driverName;

  const AirtelPaymentScreen({
    super.key,
    required this.rideId,
    required this.amount,
    required this.pickupAddress,
    required this.destinationAddress,
    this.driverName,
  });

  @override
  ConsumerState<AirtelPaymentScreen> createState() => _AirtelPaymentScreenState();
}

class _AirtelPaymentScreenState extends ConsumerState<AirtelPaymentScreen> {
  final _phoneCtrl = TextEditingController();
  final _auth = LocalAuthentication();
  _PayState _state = _PayState.idle;
  String? _error;
  int _attempts = 0;
  static const _maxAttempts = 3;
  String? _reference;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _phoneCtrl.text = auth.user?.phone ?? '';
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricAvailable = canCheck && isDeviceSupported);
      }
    } catch (_) {}
  }

  Future<bool> _authenticate() async {
    if (!_biometricAvailable) return true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirmez le paiement de FC ${widget.amount.toStringAsFixed(0)}',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_attempts >= _maxAttempts) return;
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Entrez votre numéro Airtel Money');
      return;
    }

    // Biometric gate
    final authenticated = await _authenticate();
    if (!authenticated) {
      setState(() => _error = 'Authentification biométrique requise pour payer');
      return;
    }

    setState(() {
      _state = _PayState.processing;
      _error = null;
    });
    _attempts++;
    try {
      final res = await ApiService.initiatePayment(
        rideId: widget.rideId,
        phone: phone,
        method: 'airtel_money',
      );
      final data = res.data as Map<String, dynamic>;
      if (data['status'] == 'paid') {
        _reference = data['reference'] as String?;
        setState(() => _state = _PayState.success);
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentReceiptScreen(
              amount: widget.amount,
              reference: _reference ?? '',
              driverName: widget.driverName,
              pickupAddress: widget.pickupAddress,
              destinationAddress: widget.destinationAddress,
              paymentMethod: 'airtel_money',
            ),
          ),
        );
      } else {
        setState(() {
          _state = _PayState.failed;
          _error = 'Paiement refusé. Vérifiez votre solde Airtel.';
        });
      }
    } catch (_) {
      setState(() {
        _state = _PayState.failed;
        _error = _attempts >= _maxAttempts
            ? 'Échec après $_maxAttempts tentatives. Contactez le support.'
            : 'Erreur réseau. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 22,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payer via Airtel Money',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE02020).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFE02020).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text('Montant à payer',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text('FC ${widget.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.sora(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    const HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 14,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                            '${widget.pickupAddress} → ${widget.destinationAddress}',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (_state != _PayState.success) ...[
              Text('Numéro Airtel Money',
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                enabled:
                    _state == _PayState.idle || _state == _PayState.failed,
                decoration: InputDecoration(
                  hintText: '+243XXXXXXXXX',
                  prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPhoneCheck,
                      size: 20,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const HugeIcon(
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    size: 16,
                    color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppColors.error))),
              ]),
            ],

            const Spacer(),

            if (_state == _PayState.processing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Center(
                  child: Text('Traitement en cours...',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textSecondary))),
            ] else if (_state == _PayState.success) ...[
              Center(
                  child: Column(children: [
                const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    size: 56,
                    color: AppColors.success),
                const SizedBox(height: 12),
                Text('Paiement confirmé !',
                    style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ])),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _attempts >= _maxAttempts
                        ? AppColors.textSecondary
                        : const Color(0xFFE02020),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: _attempts >= _maxAttempts ? null : _pay,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_biometricAvailable) ...[
                        const Icon(Icons.fingerprint, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _state == _PayState.failed ? 'Réessayer' : 'Payer maintenant',
                        style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

enum _PayState { idle, processing, success, failed }
