import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/auth_service.dart';

/// Full-screen sign-in page.
/// After success → checks Supabase for saved cuisines:
///   has cuisines → /home  |  no cuisines → /onboarding
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _Step { signIn, forgotEmail, forgotOtp, forgotNewPass, forgotDone }

class _AuthScreenState extends State<AuthScreen> {
  _Step _step = _Step.signIn;

  // Sign-in
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // Forgot password
  final _forgotEmailCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _fpEmail = '';

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _forgotEmailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Navigation after successful auth ────────────────────────────────────────

  Future<void> _onSuccess() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('user_cuisines')
          .select('cuisine_id')
          .eq('user_id', uid);
      final hasCuisines = (rows as List).isNotEmpty;
      if (!mounted) return;
      context.go(hasCuisines ? AppRouter.home : AppRouter.onboarding);
    } catch (_) {
      if (!mounted) return;
      context.go(AppRouter.onboarding);
    }
  }

  // ── Sign in ──────────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.instance.signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      AnalyticsService.instance.logLogin();
      await _onSuccess();
    } else {
      setState(() => _error = err);
    }
  }

  // ── Forgot password ──────────────────────────────────────────────────────────

  Future<void> _sendForgotOtp() async {
    final email = _forgotEmailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.instance.sendPasswordResetOtp(email: email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      _fpEmail = email;
      setState(() => _step = _Step.forgotOtp);
    } else {
      setState(() => _error = err);
    }
  }

  Future<void> _verifyForgotOtp(String otp) async {
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.instance.verifyPasswordResetOtp(
        email: _fpEmail, token: otp);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      setState(() => _step = _Step.forgotNewPass);
    } else {
      setState(() => _error = err);
    }
  }

  Future<void> _updatePassword() async {
    final newPass = _newPassCtrl.text;
    if (newPass != _confirmPassCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    final passErr = AuthService.passwordError(newPass);
    if (passErr != null) { setState(() => _error = passErr); return; }
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.instance.updatePassword(newPassword: newPass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      AnalyticsService.instance.logPasswordReset();
      setState(() => _step = _Step.forgotDone);
    } else {
      setState(() => _error = err);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Forgot-password steps take the full screen (no bottom bar)
    if (_step != _Step.signIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: _buildForgotStep(),
          ),
        ),
      );
    }

    // ── Main sign-in layout ──────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content — vertically centered when space allows
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Logo + title + subtitle ──────────────────────
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: Image.asset(
                                        'assets/images/app_icon.png',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                            Icons.restaurant_rounded,
                                            color: AppColors.primary,
                                            size: 40),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppStrings.appName,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Discover dishes from cuisines\naround the world',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ── Form fields ──────────────────────────────────
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildField(
                                    controller: _emailCtrl,
                                    label: 'Email',
                                    hint: 'you@example.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Enter your email';
                                      if (!v.contains('@'))
                                        return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _passCtrl,
                                    label: 'Password',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscure,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Enter your password';
                                      return null;
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => setState(() {
                                        _step = _Step.forgotEmail;
                                        _error = null;
                                      }),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 4),
                                    _ErrorBanner(message: _error!),
                                  ],
                                ],
                              ),
                            ),

                            // Bottom breathing room so content isn't flush
                            // against the footer when content is short
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Bottom: Sign In button + Register link ───────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.register),
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account?  ",
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Register',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

  // ── Forgot password steps ────────────────────────────────────────────────────

  Widget _buildForgotStep() {
    switch (_step) {
      case _Step.forgotEmail:
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () =>
                  setState(() { _step = _Step.signIn; _error = null; })),
              const SizedBox(height: 24),
              _StepHeader(
                icon: Icons.lock_reset_rounded,
                title: 'Forgot Password?',
                subtitle: "Enter your email and we'll send a 6-digit OTP.",
              ),
              const SizedBox(height: 24),
              _buildField(
                  controller: _forgotEmailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!)
              ],
              const SizedBox(height: 24),
              _PrimaryBtn(
                  label: 'Send OTP',
                  loading: _loading,
                  onPressed: _sendForgotOtp),
            ]);

      case _Step.forgotOtp:
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () =>
                  setState(() { _step = _Step.forgotEmail; _error = null; })),
              const SizedBox(height: 24),
              _StepHeader(
                icon: Icons.mark_email_read_outlined,
                title: 'Check Your Email',
                subtitle: 'Enter the 6-digit code sent to $_fpEmail',
              ),
              const SizedBox(height: 28),
              _OtpInput(onCompleted: _verifyForgotOtp),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!)
              ],
              if (_loading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : _sendForgotOtp,
                  child: const Text('Resend OTP',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ),
            ]);

      case _Step.forgotNewPass:
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepHeader(
                icon: Icons.lock_outline_rounded,
                title: 'Set New Password',
                subtitle: 'Choose a strong password for your account.',
              ),
              const SizedBox(height: 24),
              _buildField(
                controller: _newPassCtrl,
                label: 'New Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureNew,
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _confirmPassCtrl,
                label: 'Confirm Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!)
              ],
              const SizedBox(height: 24),
              _PrimaryBtn(
                  label: 'Update Password',
                  loading: _loading,
                  onPressed: _updatePassword),
            ]);

      case _Step.forgotDone:
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 72),
              const SizedBox(height: 16),
              const Text('Password Updated!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Your password has been changed.\nSign in with your new password.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 28),
              _PrimaryBtn(
                label: 'Go to Sign In',
                loading: false,
                onPressed: () => setState(() {
                  _step = _Step.signIn;
                  _error = null;
                  _newPassCtrl.clear();
                  _confirmPassCtrl.clear();
                  _forgotEmailCtrl.clear();
                }),
              ),
            ]);

      default:
        return const SizedBox.shrink();
    }
  }

  // ── Field builder ────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textHint, fontSize: 14),
            prefixIcon:
                Icon(icon, color: AppColors.textSecondary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.5)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// ── Shared small widgets ─────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.arrow_back_ios_new_rounded,
            size: 16, color: AppColors.primary),
        SizedBox(width: 4),
        Text('Back',
            style: TextStyle(color: AppColors.primary, fontSize: 13)),
      ]),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _StepHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 26),
      ),
      const SizedBox(height: 12),
      Text(title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(subtitle,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
    ]);
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const _PrimaryBtn(
      {required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OtpInput extends StatefulWidget {
  final void Function(String) onCompleted;
  const _OtpInput({required this.onCompleted});

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  static const _count = 6;
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(_count, (_) => TextEditingController());
    _nodes = List.generate(_count, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _onChanged(int i, String val) {
    if (val.length > 1) {
      final digits = val.replaceAll(RegExp(r'\D'), '').split('');
      for (int j = 0; j < _count && j < digits.length; j++) {
        _ctrls[j].text = digits[j];
      }
      _nodes[(digits.length < _count ? digits.length : _count - 1)]
          .requestFocus();
    } else if (val.isNotEmpty) {
      if (i < _count - 1) _nodes[i + 1].requestFocus();
    } else {
      if (i > 0) {
        _nodes[i - 1].requestFocus();
        _ctrls[i - 1].clear();
      }
    }
    final otp = _ctrls.map((c) => c.text).join();
    if (otp.length == _count && RegExp(r'^\d{6}$').hasMatch(otp)) {
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_count, (i) => SizedBox(
        width: 48,
        height: 56,
        child: TextFormField(
          controller: _ctrls[i],
          focusNode: _nodes[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
          ),
          onChanged: (v) => _onChanged(i, v),
        ),
      )),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}
