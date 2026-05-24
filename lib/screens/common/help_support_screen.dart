import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.textOnDark, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Aide & Support',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: const [
                  const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Rechercher de l\'aide...',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Common Questions
            const Text(
              'Questions fréquentes',
              style: TextStyle(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: const [
                    _FaqTile(
                      question: 'Comment réserver un trajet ?',
                      answer:
                          "Appuyez sur 'Où voulez-vous aller ?' sur l'écran d'accueil, entrez votre destination, choisissez un type de trajet et confirmez.",
                    ),
                    _FaqTile(
                      question: 'Comment payer ?',
                      answer:
                          'KuboChain accepte les espèces et Airtel Money. Choisissez votre mode de paiement avant de confirmer.',
                    ),
                    _FaqTile(
                      question: "Mon conducteur n'est pas venu",
                      answer:
                          'Vous pouvez annuler le trajet et en demander un nouveau. Si cela se reproduit, contactez notre équipe.',
                    ),
                    _FaqTile(
                      question: 'Comment noter mon conducteur ?',
                      answer:
                          'Après chaque trajet, vous serez invité à noter votre conducteur de 1 à 5 étoiles.',
                    ),
                    _FaqTile(
                      question: 'Comment devenir conducteur ?',
                      answer:
                          'Inscrivez-vous en tant que Conducteur sur l\'écran d\'inscription et renseignez les informations de votre véhicule.',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contact Support
            const Text(
              'Contacter le support',
              style: TextStyle(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  _SupportTile(
                    icon: HugeIcons.strokeRoundedMessage01,
                    label: 'Discuter avec le support',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bientôt disponible')),
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: AppColors.borderDark,
                      indent: 56,
                      endIndent: 0),
                  _SupportTile(
                    icon: HugeIcons.strokeRoundedPhoneCheck,
                    label: 'Appelez-nous : +256 767 579 099',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bientôt disponible')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(icon: HugeIcons.strokeRoundedCall02,
                        color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Urgence ? Appelez le 112',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Services d\'urgence KuboChain',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
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

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isLast;

  const _FaqTile({
    required this.question,
    required this.answer,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Text(
          question,
          style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          Text(
            answer,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SupportTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: HugeIcon(icon: icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textOnDark, fontSize: 14)),
            ),
            const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
