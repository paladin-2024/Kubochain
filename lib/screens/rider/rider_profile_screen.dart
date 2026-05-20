import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../providers/providers.dart';
import '../../screens/onboarding.dart';
import '../common/notifications_screen.dart';

class RiderProfileScreen extends ConsumerStatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  ConsumerState<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends ConsumerState<RiderProfileScreen> {
  bool _uploading = false;

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
              title: const Text('Camera', style: TextStyle(color: AppColors.textOnDark)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: AppColors.textOnDark, size: 20),
              title: const Text('Gallery', style: TextStyle(color: AppColors.textOnDark)),
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
          const SnackBar(content: Text('Failed to upload photo')),
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
                const Text('Edit Profile',
                    style: TextStyle(color: AppColors.textOnDark, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _DarkField(ctrl: firstCtrl, label: 'First Name', icon: HugeIcons.strokeRoundedUser),
                const SizedBox(height: 12),
                _DarkField(ctrl: lastCtrl, label: 'Last Name', icon: HugeIcons.strokeRoundedUser),
                const SizedBox(height: 12),
                _DarkField(ctrl: emailCtrl, label: 'Email', icon: HugeIcons.strokeRoundedMail01, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _DarkField(ctrl: phoneCtrl, label: 'Phone', icon: HugeIcons.strokeRoundedPhoneCheck, keyboardType: TextInputType.phone),
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
                          content: Text(ok ? 'Profile updated' : 'Failed to update'),
                          backgroundColor: ok ? AppColors.success : AppColors.error,
                        ));
                      }
                    },
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                const Text('Vehicle Details',
                    style: TextStyle(color: AppColors.textOnDark, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _DarkField(ctrl: makeCtrl, label: 'Make (e.g. Honda)', icon: HugeIcons.strokeRoundedMotorbike01),
                const SizedBox(height: 12),
                _DarkField(ctrl: modelCtrl, label: 'Model (e.g. CB200)', icon: HugeIcons.strokeRoundedMotorbike02),
                const SizedBox(height: 12),
                _DarkField(ctrl: plateCtrl, label: 'Plate Number', icon: HugeIcons.strokeRoundedCreditCard),
                const SizedBox(height: 12),
                _DarkField(ctrl: colorCtrl, label: 'Color', icon: HugeIcons.strokeRoundedColorPicker),
                const SizedBox(height: 12),
                // Vehicle type selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vehicle Type',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        {'value': 'motorcycle', 'label': 'Moto', 'icon': HugeIcons.strokeRoundedMotorbike01},
                        {'value': 'bicycle', 'label': 'Bicycle', 'icon': HugeIcons.strokeRoundedBicycle01},
                        {'value': 'car', 'label': 'Car', 'icon': HugeIcons.strokeRoundedCar01},
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
                          content: Text(ok ? 'Vehicle updated' : 'Failed to update'),
                          backgroundColor: ok ? AppColors.success : AppColors.error,
                        ));
                      }
                    },
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  const Text('Upload Document', style: TextStyle(color: AppColors.textOnDark, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ),
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: AppColors.textSecondary, size: 20),
                title: const Text('Take Photo', style: TextStyle(color: AppColors.textOnDark)),
                onTap: () => Navigator.pop(_, 'camera'),
              ),
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: AppColors.textSecondary, size: 20),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textOnDark)),
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
          const SnackBar(content: Text('Document uploaded successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload document'), backgroundColor: AppColors.error),
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
              const Text('Help & Support',
                  style: TextStyle(color: AppColors.textOnDark, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _SupportTile(
                icon: HugeIcons.strokeRoundedMail01,
                title: 'Email Support',
                subtitle: 'support@kubochain.com',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _SupportTile(
                icon: HugeIcons.strokeRoundedPhoneCheck,
                title: 'Call Us',
                subtitle: '+243 XXX XXX XXX',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _SupportTile(
                icon: HugeIcons.strokeRoundedMessage01,
                title: 'Live Chat',
                subtitle: 'Chat with our support team',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _SupportTile(
                icon: HugeIcons.strokeRoundedInformationCircle,
                title: 'FAQ',
                subtitle: 'Frequently asked questions',
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

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundDark,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFEFF6FF), Color(0xFFF5F8FF)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              backgroundImage: user?.profileImage != null
                                  ? CachedNetworkImageProvider(
                                      ApiService.imageUrl(user!.profileImage!))
                                  : null,
                              child: user?.profileImage == null
                                  ? Text(
                                      (user?.firstName ?? 'D')[0].toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 34,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
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
                      const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? 'Driver',
                        style: const TextStyle(color: AppColors.textOnDark, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.phone ?? '',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(
                  children: [
                    Expanded(child: _DarkStatCard(value: '${user?.totalRides ?? 0}', label: 'Total Trips')),
                    const SizedBox(width: 12),
                    Expanded(child: _DarkStatCard(value: '${user?.rating ?? 5.0}', label: 'Rating')),
                  ],
                ),
                const SizedBox(height: 16),

                _DarkMenuSection(
                  title: 'ACCOUNT',
                  items: [
                    _DarkMenuItem(
                      icon: HugeIcons.strokeRoundedUser,
                      label: 'Edit Profile',
                      onTap: _showEditProfile,
                    ),
                    _DarkMenuItem(
                      icon: HugeIcons.strokeRoundedMotorbike01,
                      label: 'Vehicle Details',
                      onTap: _showVehicleDetails,
                    ),
                    _DarkMenuItem(
                      icon: HugeIcons.strokeRoundedLicense,
                      label: 'Documents',
                      onTap: _showDocumentUpload,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _DarkMenuSection(
                  title: 'SUPPORT',
                  items: [
                    _DarkMenuItem(
                      icon: HugeIcons.strokeRoundedNotification01,
                      label: 'Notifications',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                    ),
                    _DarkMenuItem(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      label: 'Help & Support',
                      onTap: _showHelpSupport,
                    ),
                    _DarkMenuItem(
                      icon: HugeIcons.strokeRoundedLogout01,
                      label: 'Log Out',
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
                const SizedBox(height: 32),
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

// ── Stat card ─────────────────────────────────────────────────────────────────
class _DarkStatCard extends StatelessWidget {
  final String value;
  final String label;
  const _DarkStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Menu section ──────────────────────────────────────────────────────────────
class _DarkMenuSection extends StatelessWidget {
  final String title;
  final List<_DarkMenuItem> items;
  const _DarkMenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  item,
                  if (!isLast) Divider(height: 1, indent: 56, color: AppColors.borderDark),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Menu item ─────────────────────────────────────────────────────────────────
class _DarkMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final bool showArrow;

  const _DarkMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.textColor = AppColors.textOnDark,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: HugeIcon(icon: icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: showArrow ? const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.textSecondary, size: 20) : null,
      onTap: onTap,
    );
  }
}
