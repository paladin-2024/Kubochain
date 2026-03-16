import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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

class _DriverVehicleSetupScreenState extends State<DriverVehicleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _vehicleType = 'motorcycle';
  bool _loading = false;

  static const _docLabels = ['National ID', "Driver's Licence", 'Vehicle Insurance'];
  final _docPaths = <String?>[null, null, null];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDoc(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload ${_docLabels[index]}',
                style: GoogleFonts.sora(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _SheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
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
        content: Text('DEV MODE — Your OTP is: $devOtp'),
        duration: const Duration(seconds: 30),
        backgroundColor: Colors.orange.shade800,
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
      content: Text(msg, style: GoogleFonts.sora()),
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
          // Header
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(bottom: BorderSide(color: AppColors.borderDark)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textOnDark),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vehicle Details',
                              style: GoogleFonts.sora(
                                color: AppColors.textOnDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              )),
                          Text('Step 2 of 3 — Driver Verification',
                              style: GoogleFonts.sora(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                            color: filled ? AppColors.primary : AppColors.borderDark,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final e in [('Account', 0), ('Vehicle', 1), ('Verify', 2)])
                  Text(
                    e.$1,
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight:
                          e.$2 == 1 ? FontWeight.w700 : FontWeight.w400,
                      color: e.$2 == 1
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Form body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + safeBottom),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Vehicle Type'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _VehicleTypePill(
                          icon: Icons.directions_bike_rounded,
                          label: 'Motorcycle',
                          value: 'motorcycle',
                          selected: _vehicleType == 'motorcycle',
                          onTap: () =>
                              setState(() => _vehicleType = 'motorcycle'),
                        ),
                        const SizedBox(width: 10),
                        _VehicleTypePill(
                          icon: Icons.electric_bike_rounded,
                          label: 'Electric Bike',
                          value: 'electric',
                          selected: _vehicleType == 'electric',
                          onTap: () =>
                              setState(() => _vehicleType = 'electric'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _SectionLabel('Plate Number'),
                    const SizedBox(height: 10),
                    _DarkField(
                      controller: _plateCtrl,
                      hint: 'e.g. RAB 123A',
                      prefixIcon: Icons.credit_card_rounded,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Plate number is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('Make / Brand'),
                              const SizedBox(height: 10),
                              _DarkField(
                                controller: _makeCtrl,
                                hint: 'e.g. Honda',
                                prefixIcon: Icons.motorcycle_rounded,
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
                              _SectionLabel('Model'),
                              const SizedBox(height: 10),
                              _DarkField(
                                controller: _modelCtrl,
                                hint: 'e.g. CB150R',
                                prefixIcon: Icons.two_wheeler_rounded,
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

                    _SectionLabel('Vehicle Color'),
                    const SizedBox(height: 10),
                    _DarkField(
                      controller: _colorCtrl,
                      hint: 'e.g. Black, Red, Silver',
                      prefixIcon: Icons.palette_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Color is required'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    // Documents
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
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload clear photos or scans. Reviewed within 24 hours.',
                      style: GoogleFonts.sora(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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

                    const SizedBox(height: 24),

                    // Continue button
                    GestureDetector(
                      onTap: _loading ? null : _handleContinue,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient:
                              _loading ? null : AppColors.primaryGradient,
                          color: _loading ? AppColors.borderDark : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _loading
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: _loading
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
                                    const Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.sora(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.validator,
    this.textCapitalization = TextCapitalization.words,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        textCapitalization: textCapitalization,
        style: GoogleFonts.sora(color: AppColors.textOnDark, fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.sora(color: AppColors.textHint, fontSize: 14),
          filled: true,
          fillColor: AppColors.cardDark,
          prefixIcon:
              Icon(prefixIcon, color: AppColors.textSecondary, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
      );
}

class _VehicleTypePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleTypePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderDark,
                width: selected ? 1.5 : 1,
              ),
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
                  style: GoogleFonts.sora(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: uploaded
              ? AppColors.success.withOpacity(0.07)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded
                ? AppColors.success.withOpacity(0.4)
                : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: uploaded
                    ? AppColors.success.withOpacity(0.12)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                uploaded
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_rounded,
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
                          color: AppColors.textOnDark,
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
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: GoogleFonts.sora(
                              color: AppColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
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
                        : 'Tap to upload (photo or PDF)',
                    style: GoogleFonts.sora(
                      color: uploaded
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              uploaded ? Icons.edit_rounded : Icons.add_rounded,
              color:
                  uploaded ? AppColors.success : AppColors.textSecondary,
              size: 18,
            ),
          ],
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.sora(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
}
