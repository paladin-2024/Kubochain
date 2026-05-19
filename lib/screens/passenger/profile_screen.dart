import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../providers/providers.dart';
import '../../screens/onboarding.dart';
import '../common/about_screen.dart';
import '../common/help_support_screen.dart';

class PassengerProfileScreen extends ConsumerStatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  ConsumerState<PassengerProfileScreen> createState() =>
      _PassengerProfileScreenState();
}

class _PassengerProfileScreenState
    extends ConsumerState<PassengerProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _uploading = false;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file == null) return;

    setState(() => _uploading = true);
    if (!mounted) return;
    try {
      final ok = await ref.read(authProvider).updateProfileImage(file.path);
      if (mounted) {
        setState(() => _uploading = false);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload photo.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    }
  }

  Future<void> _showEditDialog(
      String label, String currentValue, String field) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditDialog(
        label: label,
        controller: controller,
        onSave: (val) => Navigator.pop(ctx, val),
        onCancel: () => Navigator.pop(ctx),
      ),
    );

    if (result == null || result == currentValue || !mounted) return;

    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null) return;

    final ok = await auth.updateProfile(
      firstName: field == 'firstName' ? result : user.firstName,
      lastName: field == 'lastName' ? result : user.lastName,
      email: field == 'email' ? result : user.email,
      phone: field == 'phone' ? result : user.phone,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile updated' : 'Failed to update',
            style: GoogleFonts.dmSans()),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final ride = ref.watch(rideProvider);
    final user = auth.user;
    final completedRides =
        ride.rideHistory.where((r) => r.isCompleted).length;
    final totalSpent = ride.rideHistory
        .where((r) => r.isCompleted)
        .fold<double>(0, (s, r) => s + r.price);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Page title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    'Profile',
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // Avatar hero card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.15)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.primary.withOpacity(0.35),
                                    blurRadius: 20,
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: user?.profileImage != null
                                    ? CachedNetworkImage(
                                        imageUrl: ApiService.imageUrl(
                                            user!.profileImage!),
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            const SizedBox(),
                                        errorWidget: (_, __, ___) =>
                                            _AvatarFallback(user: user),
                                      )
                                    : _AvatarFallback(user: user),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.softShadow,
                                ),
                                child: _uploading
                                    ? const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(HugeIcons.strokeRoundedCamera01,
                                        size: 14,
                                        color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'User',
                              style: GoogleFonts.sora(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.phone ?? '',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color:
                                        AppColors.success.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(HugeIcons.strokeRoundedShieldUser,
                                      color: AppColors.success, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified Passenger',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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

              // Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: HugeIcons.strokeRoundedMotorbike01,
                          label: 'Total Trips',
                          value: '$completedRides',
                          color: AppColors.primary,
                          bgColor: AppColors.primary.withOpacity(0.07),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: HugeIcons.strokeRoundedWallet01,
                          label: 'Total Spent',
                          value: 'FC ${totalSpent.toStringAsFixed(0)}',
                          color: AppColors.success,
                          bgColor: AppColors.success.withOpacity(0.07),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: HugeIcons.strokeRoundedShield01,
                          label: 'Safety Score',
                          value: '100%',
                          color: AppColors.safetyGold,
                          bgColor: AppColors.safetyGold.withOpacity(0.07),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Personal info
              SliverToBoxAdapter(
                child: _SectionCard(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  title: 'Personal Info',
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: HugeIcons.strokeRoundedUser,
                        label: 'First name',
                        value: user?.firstName ?? '',
                        onTap: () => _showEditDialog(
                            'First name',
                            user?.firstName ?? '',
                            'firstName'),
                      ),
                      const _TileDivider(),
                      _InfoTile(
                        icon: HugeIcons.strokeRoundedUser,
                        label: 'Last name',
                        value: user?.lastName ?? '',
                        onTap: () => _showEditDialog(
                            'Last name',
                            user?.lastName ?? '',
                            'lastName'),
                      ),
                      const _TileDivider(),
                      _InfoTile(
                        icon: HugeIcons.strokeRoundedMail01,
                        label: 'Email',
                        value: user?.email ?? '',
                        onTap: () => _showEditDialog(
                            'Email', user?.email ?? '', 'email'),
                      ),
                      const _TileDivider(),
                      _InfoTile(
                        icon: HugeIcons.strokeRoundedSmartPhone01,
                        label: 'Phone',
                        value: user?.phone ?? '',
                        trailing: _VerifiedBadge(),
                      ),
                    ],
                  ),
                ),
              ),

              // Safety & Trust
              SliverToBoxAdapter(
                child: _SectionCard(
                  margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  title: 'Safety & Trust',
                  child: Column(
                    children: const [
                      _TrustRow(
                        icon: HugeIcons.strokeRoundedShieldUser,
                        label: 'Phone Verified',
                        active: true,
                      ),
                      _TileDivider(),
                      _TrustRow(
                        icon: HugeIcons.strokeRoundedLock,
                        label: 'Account Secured',
                        active: true,
                      ),
                      _TileDivider(),
                      _TrustRow(
                        icon: HugeIcons.strokeRoundedLocation01,
                        label: 'Location Services',
                        active: true,
                      ),
                    ],
                  ),
                ),
              ),

              // More
              SliverToBoxAdapter(
                child: _SectionCard(
                  margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  title: 'More',
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: HugeIcons.strokeRoundedHelpCircle,
                        label: 'Help & Support',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HelpSupportScreen()),
                        ),
                      ),
                      const _TileDivider(),
                      _ActionTile(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        label: 'About KuboChain',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AboutScreen()),
                        ),
                      ),
                      const _TileDivider(),
                      _ActionTile(
                        icon: HugeIcons.strokeRoundedLogoutSquare01,
                        label: 'Log Out',
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                        showChevron: false,
                        onTap: () async {
                          await ref.read(authProvider).logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const OnBoardingPage()),
                            (r) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Dialog ────────────────────────────────────────────────────────────────
class _EditDialog extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const _EditDialog({
    required this.label,
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit $label',
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: GoogleFonts.dmSans(
                      color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.sora(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSave(controller.text.trim()),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Save',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar Fallback ────────────────────────────────────────────────────────────
class _AvatarFallback extends StatelessWidget {
  final dynamic user;
  const _AvatarFallback({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        (user?.firstName ?? 'U')[0].toUpperCase(),
        style: GoogleFonts.sora(
          fontSize: 32,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Verified Badge ─────────────────────────────────────────────────────────────
class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(HugeIcons.strokeRoundedCheckmarkCircle01,
              size: 11, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: GoogleFonts.dmSans(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Section Card ───────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final EdgeInsets margin;
  final String title;
  final Widget child;

  const _SectionCard(
      {required this.margin, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Tile Divider ───────────────────────────────────────────────────────────────
class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: AppColors.borderDark,
    );
  }
}

// ── Info Tile ──────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '—' : value,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              const Icon(HugeIcons.strokeRoundedEdit01,
                  size: 15, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Trust Row ──────────────────────────────────────────────────────────────────
class _TrustRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _TrustRow(
      {required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.success.withOpacity(0.08)
                  : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18,
                color: active ? AppColors.success : AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.success.withOpacity(0.08)
                  : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: active
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.border,
              ),
            ),
            child: Text(
              active ? 'Active' : 'Inactive',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Tile ────────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final bool showChevron;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.textColor = AppColors.textPrimary,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (showChevron)
              const Icon(HugeIcons.strokeRoundedArrowRight01,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Photo Source Sheet ─────────────────────────────────────────────────────────
class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Update Photo',
                style: GoogleFonts.sora(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _SourceOption(
              icon: HugeIcons.strokeRoundedCamera01,
              label: 'Take Photo',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            Container(
                height: 1,
                color: AppColors.border,
                margin: const EdgeInsets.only(left: 56)),
            _SourceOption(
              icon: HugeIcons.strokeRoundedImage01,
              label: 'Choose from Gallery',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
