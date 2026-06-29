import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/auth_service.dart';
import '../../auth/auth_bottom_sheet.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // ── URL helpers ──────────────────────────────────────────────────────────

  static const _privacyUrl =
      'https://athulsethumadhavan.github.io/RecipeQuest/privacy_policy.html';
  static const _supportEmail = 'athulsethumadhavan+recipeSupport@gmail.com'; // TODO: replace
  static const _appStoreUrl =
      'https://apps.apple.com/app/your-app-id'; // TODO: replace
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.your.packagename'; // TODO: replace

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final isLoggedIn = auth.isLoggedIn;
    final user = auth.currentUser;

    // Derive display name & initials from Supabase metadata
    final rawName =
        (user?.userMetadata?['name'] as String? ?? '').trim();
    final displayName = rawName.isNotEmpty ? rawName : 'Foodie';
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final email = user?.email ?? '';

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: isLoggedIn
                  ? _LoggedInHeader(
                      initials: initials,
                      displayName: displayName,
                      email: email,
                      onTap: () => _showProfileSheet(context, displayName, email),
                    )
                  : _GuestHeader(
                      onSignIn: () async {
                        Navigator.pop(context);
                        await AuthBottomSheet.show(context);
                      },
                    ),
            ),

            const SizedBox(height: 8),

            // ── Menu items ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  if (isLoggedIn)
                    _DrawerTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: () => _showProfileSheet(context, displayName, email),
                    ),
                  _DrawerTile(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Subscription',
                    onTap: () {
                      Navigator.pop(context);
                      _showSubscriptionSheet(context);
                    },
                  ),
                  const _Divider(),
                  _DrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _launch(_privacyUrl),
                  ),
                  _DrawerTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => _launch('mailto:$_supportEmail'),
                  ),
                  _DrawerTile(
                    icon: Icons.star_outline_rounded,
                    label: 'Rate the App',
                    onTap: () {
                      final url = Theme.of(context).platform == TargetPlatform.iOS
                          ? _appStoreUrl
                          : _playStoreUrl;
                      _launch(url);
                    },
                  ),
                ],
              ),
            ),

            // ── Footer: logout / sign in ────────────────────────────────────
            const Divider(height: 1, color: AppColors.divider),
            if (isLoggedIn)
              _DrawerTile(
                icon: Icons.logout_rounded,
                label: 'Logout',
                iconColor: AppColors.error,
                labelColor: AppColors.error,
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService.instance.signOut();
                },
              )
            else
              _DrawerTile(
                icon: Icons.login_rounded,
                label: 'Sign In',
                iconColor: AppColors.primary,
                labelColor: AppColors.primary,
                onTap: () async {
                  Navigator.pop(context);
                  await AuthBottomSheet.show(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Sheets & dialogs ─────────────────────────────────────────────────────

  void _showProfileSheet(
      BuildContext context, String name, String email) {
    Navigator.pop(context); // close drawer
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(name: name, email: email),
    );
  }

  void _showSubscriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SubscriptionSheet(),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Recipe Quest',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.restaurant_rounded,
            color: AppColors.primary, size: 28),
      ),
      children: const [
        SizedBox(height: 8),
        Text(
          'Recipe Quest helps you discover and cook delicious dishes '
          'from cuisines around the world. Unlock recipes, watch video '
          'guides, and save your favourites.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _LoggedInHeader extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final VoidCallback onTap;

  const _LoggedInHeader({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  'View profile →',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  final VoidCallback onSignIn;
  const _GuestHeader({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white24,
          child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        const Text(
          'Welcome, Foodie!',
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to unlock cuisines & save favourites',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: onSignIn,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white60),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child:
              const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: iconColor ?? AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppColors.textHint, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 16, indent: 20, endIndent: 20, color: AppColors.divider);
}

// ── Profile sheet ────────────────────────────────────────────────────────────

class _ProfileSheet extends StatefulWidget {
  final String name;
  final String email;
  const _ProfileSheet({required this.name, required this.email});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await AuthService.instance.fetchProfile();
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (widget.email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.email,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 20),
          // Details
          if (_profile != null) ...[
            _ProfileRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value:
                    '${_profile!['country_code'] ?? ''} ${_profile!['phone'] ?? ''}'),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService.instance.signOut();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value.trim(),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Subscription sheet ───────────────────────────────────────────────────────

class _SubscriptionSheet extends StatelessWidget {
  const _SubscriptionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.workspace_premium_rounded,
              color: AppColors.accent, size: 48),
          const SizedBox(height: 12),
          const Text('Your Subscriptions',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Unlock individual dishes for \$1 or entire cuisines for \$10. '
            'All purchases are one-time and yours forever.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          _SubTile(
            icon: Icons.restaurant_menu_rounded,
            title: 'Dish Unlock',
            subtitle: '\$1 per dish — unlimited access',
          ),
          const SizedBox(height: 10),
          _SubTile(
            icon: Icons.public_rounded,
            title: 'Cuisine Unlock',
            subtitle: '\$10 per cuisine — all dishes included',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Got it',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SubTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
