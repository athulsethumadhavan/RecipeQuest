import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';

/// Shows a modal bottom sheet with Login / Register tabs.
///
/// Usage:
/// ```dart
/// final success = await AuthBottomSheet.show(context);
/// if (success == true) { /* continue purchase */ }
/// ```
class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AuthBottomSheet(),
    );
  }

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Logo / headline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_rounded,
                          color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recipe Quest',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to unlock cuisines and save favourites',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Register'),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Forms
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SizedBox.expand(
                      child: _LoginForm(
                        onSuccess: () => Navigator.pop(context, true),
                        onSwitchToRegister: () => _tabController.animateTo(1),
                      ),
                    ),
                    SizedBox.expand(
                      child: _RegisterForm(
                        onSuccess: () => Navigator.pop(context, true),
                        onSwitchToLogin: () => _tabController.animateTo(0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Login form ──────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onSwitchToRegister;

  const _LoginForm({required this.onSuccess, required this.onSwitchToRegister});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final err = await AuthService.instance.signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err == null) {
      widget.onSuccess();
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _passCtrl,
              label: 'Password',
              hint: '••••••••',
              obscure: _obscure,
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign In',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: widget.onSwitchToRegister,
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Register',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Register form ───────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onSwitchToLogin;

  const _RegisterForm({required this.onSuccess, required this.onSwitchToLogin});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Unique key = '$dialCode|$countryLabel' so duplicates like +1 (US/Canada)
  // or +7 (Russia/Kazakhstan) don't cause DropdownButton assertion errors.
  String _countryKey = '+1|🇺🇸 United States';

  /// The dial code portion extracted from the selected country key.
  String get _dialCode => _countryKey.split('|').first;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  // All countries sorted alphabetically
  static const _countryCodes = [
    ('+93',   '🇦🇫 Afghanistan'),
    ('+355',  '🇦🇱 Albania'),
    ('+213',  '🇩🇿 Algeria'),
    ('+376',  '🇦🇩 Andorra'),
    ('+244',  '🇦🇴 Angola'),
    ('+1268', '🇦🇬 Antigua & Barbuda'),
    ('+54',   '🇦🇷 Argentina'),
    ('+374',  '🇦🇲 Armenia'),
    ('+61',   '🇦🇺 Australia'),
    ('+43',   '🇦🇹 Austria'),
    ('+994',  '🇦🇿 Azerbaijan'),
    ('+1242', '🇧🇸 Bahamas'),
    ('+973',  '🇧🇭 Bahrain'),
    ('+880',  '🇧🇩 Bangladesh'),
    ('+1246', '🇧🇧 Barbados'),
    ('+375',  '🇧🇾 Belarus'),
    ('+32',   '🇧🇪 Belgium'),
    ('+501',  '🇧🇿 Belize'),
    ('+229',  '🇧🇯 Benin'),
    ('+975',  '🇧🇹 Bhutan'),
    ('+591',  '🇧🇴 Bolivia'),
    ('+387',  '🇧🇦 Bosnia & Herzegovina'),
    ('+267',  '🇧🇼 Botswana'),
    ('+55',   '🇧🇷 Brazil'),
    ('+673',  '🇧🇳 Brunei'),
    ('+359',  '🇧🇬 Bulgaria'),
    ('+226',  '🇧🇫 Burkina Faso'),
    ('+257',  '🇧🇮 Burundi'),
    ('+238',  '🇨🇻 Cabo Verde'),
    ('+855',  '🇰🇭 Cambodia'),
    ('+237',  '🇨🇲 Cameroon'),
    ('+1',    '🇨🇦 Canada'),
    ('+236',  '🇨🇫 Central African Rep.'),
    ('+235',  '🇹🇩 Chad'),
    ('+56',   '🇨🇱 Chile'),
    ('+86',   '🇨🇳 China'),
    ('+57',   '🇨🇴 Colombia'),
    ('+269',  '🇰🇲 Comoros'),
    ('+242',  '🇨🇬 Congo'),
    ('+243',  '🇨🇩 Congo (DRC)'),
    ('+506',  '🇨🇷 Costa Rica'),
    ('+385',  '🇭🇷 Croatia'),
    ('+53',   '🇨🇺 Cuba'),
    ('+357',  '🇨🇾 Cyprus'),
    ('+420',  '🇨🇿 Czech Republic'),
    ('+45',   '🇩🇰 Denmark'),
    ('+253',  '🇩🇯 Djibouti'),
    ('+1767', '🇩🇲 Dominica'),
    ('+1809', '🇩🇴 Dominican Republic'),
    ('+593',  '🇪🇨 Ecuador'),
    ('+20',   '🇪🇬 Egypt'),
    ('+503',  '🇸🇻 El Salvador'),
    ('+240',  '🇬🇶 Equatorial Guinea'),
    ('+291',  '🇪🇷 Eritrea'),
    ('+372',  '🇪🇪 Estonia'),
    ('+268',  '🇸🇿 Eswatini'),
    ('+251',  '🇪🇹 Ethiopia'),
    ('+679',  '🇫🇯 Fiji'),
    ('+358',  '🇫🇮 Finland'),
    ('+33',   '🇫🇷 France'),
    ('+241',  '🇬🇦 Gabon'),
    ('+220',  '🇬🇲 Gambia'),
    ('+995',  '🇬🇪 Georgia'),
    ('+49',   '🇩🇪 Germany'),
    ('+233',  '🇬🇭 Ghana'),
    ('+30',   '🇬🇷 Greece'),
    ('+1473', '🇬🇩 Grenada'),
    ('+502',  '🇬🇹 Guatemala'),
    ('+224',  '🇬🇳 Guinea'),
    ('+245',  '🇬🇼 Guinea-Bissau'),
    ('+592',  '🇬🇾 Guyana'),
    ('+509',  '🇭🇹 Haiti'),
    ('+504',  '🇭🇳 Honduras'),
    ('+36',   '🇭🇺 Hungary'),
    ('+354',  '🇮🇸 Iceland'),
    ('+91',   '🇮🇳 India'),
    ('+62',   '🇮🇩 Indonesia'),
    ('+98',   '🇮🇷 Iran'),
    ('+964',  '🇮🇶 Iraq'),
    ('+353',  '🇮🇪 Ireland'),
    ('+972',  '🇮🇱 Israel'),
    ('+39',   '🇮🇹 Italy'),
    ('+1876', '🇯🇲 Jamaica'),
    ('+81',   '🇯🇵 Japan'),
    ('+962',  '🇯🇴 Jordan'),
    ('+7',    '🇰🇿 Kazakhstan'),
    ('+254',  '🇰🇪 Kenya'),
    ('+686',  '🇰🇮 Kiribati'),
    ('+383',  '🇽🇰 Kosovo'),
    ('+965',  '🇰🇼 Kuwait'),
    ('+996',  '🇰🇬 Kyrgyzstan'),
    ('+856',  '🇱🇦 Laos'),
    ('+371',  '🇱🇻 Latvia'),
    ('+961',  '🇱🇧 Lebanon'),
    ('+266',  '🇱🇸 Lesotho'),
    ('+231',  '🇱🇷 Liberia'),
    ('+218',  '🇱🇾 Libya'),
    ('+423',  '🇱🇮 Liechtenstein'),
    ('+370',  '🇱🇹 Lithuania'),
    ('+352',  '🇱🇺 Luxembourg'),
    ('+261',  '🇲🇬 Madagascar'),
    ('+265',  '🇲🇼 Malawi'),
    ('+60',   '🇲🇾 Malaysia'),
    ('+960',  '🇲🇻 Maldives'),
    ('+223',  '🇲🇱 Mali'),
    ('+356',  '🇲🇹 Malta'),
    ('+692',  '🇲🇭 Marshall Islands'),
    ('+222',  '🇲🇷 Mauritania'),
    ('+230',  '🇲🇺 Mauritius'),
    ('+52',   '🇲🇽 Mexico'),
    ('+691',  '🇫🇲 Micronesia'),
    ('+373',  '🇲🇩 Moldova'),
    ('+377',  '🇲🇨 Monaco'),
    ('+976',  '🇲🇳 Mongolia'),
    ('+382',  '🇲🇪 Montenegro'),
    ('+212',  '🇲🇦 Morocco'),
    ('+258',  '🇲🇿 Mozambique'),
    ('+95',   '🇲🇲 Myanmar'),
    ('+264',  '🇳🇦 Namibia'),
    ('+674',  '🇳🇷 Nauru'),
    ('+977',  '🇳🇵 Nepal'),
    ('+31',   '🇳🇱 Netherlands'),
    ('+64',   '🇳🇿 New Zealand'),
    ('+505',  '🇳🇮 Nicaragua'),
    ('+227',  '🇳🇪 Niger'),
    ('+234',  '🇳🇬 Nigeria'),
    ('+389',  '🇲🇰 North Macedonia'),
    ('+47',   '🇳🇴 Norway'),
    ('+968',  '🇴🇲 Oman'),
    ('+92',   '🇵🇰 Pakistan'),
    ('+680',  '🇵🇼 Palau'),
    ('+970',  '🇵🇸 Palestine'),
    ('+507',  '🇵🇦 Panama'),
    ('+675',  '🇵🇬 Papua New Guinea'),
    ('+595',  '🇵🇾 Paraguay'),
    ('+51',   '🇵🇪 Peru'),
    ('+63',   '🇵🇭 Philippines'),
    ('+48',   '🇵🇱 Poland'),
    ('+351',  '🇵🇹 Portugal'),
    ('+974',  '🇶🇦 Qatar'),
    ('+40',   '🇷🇴 Romania'),
    ('+7',    '🇷🇺 Russia'),
    ('+250',  '🇷🇼 Rwanda'),
    ('+1869', '🇰🇳 Saint Kitts & Nevis'),
    ('+1758', '🇱🇨 Saint Lucia'),
    ('+1784', '🇻🇨 Saint Vincent & Grenadines'),
    ('+685',  '🇼🇸 Samoa'),
    ('+378',  '🇸🇲 San Marino'),
    ('+239',  '🇸🇹 São Tomé & Príncipe'),
    ('+966',  '🇸🇦 Saudi Arabia'),
    ('+221',  '🇸🇳 Senegal'),
    ('+381',  '🇷🇸 Serbia'),
    ('+248',  '🇸🇨 Seychelles'),
    ('+232',  '🇸🇱 Sierra Leone'),
    ('+65',   '🇸🇬 Singapore'),
    ('+421',  '🇸🇰 Slovakia'),
    ('+386',  '🇸🇮 Slovenia'),
    ('+677',  '🇸🇧 Solomon Islands'),
    ('+252',  '🇸🇴 Somalia'),
    ('+27',   '🇿🇦 South Africa'),
    ('+82',   '🇰🇷 South Korea'),
    ('+211',  '🇸🇸 South Sudan'),
    ('+34',   '🇪🇸 Spain'),
    ('+94',   '🇱🇰 Sri Lanka'),
    ('+249',  '🇸🇩 Sudan'),
    ('+597',  '🇸🇷 Suriname'),
    ('+46',   '🇸🇪 Sweden'),
    ('+41',   '🇨🇭 Switzerland'),
    ('+963',  '🇸🇾 Syria'),
    ('+886',  '🇹🇼 Taiwan'),
    ('+992',  '🇹🇯 Tajikistan'),
    ('+255',  '🇹🇿 Tanzania'),
    ('+66',   '🇹🇭 Thailand'),
    ('+670',  '🇹🇱 Timor-Leste'),
    ('+228',  '🇹🇬 Togo'),
    ('+676',  '🇹🇴 Tonga'),
    ('+1868', '🇹🇹 Trinidad & Tobago'),
    ('+216',  '🇹🇳 Tunisia'),
    ('+90',   '🇹🇷 Turkey'),
    ('+993',  '🇹🇲 Turkmenistan'),
    ('+688',  '🇹🇻 Tuvalu'),
    ('+256',  '🇺🇬 Uganda'),
    ('+380',  '🇺🇦 Ukraine'),
    ('+971',  '🇦🇪 UAE'),
    ('+44',   '🇬🇧 United Kingdom'),
    ('+1',    '🇺🇸 United States'),
    ('+598',  '🇺🇾 Uruguay'),
    ('+998',  '🇺🇿 Uzbekistan'),
    ('+678',  '🇻🇺 Vanuatu'),
    ('+58',   '🇻🇪 Venezuela'),
    ('+84',   '🇻🇳 Vietnam'),
    ('+967',  '🇾🇪 Yemen'),
    ('+260',  '🇿🇲 Zambia'),
    ('+263',  '🇿🇼 Zimbabwe'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Password strength indicator
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final err = await AuthService.instance.signUp(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      countryCode: _dialCode,
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err == null) {
      widget.onSuccess();
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full name
            _Field(
              controller: _nameCtrl,
              label: 'Full Name',
              hint: 'John Smith',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your name';
                if (v.trim().length < 2) return 'Name too short';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Phone with country picker
            _Label('Phone Number'),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country code dropdown
                Container(
                  width: 140,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _countryKey,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary, size: 18),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _countryCodes.map((entry) {
                        final (code, label) = entry;
                        final key = '$code|$label';
                        return DropdownMenuItem(
                          value: key,
                          child: Text('$label  $code',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _countryKey = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '9876543210',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Enter phone number';
                      if (v.length < 7) return 'Too short';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Email
            _Field(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@') || !v.contains('.'))
                  return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            _Field(
              controller: _passCtrl,
              label: 'Password',
              hint: '••••••••',
              obscure: _obscurePass,
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                return AuthService.passwordError(v);
              },
            ),

            // Strength indicator
            if (_passCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
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
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Use uppercase, lowercase, number & symbol',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
              ),
            ],
            const SizedBox(height: 14),

            // Confirm password
            _Field(
              controller: _confirmCtrl,
              label: 'Confirm Password',
              hint: '••••••••',
              obscure: _obscureConfirm,
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Account',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: widget.onSwitchToLogin,
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            prefixIcon:
                Icon(icon, color: AppColors.textSecondary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
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
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
