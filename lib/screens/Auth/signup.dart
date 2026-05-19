import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/api_service.dart';
import 'driver_vehicle_setup_screen.dart';
import 'login.dart';
import 'phone_verification_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  static const String _countryCode = '+243';
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String _selectedRole = 'passenger';
  bool _isSendingOtp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final userData = {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': '$_countryCode${_phoneCtrl.text.trim()}',
      'password': _passwordCtrl.text,
      'role': _selectedRole,
    };

    if (_selectedRole == 'rider') {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => DriverVehicleSetupScreen(userData: userData),
          transitionsBuilder: (_, anim, __, child) =>
              SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
        ),
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    String? devOtp;
    try {
      final res = await ApiService.sendOtp(_phoneCtrl.text.trim());
      devOtp = res.data['devOtp'] as String?;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: ${e.toString()}',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() => _isSendingOtp = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (devOtp != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DEV — OTP: $devOtp',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          duration: const Duration(seconds: 30),
          backgroundColor: const Color(0xFFEA580C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => PhoneVerificationScreen(userData: userData),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softShadow,
                        ),
                        child: const Icon(
                          HugeIcons.strokeRoundedArrowLeft01,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Headline
                          Text(
                            'Créez votre\ncompte.',
                            style: GoogleFonts.sora(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.1,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rejoignez des milliers de voyageurs à Goma.',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Role selector
                          _SectionLabel(label: 'Je suis...'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _RoleCard(
                                label: 'Passager',
                                subtitle: 'Je veux voyager',
                                icon: HugeIcons.strokeRoundedUser,
                                selected: _selectedRole == 'passenger',
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedRole = 'passenger');
                                },
                              ),
                              const SizedBox(width: 12),
                              _RoleCard(
                                label: 'Conducteur',
                                subtitle: 'Je veux conduire',
                                icon: HugeIcons.strokeRoundedMotorbike01,
                                selected: _selectedRole == 'rider',
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedRole = 'rider');
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Name row
                          Row(
                            children: [
                              Expanded(
                                child: _FieldGroup(
                                  label: 'Prénom',
                                  child: _SignupField(
                                    controller: _firstNameCtrl,
                                    hint: 'Jean',
                                    icon: HugeIcons.strokeRoundedUserCircle,
                                    validator: (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _FieldGroup(
                                  label: 'Nom',
                                  child: _SignupField(
                                    controller: _lastNameCtrl,
                                    hint: 'Kalinda',
                                    icon: HugeIcons.strokeRoundedUserCircle,
                                    validator: (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _FieldGroup(
                            label: 'Adresse e-mail',
                            child: _SignupField(
                              controller: _emailCtrl,
                              hint: 'vous@exemple.com',
                              icon: HugeIcons.strokeRoundedAt,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                                if (!v.contains('@')) return AppStrings.invalidEmail;
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          _FieldGroup(
                            label: 'Numéro de téléphone',
                            child: _PhoneSignupField(controller: _phoneCtrl),
                          ),

                          const SizedBox(height: 16),

                          _FieldGroup(
                            label: 'Mot de passe',
                            child: _SignupField(
                              controller: _passwordCtrl,
                              hint: '••••••••',
                              icon: HugeIcons.strokeRoundedLock,
                              obscureText: _obscurePassword,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                                if (v.length < 6) return AppStrings.passwordTooShort;
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          _FieldGroup(
                            label: 'Confirmer le mot de passe',
                            child: _SignupField(
                              controller: _confirmPasswordCtrl,
                              hint: '••••••••',
                              icon: HugeIcons.strokeRoundedLock,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                child: Icon(
                                  _obscureConfirm ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                                if (v != _passwordCtrl.text) return AppStrings.passwordMismatch;
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Submit
                          _SubmitButton(
                            label: _selectedRole == 'rider' ? 'Continuer vers la configuration' : 'Envoyer le code de vérification',
                            isLoading: _isSendingOtp,
                            onTap: _signup,
                          ),

                          const SizedBox(height: 28),

                          // Log in link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 300),
                                    pageBuilder: (_, __, ___) => const LoginPage(),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        FadeTransition(opacity: anim, child: child),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Déjà un compte ? '),
                                    TextSpan(
                                      text: 'Se connecter',
                                      style: GoogleFonts.sora(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.sora(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 0.2,
    ),
  );
}

class _FieldGroup extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionLabel(label: label),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _SignupField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _SignupField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.softShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textHint),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: AppColors.textMuted, size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 44),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          errorStyle: GoogleFonts.dmSans(fontSize: 11, color: AppColors.error),
        ),
      ),
    );
  }
}

class _PhoneSignupField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneSignupField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.softShadow,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
          if (v.trim().length < 8) return 'Numéro de téléphone invalide';
          return null;
        },
        decoration: InputDecoration(
          hintText: '812 345 678',
          hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textHint),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇨🇩', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 5),
                Text(
                  '+243',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 7),
                Container(width: 1, height: 20, color: AppColors.border),
                const SizedBox(width: 7),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          errorStyle: GoogleFonts.dmSans(fontSize: 11, color: AppColors.error),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))]
              : AppColors.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.sora(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                color: selected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SubmitButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => _press.forward(),
        onTapUp: widget.isLoading ? null : (_) { _press.reverse(); widget.onTap(); },
        onTapCancel: () => _press.reverse(),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: widget.isLoading ? AppColors.primary.withOpacity(0.7) : AppColors.primary,
            borderRadius: BorderRadius.circular(50),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
