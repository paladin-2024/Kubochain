import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/app_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'cash';

  final _paymentMethods = [
    {'id': 'cash', 'label': 'Cash', 'icon': Icons.monetization_on_outlined, 'subtitle': 'Pay with cash'},
    {'id': 'momo', 'label': 'MTN MoMo', 'icon': Icons.phone_android_outlined, 'subtitle': 'Mobile money'},
    {'id': 'airtel', 'label': 'Airtel Money', 'icon': Icons.phone_android_outlined, 'subtitle': 'Mobile money'},
    {'id': 'card', 'label': 'Credit/Debit Card', 'icon': Icons.credit_card_outlined, 'subtitle': 'Visa, Mastercard'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Payment Methods')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your preferred payment method',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _paymentMethods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final method = _paymentMethods[i];
                  final selected = _selectedMethod == method['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMethod = method['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withOpacity(0.05) : AppColors.backgroundLight,
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              method['icon'] as IconData,
                              color: selected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method['label'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  method['subtitle'] as String,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            AppButton(
              label: 'Save Payment Method',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
