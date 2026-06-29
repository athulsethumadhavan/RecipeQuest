import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Password must have ≥8 chars, ≥1 uppercase, ≥1 lowercase, ≥1 digit, ≥1 symbol.
final _passwordRegex =
    RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&#^()\-_+=<>]).{8,}$');

/// Wraps Supabase Auth with a ChangeNotifier so the UI can react to auth state.
///
/// Passwords are NEVER stored — Supabase Auth handles bcrypt hashing server-side.
/// Extra profile data (name, phone, country_code) is stored in `user_profiles`.
class AuthService extends ChangeNotifier {
  AuthService._() {
    // Listen to auth state changes from Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  static final AuthService instance = AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  // ── State ──────────────────────────────────────────────────────────────────

  bool get isLoggedIn => _client.auth.currentSession != null;

  User? get currentUser => _client.auth.currentUser;

  String? get currentUserId => currentUser?.id;

  String? get currentUserEmail => currentUser?.email;

  // ── Password validation ────────────────────────────────────────────────────

  static bool isValidPassword(String password) =>
      _passwordRegex.hasMatch(password);

  static String? passwordError(String password) {
    if (password.length < 8) return 'Must be at least 8 characters';
    if (!password.contains(RegExp(r'[A-Z]')))
      return 'Must contain an uppercase letter';
    if (!password.contains(RegExp(r'[a-z]')))
      return 'Must contain a lowercase letter';
    if (!password.contains(RegExp(r'\d'))) return 'Must contain a number';
    if (!password.contains(RegExp(r'[@$!%*?&#^()\-_+=<>]')))
      return 'Must contain a symbol (@\$!%*?&#…)';
    return null;
  }

  // ── Auth operations ────────────────────────────────────────────────────────

  /// Sign in with email + password.
  /// Returns null on success, or an error message string.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Register a new user with Supabase Auth + insert profile row.
  /// Returns null on success, or an error message string.
  Future<String?> signUp({
    required String name,
    required String phone,
    required String countryCode,
    required String email,
    required String password,
  }) async {
    final passwordErr = passwordError(password);
    if (passwordErr != null) return passwordErr;

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
          'country_code': countryCode,
        },
      );

      if (response.user?.id == null) {
        return 'Sign-up failed. Please try again.';
      }

      // Profile row is created automatically by the on_auth_user_created
      // DB trigger (SECURITY DEFINER), so no client-side insert needed.

      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('[AuthService] signUp error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  /// Fetch the current user's profile from user_profiles table.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('user_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      return row;
    } catch (e) {
      debugPrint('[AuthService] fetchProfile error: $e');
      return null;
    }
  }
}
