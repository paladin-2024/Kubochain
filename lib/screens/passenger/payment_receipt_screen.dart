import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import 'rate_driver_screen.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final double amount;
  final String reference;
  final String? driverName;
  final String pickupAddress;
  final String destinationAddress;
  final String paymentMethod;
  final DateTime? paidAt;

  const PaymentReceiptScreen({
    super.key,
    required this.amount,
    required this.reference,
    this.driverName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.paymentMethod,
    this.paidAt,
  });

  String get _methodLabel =>
      paymentMethod == 'airtel_money' ? 'Airtel Money' : 'Espèces';

  Color get _methodColor =>
      paymentMethod == 'airtel_money' ? const Color(0xFFE02020) : AppColors.success;

  Future<void> _shareWhatsApp() async {
    final date = (paidAt ?? DateTime.now()).toLocal();
    final msg = Uri.encodeComponent(
      'KuboChain — Reçu de paiement\n'
      'Montant: FC ${amount.toStringAsFixed(0)}\n'
      'Méthode: $_methodLabel\n'
      'Référence: $reference\n'
      '${driverName != null ? 'Conducteur: $driverName\n' : ''}'
      'Date: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}\n'
      'De: $pickupAddress\n'
      'Vers: $destinationAddress',
    );
    final uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = (paidAt ?? DateTime.now()).toLocal();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          size: 40,
                          color: AppColors.success),
                    ),
                    const SizedBox(height: 12),
                    Text('Paiement confirmé',
                        style: GoogleFonts.sora(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('FC ${amount.toStringAsFixed(0)}',
                        style: GoogleFonts.sora(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const SizedBox(height: 24),
                    _ReceiptCard(children: [
                      _ReceiptRow(
                          label: 'Méthode',
                          value: _methodLabel,
                          valueColor: _methodColor),
                      _ReceiptRow(
                          label: 'Référence', value: reference, mono: true),
                      if (driverName != null)
                        _ReceiptRow(label: 'Conducteur', value: driverName!),
                      _ReceiptRow(
                          label: 'Date',
                          value:
                              '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                      _ReceiptRow(
                          label: 'De',
                          value: pickupAddress,
                          maxLines: 2),
                      _ReceiptRow(
                          label: 'Vers',
                          value: destinationAddress,
                          maxLines: 2),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _shareWhatsApp,
                      icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedShare01,
                          size: 18,
                          color: AppColors.primary),
                      label: Text('Partager via WhatsApp',
                          style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RateDriverScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                      ),
                      child: Text('Évaluer le conducteur',
                          style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
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
}

class _ReceiptCard extends StatelessWidget {
  final List<Widget> children;
  const _ReceiptCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(children: children),
      );
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;
  final int maxLines;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 100,
                child: Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.textSecondary))),
            Expanded(
                child: Text(value,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: mono
                        ? const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600)
                        : GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                valueColor ?? AppColors.textPrimary))),
          ],
        ),
      );
}
