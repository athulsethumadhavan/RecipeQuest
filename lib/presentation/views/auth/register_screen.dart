import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/auth_service.dart';

/// Register (sign-up) page.
/// Collects email + password, creates the account, then navigates to
/// onboarding or home exactly like AuthScreen._onSuccess().
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum _RegStep { form, otp, done }

class _RegisterScreenState extends State<RegisterScreen> {
  _RegStep _step = _RegStep.form;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // ── Password strength ────────────────────────────────────────────────────────
  double get _strength {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.2;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.2;
    if (p.contains(RegExp(r'[a-z]'))) s += 0.2;
    if (p.contains(RegExp(r'\d'))) s += 0.2;
    if (p.contains(RegExp(r'[@$!%*?&#^()\-_+=<>]'))) s += 0.2;
    return s;
  }

  Color get _strengthColor {
    final s = _strength;
    if (s <= 0.2) return Colors.red;
    if (s <= 0.4) return Colors.orange;
    if (s <= 0.6) return Colors.yellow.shade700;
    if (s <= 0.8) return Colors.lightGreen;
    return Colors.green;
  }

  String get _strengthLabel {
    final s = _strength;
    if (s <= 0.2) return 'Very weak';
    if (s <= 0.4) return 'Weak';
    if (s <= 0.6) return 'Fair';
    if (s <= 0.8) return 'Strong';
    return 'Very strong';
  }

  String _regEmail = '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Navigation after verified ────────────────────────────────────────────────

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

  // ── Register ────────────────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final passErr = AuthService.passwordError(_passCtrl.text);
    if (passErr != null) { setState(() => _error = passErr); return; }

    setState(() { _loading = true; _error = null; });
    final err = await AuthService.instance.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      _regEmail = _emailCtrl.text.trim();
      setState(() => _step = _RegStep.otp);
    } else {
      setState(() => _error = err);
    }
  }

  // ── OTP verify ──────────────────────────────────────────────────────────────

  Future<void> _verifyOtp(String otp) async {
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.instance.verifyOtp(
        email: _regEmail, token: otp);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      AnalyticsService.instance.logSignUp();
      await _onSuccess();
    } else {
      setState(() => _error = err);
    }
  }

  Future<void> _resendOtp() async {
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.instance.resendOtp(email: _regEmail);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) setState(() => _error = err);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: switch (_step) {
          _RegStep.form => _buildRegisterForm(),
          _RegStep.otp => _buildOtpStep(),
          _RegStep.done => _buildDone(),
        },
      ),
    );
  }

  // ── Step 1: registration form ────────────────────────────────────────────────

  Widget _buildRegisterForm() {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back link
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Sign In',
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 28),

                const Text('Create Account',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                const Text(
                  'Join RecipeQuest and start exploring\ncuisines from around the world.',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 32),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      _buildField(
                        controller: _nameCtrl,
                        label: 'Name',
                        hint: 'Your name',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter your name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // Email
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
                      // Password
                      _buildField(
                        controller: _passCtrl,
                        label: 'Password',
                        hint: '8+ characters',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePass,
                        onChanged: (_) => setState(() {}),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 20),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Enter a password';
                          return AuthService.passwordError(v);
                        },
                      ),
                      // Strength bar
                      if (_passCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _strength,
                                backgroundColor: AppColors.divider,
                                color: _strengthColor,
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _strengthLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: _strengthColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        const Text(
                          'Use uppercase, lowercase, number & symbol',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Confirm password
                      _buildField(
                        controller: _confirmCtrl,
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
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Confirm your password';
                          if (v != _passCtrl.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBanner(message: _error!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom: Register button + sign in link
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            border:
                Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Create Account',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.pop(),
                child: RichText(
                  text: const TextSpan(
                    text: 'Already have an account?  ',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Sign In',
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
    );
  }

  // ── Step 2: OTP verification ─────────────────────────────────────────────────

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() { _step = _RegStep.form; _error = null; }),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text('Back',
                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 28),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 12),
          const Text('Verify Email',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-digit code sent to $_regEmail',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          _OtpInput(onCompleted: _verifyOtp),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          if (_loading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: _loading ? null : _resendOtp,
              child: const Text('Resend Code',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: done (fallback if _onSuccess failed) ────────────────────────────

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 72),
          const SizedBox(height: 16),
          const Text('Account Created!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            "You're all set. Let's pick your cuisines.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onSuccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Continue',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Field builder ────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
    void Function(String)? onChanged,
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
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style:
              const TextStyle(fontSize: 15, color: AppColors.textPrimary),
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
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1.5)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// ── Shared widgets (duplicated from auth_screen so file stays self-contained) ─

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
      children: List.generate(
        _count,
        (i) => SizedBox(
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
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
            ),
            onChanged: (v) => _onChanged(i, v),
          ),
        ),
      ),
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
