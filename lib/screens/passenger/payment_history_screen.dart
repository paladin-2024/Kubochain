import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'payment_receipt_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getPaymentHistory();
      setState(() {
        _items = List<Map<String, dynamic>>.from(res.data as List);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = "Impossible de charger l'historique";
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'processing':
        return Colors.blue;
      case 'failed':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'processing':
        return 'En cours';
      case 'failed':
        return 'Échoué';
      default:
        return 'En attente';
    }
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'airtel_money':
        return 'Airtel Money';
      case 'mtn_momo':
        return 'MTN MoMo';
      default:
        return 'Espèces';
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
        title: Text('Historique des paiements',
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: _load, child: const Text('Réessayer')),
                ]))
              : _items.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedInvoice01,
                          size: 48,
                          color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('Aucun paiement',
                          style: GoogleFonts.sora(
                              fontSize: 16,
                              color: AppColors.textSecondary)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final status =
                            item['payment_status'] as String? ?? 'pending';
                        final method =
                            item['payment_method'] as String? ?? 'cash';
                        final amount =
                            (item['amount'] as num?)?.toDouble() ?? 0;
                        return GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentReceiptScreen(
                                  amount: amount,
                                  reference: item['payment_reference']
                                          as String? ??
                                      '-',
                                  driverName:
                                      item['driver_name'] as String?,
                                  pickupAddress:
                                      item['pickup_address'] as String? ?? '',
                                  destinationAddress:
                                      item['destination_address'] as String? ??
                                          '',
                                  paymentMethod: method,
                                ),
                              )),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedMoney01,
                                    size: 22,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('FC ${amount.toStringAsFixed(0)}',
                                        style: GoogleFonts.sora(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(_methodLabel(method),
                                        style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ])),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(_statusLabel(status),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(status))),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}
