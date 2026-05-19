import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'phone_verification_screen.dart';

class DriverVehicleSetupScreen extends StatefulWidget {
  final Map<String, String> userData;

  const DriverVehicleSetupScreen({super.key, required this.userData});

  @override
  State<DriverVehicleSetupScreen> createState() =>
      _DriverVehicleSetupScreenState();
}

class _DriverVehicleSetupScreenState extends State<DriverVehicleSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _vehicleType = 'motorcycle';
  bool _loading = false;

  late AnimationController _entryCtrl;

  static const _docLabels = [
    'National ID',
    "Driver's Licence",
    'Vehicle Insurance'
  ];
  final _docPaths = <String?>[null, null, null];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDoc(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DocPickerSheet(label: _docLabels[index]),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file != null) setState(() => _docPaths[index] = file.path);
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_docPaths[0] == null) {
      _snack('Please upload your National ID to continue', AppColors.error);
      return;
    }

    setState(() => _loading = true);
    String? devOtp;
    try {
      final res = await ApiService.sendOtp(widget.userData['phone']!);
      devOtp = res.data['devOtp'] as String?;
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to send OTP: $e', AppColors.error);
      setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (devOtp != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('DEV MODE — Your OTP is: $devOtp',
            style: GoogleFonts.dmSans()),
        duration: const Duration(seconds: 30),
        backgroundColor: AppColors.warning,
      ));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneVerificationScreen(
          userData: widget.userData,
          vehicleData: {
            'plateNumber': _plateCtrl.text.trim().toUpperCase(),
            'make': _makeCtrl.text.trim(),
            'model': _modelCtrl.text.trim(),
            'color': _colorCtrl.text.trim(),
            'type': _vehicleType,
          },
          documentPaths: _docPaths.whereType<String>().toList(),
        ),
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01,
                              color: AppColors.textPrimary),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle Details',
                                style: GoogleFonts.sora(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Step 2 of 3 — Driver Verification',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      children: List.generate(3, (i) {
                        final filled = i <= 1;
                        return Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: filled
                                        ? AppColors.primaryGradient
                                        : null,
                                    color: filled
                                        ? null
                                        : AppColors.borderDark,
                                  ),
                                ),
                              ),
                              if (i < 2) const SizedBox(width: 6),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final e in [
                          ('Account', 0),
                          ('Vehicle', 1),
                          ('Verify', 2)
                        ])
                          Text(
                            e.$1,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: e.$2 == 1
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: e.$2 == 1
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Form ────────────────────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, child) => Opacity(
                opacity: _entryCtrl.value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - _entryCtrl.value)),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + safeBottom),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Vehicle Type'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _VehicleTypePill(
                            icon: HugeIcons.strokeRoundedBicycle01,
                            label: 'Motorcycle',
                            selected: _vehicleType == 'motorcycle',
                            onTap: () =>
                                setState(() => _vehicleType = 'motorcycle'),
                          ),
                          const SizedBox(width: 10),
                          _VehicleTypePill(
                            icon: HugeIcons.strokeRoundedMotorbike01,
                            label: 'Electric Bike',
                            selected: _vehicleType == 'electric',
                            onTap: () =>
                                setState(() => _vehicleType = 'electric'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      _FieldLabel('Plate Number'),
                      const SizedBox(height: 8),
                      _FormField(
                        controller: _plateCtrl,
                        hint: 'e.g. RAB 123A',
                        prefixIcon: HugeIcons.strokeRoundedCreditCard,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Plate number is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel('Make / Brand'),
                                const SizedBox(height: 8),
                                _FormField(
                                  controller: _makeCtrl,
                                  hint: 'e.g. Honda',
                                  prefixIcon: HugeIcons.strokeRoundedMotorbike01,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel('Model'),
                                const SizedBox(height: 8),
                                _FormField(
                                  controller: _modelCtrl,
                                  hint: 'e.g. CB150R',
                                  prefixIcon: HugeIcons.strokeRoundedMotorbike02,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _FieldLabel('Vehicle Color'),
                      const SizedBox(height: 8),
                      _FormField(
                        controller: _colorCtrl,
                        hint: 'e.g. Black, Red, Silver',
                        prefixIcon: HugeIcons.strokeRoundedPaintBrush01,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Color is required'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      // Documents section
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Required Documents',
                            style: GoogleFonts.sora(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upload clear photos or scans. Reviewed within 24 hours.',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),

                      for (int i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DocumentUploadTile(
                            label: _docLabels[i],
                            required: i == 0,
                            filePath: _docPaths[i],
                            onTap: () => _pickDoc(i),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Continue button
                      _ContinueButton(
                          loading: _loading, onTap: _handleContinue),
                    ],
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

// ── Continue Button ────────────────────────────────────────────────────────────
class _ContinueButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;

  const _ContinueButton({required this.loading, required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
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
        onTapDown: widget.loading ? null : (_) => _ctrl.forward(),
        onTapUp: widget.loading
            ? null
            : (_) {
                _ctrl.reverse();
                widget.onTap();
              },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.loading ? null : AppColors.primaryGradient,
            color: widget.loading ? AppColors.borderDark : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.loading
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
            child: widget.loading
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
                        'Send Verification Code',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
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

// ── Field Label ────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      );
}

// ── Form Field ────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.validator,
    this.textCapitalization = TextCapitalization.words,
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
        textCapitalization: textCapitalization,
        style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
              color: AppColors.textHint, fontSize: 14),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Icon(prefixIcon,
              color: AppColors.textSecondary, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
      ),
    );
  }
}

// ── Vehicle Type Pill ──────────────────────────────────────────────────────────
class _VehicleTypePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleTypePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1.5,
              ),
              boxShadow: selected ? null : AppColors.softShadow,
            ),
            child: Column(
              children: [
                Icon(icon,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Document Upload Tile ───────────────────────────────────────────────────────
class _DocumentUploadTile extends StatelessWidget {
  final String label;
  final bool required;
  final String? filePath;
  final VoidCallback onTap;

  const _DocumentUploadTile({
    required this.label,
    required this.required,
    required this.filePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = filePath != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: uploaded
              ? AppColors.success.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded
                ? AppColors.success.withOpacity(0.35)
                : AppColors.border,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: uploaded
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                uploaded
                    ? HugeIcons.strokeRoundedCheckmarkCircle01
                    : HugeIcons.strokeRoundedUpload01,
                color: uploaded ? AppColors.success : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.sora(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (required) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: GoogleFonts.dmSans(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    uploaded
                        ? filePath!.split('/').last
                        : 'Tap to upload photo or PDF',
                    style: GoogleFonts.dmSans(
                      color: uploaded
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              uploaded ? HugeIcons.strokeRoundedEdit01 : HugeIcons.strokeRoundedAdd01,
              color: uploaded ? AppColors.success : AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Doc Picker Sheet ──────────────────────────────────────────────────────────
class _DocPickerSheet extends StatelessWidget {
  final String label;
  const _DocPickerSheet({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Upload $label',
                style: GoogleFonts.sora(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _SheetOption(
                icon: HugeIcons.strokeRoundedCamera01,
                label: 'Take Photo',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              _SheetOption(
                icon: HugeIcons.strokeRoundedImage01,
                label: 'Choose from Gallery',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
}
