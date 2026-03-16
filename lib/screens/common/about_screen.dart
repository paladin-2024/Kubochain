import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About KuboChain',
          style: TextStyle(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hero icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.electric_moped_rounded,
                  size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'KuboChain',
              style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Goma's #1 Boda Ride-Hailing App",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Version badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.4), width: 1),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),

            // Mission section
            _SectionCard(
              title: 'Our Mission',
              child: const Text(
                'Connecting passengers with trusted boda drivers across Congo-Goma — fast, safe, and affordable.',
                style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 14,
                    height: 1.6),
              ),
            ),
            const SizedBox(height: 16),

            // Contact section
            _SectionCard(
              title: 'Contact Us',
              child: Column(
                children: [
                  _ContactRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'cnzabb@gmail.com',
                  ),
                  const SizedBox(height: 12),
                  _ContactRow(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    value: '+256 767 579 099',
                  ),
                  const SizedBox(height: 12),
                  _ContactRow(
                    icon: Icons.tag,
                    label: 'Twitter',
                    value: '@KuboChain',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Legal section
            _SectionCard(
              title: 'Legal',
              child: Column(
                children: [
                  _LegalTile(
                    label: 'Terms of Service',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: AppColors.borderDark,
                      indent: 8,
                      endIndent: 8),
                  _LegalTile(
                    label: 'Privacy Policy',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            const Text(
              '© 2025 KuboChain. All rights reserved.',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textOnDark, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _LegalTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textOnDark, fontSize: 14)),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
