import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/api_service.dart';
import '../../providers/auth_provider.dart' show AuthProvider;
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'driver_vehicle_setup_screen.dart';
import 'login.dart';
import 'phone_verification_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String _selectedRole = 'passenger';
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final userData = {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'role': _selectedRole,
    };

    if (_selectedRole == 'rider') {
      // Riders complete vehicle setup first — OTP is sent from that screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverVehicleSetupScreen(userData: userData),
        ),
      );
      return;
    }

    // Passengers go straight to OTP
    setState(() => _isSendingOtp = true);
    String? devOtp;
    try {
      final res = await ApiService.sendOtp(_phoneCtrl.text.trim());
      devOtp = res.data['devOtp'] as String?;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: ${e.toString()}')),
      );
      setState(() => _isSendingOtp = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (devOtp != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DEV MODE — Your OTP is: $devOtp'),
          duration: const Duration(seconds: 30),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneVerificationScreen(userData: userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join KuboChain',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Role selector
                Text(
                  AppStrings.selectRole,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _RoleCard(
                      label: AppStrings.passenger,
                      icon: Icons.person_outline,
                      selected: _selectedRole == 'passenger',
                      onTap: () => setState(() => _selectedRole = 'passenger'),
                    ),
                    const SizedBox(width: 12),
                    _RoleCard(
                      label: AppStrings.rider,
                      icon: Icons.directions_bike_outlined,
                      selected: _selectedRole == 'rider',
                      onTap: () => setState(() => _selectedRole = 'rider'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name row
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        hint: 'First Name',
                        label: 'First Name',
                        controller: _firstNameCtrl,
                        validator: (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        hint: 'Last Name',
                        label: 'Last Name',
                        controller: _lastNameCtrl,
                        validator: (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AppTextField(
                  hint: 'Email address',
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (!v.contains('@')) return AppStrings.invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  hint: '+250 700 000 000',
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  validator: (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  hint: 'Password',
                  label: 'Password',
                  controller: _passwordCtrl,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (v.length < 6) return AppStrings.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  hint: 'Confirm Password',
                  label: 'Confirm Password',
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (v != _passwordCtrl.text) return AppStrings.passwordMismatch;
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: _selectedRole == 'rider' ? 'Continue' : 'Send Verification Code',
                  onPressed: _signup,
                  isLoading: _isSendingOtp,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.haveAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      child: const Text(
                        AppStrings.login,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
