import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  String _selectedMethod = 'cash';
  late AnimationController _saveCtrl;
  late Animation<double> _saveScale;

  static const _methods = [
    _PayMethod(
      id: 'airtel_money',
      label: 'Airtel Money',
      subtitle: 'Mobile money · Rapide et fiable',
      icon: HugeIcons.strokeRoundedWifi01,
      brandColor: Color(0xFFE02020),
      bgLight: Color(0xFFFFF1F1),
      tag: null,
    ),
    _PayMethod(
      id: 'cash',
      label: 'Espèces',
      subtitle: 'Payez directement votre conducteur',
      icon: HugeIcons.strokeRoundedMoney01,
      brandColor: Color(0xFF10B981),
      bgLight: Color(0xFFF0FDF9),
      tag: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _saveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _saveScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _saveCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _saveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: Column(
        children: [
          // Header
          _buildHeader(context),

          // Payment methods list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: _methods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _MethodCard(
                method: _methods[i],
                selected: _selectedMethod == _methods[i].id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMethod = _methods[i].id);
                },
              ),
            ),
          ),

          // Save button
          _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: Colors.white.withOpacity(0.9),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode de paiement',
                        style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Comment souhaitez-vous payer ?',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final selected = _methods.firstWhere((m) => m.id == _selectedMethod);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected method preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected.bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected.brandColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(icon: selected.icon, color: selected.brandColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selected.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected.brandColor,
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedTick01, color: Colors.white, size: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ScaleTransition(
            scale: _saveScale,
            child: GestureDetector(
              onTapDown: (_) => _saveCtrl.forward(),
              onTapUp: (_) {
                _saveCtrl.reverse();
                HapticFeedback.mediumImpact();
                Navigator.pop(context, _selectedMethod);
              },
              onTapCancel: () => _saveCtrl.reverse(),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Enregistrer le mode de paiement',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final _PayMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? method.bgLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? method.brandColor : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: method.brandColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppColors.softShadow,
        ),
        child: Row(
          children: [
            // Brand icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? method.brandColor.withOpacity(0.18)
                    : method.brandColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: HugeIcon(
                icon: method.icon,
                color: method.brandColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Label + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          method.label,
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.textPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (method.tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: method.brandColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            method.tag!,
                            style: GoogleFonts.sora(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    method.subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? method.brandColor : Colors.transparent,
                border: Border.all(
                  color: selected ? method.brandColor : AppColors.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? const HugeIcon(icon: HugeIcons.strokeRoundedTick01, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethod {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color brandColor;
  final Color bgLight;
  final String? tag;

  const _PayMethod({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.brandColor,
    required this.bgLight,
    this.tag,
  });
}
