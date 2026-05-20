import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../providers/providers.dart';
import '../../core/services/storage_service.dart';
import '../../screens/onboarding.dart';
import '../../widgets/common/avatar_picker_sheet.dart';
import '../../widgets/common/press_scale.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/effects/ambient_orbs.dart';
import '../common/notifications_screen.dart';

class RiderProfileScreen extends ConsumerStatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  ConsumerState<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends ConsumerState<RiderProfileScreen> {
  bool _uploading = false;
  int _avatarColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _avatarColorIndex = StorageService.getAvatarColorIndex();
  }

  void _openAvatarPicker(String name) {
    AvatarPickerSheet.show(
      context,
      name: name,
      onSelected: (i) => setState(() => _avatarColorIndex = i),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: AppColors.textOnDark, size: 20),
              title: const Text('Caméra', style: TextStyle(color: AppColors.textOnDark)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: AppColors.textOnDark, size: 20),
              title: const Text('Galerie', style: TextStyle(color: AppColors.textOnDark)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file == null) return;
    setState(() => _uploading = true);
    if (!mounted) return;
    final ok = await ref.read(authProvider).updateProfileImage(file.path);
    if (mounted) {
      setState(() => _uploading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du chargement de la photo')),
        );
      }
    }
  }

  void _showEditProfile() {
    final auth = ref.read(authProvider);
    final user = auth.user;
    final firstCtrl = TextEditingController(text: user?.firstName ?? '');
    final lastCtrl = TextEditingController(text: user?.lastName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modifier le profil',
                    style: TextStyle(color: AppColors.textOnDark, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _DarkField(ctrl: firstCtrl, label: 'Prénom', icon: HugeIcons.strokeRoundedUser),
                const SizedBox(height: 12),
                _DarkField(ctrl: lastCtrl, label: 'Nom', icon: HugeIcons.strokeRoundedUser),
                const SizedBox(height: 12),
                _DarkField(ctrl: emailCtrl, label: 'E-mail', icon: HugeIcons.strokeRoundedMail01, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _DarkField(ctrl: phoneCtrl, label: 'Téléphone', icon: HugeIcons.strokeRoundedPhoneCheck, keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: saving ? null : () async {
                      setModalState(() => saving = true);
                      final ok = await ref.read(authProvider).updateProfile(
                        firstName: firstCtrl.text.trim(),
                        lastName: lastCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Profil mis à jour' : 'Échec de la mise à jour'),
                          backgroundColor: ok ? AppColors.success : AppColors.error,
                        ));
                      }
                    },
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showVehicleDetails() {
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    String vehicleType = 'motorcycle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Détails du véhicule',
                    style: TextStyle(color: AppColors.textOnDark, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _DarkField(ctrl: makeCtrl, label: 'Marque (ex. Honda)', icon: HugeIcons.strokeRoundedMotorbike01),
                const SizedBox(height: 12),
                _DarkField(ctrl: modelCtrl, label: 'Modèle (ex. CB200)', icon: HugeIcons.strokeRoundedMotorbike02),
                const SizedBox(height: 12),
                _DarkField(ctrl: plateCtrl, label: 'Numéro de plaque', icon: HugeIcons.strokeRoundedCreditCard),
                const SizedBox(height: 12),
                _DarkField(ctrl: colorCtrl, label: 'Couleur', icon: HugeIcons.strokeRoundedColorPicker),
                const SizedBox(height: 12),
                // Vehicle type selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Type de véhicule',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        {'value': 'motorcycle', 'label': 'Moto', 'icon': HugeIcons.strokeRoundedMotorbike01},
                        {'value': 'bicycle', 'label': 'Vélo', 'icon': HugeIcons.strokeRoundedBicycle01},
                        {'value': 'car', 'label': 'Voiture', 'icon': HugeIcons.strokeRoundedCar01},
                      ].map((item) {
                        final selected = vehicleType == item['value'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => vehicleType = item['value'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.backgroundDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? AppColors.primary : AppColors.borderDark,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  HugeIcon(icon: item['icon'] as IconData,
                                      color: selected ? AppColors.primary : AppColors.textSecondary,
                                      size: 22),
                                  const SizedBox(height: 4),
                                  Text(item['label'] as String,
                                      style: TextStyle(
                                        color: selected ? AppColors.primary : AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: saving ? null : () async {
                      setModalState(() => saving = true);
                      final ok = await ref.read(authProvider).updateVehicle({
                        'vehicleMake': makeCtrl.text.trim(),
                        'vehicleModel': modelCtrl.text.trim(),
                        'vehiclePlate': plateCtrl.text.trim(),
                        'vehicleColor': colorCtrl.text.trim(),
                        'vehicleType': vehicleType,
                      });
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Véhicule mis à jour' : 'Échec de la mise à jour'),
                          backgroundColor: ok ? AppColors.success : AppColors.error,
                        ));
                      }
                    },
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showDocumentUpload() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedLicense, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  const Text('Télécharger un document', style: TextStyle(color: AppColors.textOnDark, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ),
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: AppColors.textSecondary, size: 20),
                title: const Text('Prendre une photo', style: TextStyle(color: AppColors.textOnDark)),
                onTap: () => Navigator.pop(_, 'camera'),
              ),
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: AppColors.textSecondary, size: 20),
                title: const Text('Choisir dans la galerie', style: TextStyle(color: AppColors.textOnDark)),
                onTap: () => Navigator.pop(_, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;

    final source = result == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await ApiService.uploadDriverDocuments([file.path]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document téléchargé avec succès'), backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du téléchargement du document'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aide & Support',
                  style: TextStyle(color: AppColors.textOnDark, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _SupportTile(
                icon: HugeIcons.strokeRoundedMail01,
                title: 'Support par e-mail',
                subtitle: 'support@kubochain.com',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _SupportTile(
                icon: HugeIcons.strokeRoundedPhoneCheck,
                title: 'Appelez-nous',
                subtitle: '+243 XXX XXX XXX',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _SupportTile(
                icon: HugeIcons.strokeRoundedMessage01,
                title: 'Chat en direct',
                subtitle: 'Discutez avec notre équipe',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _SupportTile(
                icon: HugeIcons.strokeRoundedInformationCircle,
                title: 'FAQ',
                subtitle: 'Questions fréquentes',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final avatarColor = AvatarPickerSheet.presets[_avatarColorIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Aurora Hero Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5), Color(0xFFF5F8FF)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AmbientOrbs(
                      color: AppColors.success,
                      orbCount: 3,
                      maxOpacity: 0.07,
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Profil',
                              style: GoogleFonts.sora(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.10),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                PressScale(
                                  scale: 0.92,
                                  onTap: _pickAndUploadPhoto,
                                  child: GestureDetector(
                                    onLongPress: () => _openAvatarPicker(user?.firstName ?? 'D'),
                                    child: Stack(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 400),
                                          curve: AppColors.springEasing,
                                          width: 80, height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: avatarColor,
                                            boxShadow: [
                                              BoxShadow(
                                                color: avatarColor.withValues(alpha: 0.40),
                                                blurRadius: 20,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: UserAvatar(
                                              name: user?.firstName ?? 'D',
                                              imageUrl: user?.profileImage != null
                                                  ? ApiService.imageUrl(user!.profileImage!)
                                                  : null,
                                              radius: 40,
                                              backgroundColor: avatarColor,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0, right: 0,
                                          child: Container(
                                            width: 28, height: 28,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.riderGradient,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.success.withValues(alpha: 0.30),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: _uploading
                                                ? const Padding(
                                                    padding: EdgeInsets.all(5),
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                  )
                                                : const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.fullName ?? 'Conducteur',
                                        style: GoogleFonts.sora(
                                          color: AppColors.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        user?.phone ?? '',
                                        style: GoogleFonts.sora(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.success.withValues(alpha: 0.12),
                                              AppColors.success.withValues(alpha: 0.06),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(50),
                                          border: Border.all(
                                            color: AppColors.success.withValues(alpha: 0.22),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const HugeIcon(icon: HugeIcons.strokeRoundedShieldUser, color: AppColors.success, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Conducteur Vérifié',
                                              style: GoogleFonts.sora(
                                                color: AppColors.success,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _PremiumStatCard(
                        value: '${user?.totalRides ?? 0}',
                        label: 'Courses totales',
                        icon: HugeIcons.strokeRoundedMotorbike01,
                        color: AppColors.success,
                        gradient: AppColors.riderGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PremiumStatCard(
                        value: '${user?.rating ?? 5.0}',
                        label: 'Note',
                        icon: HugeIcons.strokeRoundedStar,
                        color: AppColors.gold,
                        gradient: AppColors.safetyGradient,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _PremiumMenuSection(
                  title: 'COMPTE',
                  icon: HugeIcons.strokeRoundedUser,
                  iconColor: AppColors.success,
                  items: [
                    _PremiumMenuItem(
                      icon: HugeIcons.strokeRoundedUser,
                      label: 'Modifier le profil',
                      iconColor: AppColors.primary,
                      onTap: _showEditProfile,
                    ),
                    _PremiumMenuItem(
                      icon: HugeIcons.strokeRoundedMotorbike01,
                      label: 'Détails du véhicule',
                      iconColor: AppColors.success,
                      onTap: _showVehicleDetails,
                    ),
                    _PremiumMenuItem(
                      icon: HugeIcons.strokeRoundedLicense,
                      label: 'Documents',
                      iconColor: AppColors.safetyGold,
                      onTap: _showDocumentUpload,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _PremiumMenuSection(
                  title: 'SUPPORT',
                  icon: HugeIcons.strokeRoundedHelpCircle,
                  iconColor: AppColors.primary,
                  items: [
                    _PremiumMenuItem(
                      icon: HugeIcons.strokeRoundedNotification01,
                      label: 'Notifications',
                      iconColor: AppColors.indigo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                    ),
                    _PremiumMenuItem(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      label: 'Aide & Support',
                      iconColor: AppColors.primary,
                      onTap: _showHelpSupport,
                    ),
                    _PremiumMenuItem(
                      icon: HugeIcons.strokeRoundedLogout01,
                      label: 'Se déconnecter',
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      showArrow: false,
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const OnBoardingPage()),
                            (r) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 110),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable dark text field ──────────────────────────────────────────────────
class _DarkField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _DarkField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textOnDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: HugeIcon(icon: icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Support tile ─────────────────────────────────────────────────────────────
class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: HugeIcon(icon: icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textOnDark, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}

// ── Premium Stat Card ─────────────────────────────────────────────────────────
class _PremiumStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  const _PremiumStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: HugeIcon(icon: icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Premium Menu Section ───────────────────────────────────────────────────────
class _PremiumMenuSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_PremiumMenuItem> items;

  const _PremiumMenuSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(icon: icon, color: iconColor, size: 13),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderDark),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  item,
                  if (!isLast) Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 58),
                    color: AppColors.divider,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Premium Menu Item ─────────────────────────────────────────────────────────
class _PremiumMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final bool showArrow;

  const _PremiumMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.textColor = AppColors.textOnDark,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconColor == AppColors.error
                    ? AppColors.error.withValues(alpha: 0.08)
                    : iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HugeIcon(icon: icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.sora(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showArrow)
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textMuted,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
