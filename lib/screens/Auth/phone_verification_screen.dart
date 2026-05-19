import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../providers/providers.dart';
import '../../screens/rider/rider_main.dart';
import 'verified_screen.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final Map<String, String> userData;
  final Map<String, String>? vehicleData;
  final List<String>? documentPaths;

  const PhoneVerificationScreen({
    super.key,
    required this.userData,
    this.vehicleData,
    this.documentPaths,
  });

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSending = false;
  int _secondsLeft = 60;
  Timer? _timer;
  bool _hasError = false;

  late AnimationController _entryCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _startTimer();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryCtrl.dispose();
    _shakeCtrl.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _resendOtp() async {
    setState(() => _isSending = true);
    try {
      await ApiService.sendOtp(widget.userData['phone']!);
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Code envoyé !', style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Échec de l\'envoi.', style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verify() async {
    final raw = _otpCode;
    // Demo mode: tap verify with empty boxes → use bypass code
    final code = raw.length < 6 ? '000000' : raw;

    setState(() {
      _isVerifying = true;
      _hasError = false;
    });
    final auth = ref.read(authProvider);

    final ok = await auth.register(
      firstName: widget.userData['firstName']!,
      lastName: widget.userData['lastName']!,
      email: widget.userData['email']!,
      phone: widget.userData['phone']!,
      password: widget.userData['password']!,
      role: widget.userData['role']!,
      otpCode: code,
      vehicle: widget.vehicleData,
      documentPaths: widget.documentPaths,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (ok) {
      final role = auth.user?.role ?? 'passenger';
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              role == 'rider' ? const RiderMain() : const VerifiedScreen(),
        ),
        (route) => false,
      );
    } else {
      setState(() => _hasError = true);
      _shakeCtrl.forward(from: 0);
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Verification failed',
            style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _onDigitChanged(int index, String value) {
    if (_hasError) setState(() => _hasError = false);
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verify();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.userData['phone'] ?? '';
    final maskedPhone =
        phone.length > 4 ? '${phone.substring(0, phone.length - 4)}****' : phone;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AnimatedBuilder(
            animation: _entryCtrl,
            builder: (_, child) => Opacity(
              opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut)
                  .value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _entryCtrl.value)),
                child: child,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: const Icon(HugeIcons.strokeRoundedArrowLeft01,
                        color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(height: 40),

                // Icon mark
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.14)),
                  ),
                  child: const Icon(HugeIcons.strokeRoundedMailOpen01,
                      color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 24),

                Text(
                  'Vérifiez votre\ntéléphone.',
                  style: GoogleFonts.sora(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nous avons envoyé un code à 6 chiffres au $maskedPhone. Entrez-le ci-dessous pour vérifier.',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 44),

                // OTP row with shake
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) =>
                      Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        hasError: _hasError,
                        onChanged: (val) => _onDigitChanged(i, val),
                      ),
                    ),
                  ),
                ),

                // Error hint
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _hasError
                      ? Padding(
                          key: const ValueKey('err'),
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Code invalide ou incomplet. Réessayez.',
                            style: GoogleFonts.dmSans(
                                color: AppColors.error, fontSize: 13),
                          ),
                        )
                      : const SizedBox(key: ValueKey('no-err'), height: 10),
                ),
                const SizedBox(height: 32),

                // Verify button
                _VerifyButton(
                  isLoading: _isVerifying,
                  onTap: _isVerifying ? null : _verify,
                ),
                const SizedBox(height: 28),

                // Countdown / resend
                Center(
                  child: _secondsLeft > 0
                      ? _CountdownRow(seconds: _secondsLeft)
                      : _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            )
                          : GestureDetector(
                              onTap: _resendOtp,
                              child: Text(
                                'Renvoyer le code de vérification',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── OTP Box ────────────────────────────────────────────────────────────────────
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() => _focused = widget.focusNode.hasFocus);

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 46,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.hasError
              ? AppColors.error
              : _focused
                  ? AppColors.primary
                  : filled
                      ? AppColors.primary.withOpacity(0.35)
                      : AppColors.border,
          width: (_focused || widget.hasError) ? 2 : 1.5,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 12,
                )
              ]
            : AppColors.softShadow,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: widget.hasError ? AppColors.error : AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ── Verify Button ──────────────────────────────────────────────────────────────
class _VerifyButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _VerifyButton({required this.isLoading, required this.onTap});

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.isLoading ? null : AppColors.primaryGradient,
            color: widget.isLoading ? AppColors.border : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vérifier & Créer le compte',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(HugeIcons.strokeRoundedArrowRight01,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Countdown Row ──────────────────────────────────────────────────────────────
class _CountdownRow extends StatelessWidget {
  final int seconds;
  const _CountdownRow({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            value: seconds / 60,
            strokeWidth: 2,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Renvoyer dans ${seconds}s',
          style: GoogleFonts.dmSans(
              color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}
