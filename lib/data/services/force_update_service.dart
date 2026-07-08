import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Result of the update check.
enum UpdateStatus {
  /// App is up to date — proceed normally.
  none,

  /// A newer version is available but the user can skip it.
  optional,

  /// App is below the minimum supported version — must update.
  required,
}

/// Checks Firebase Remote Config for the minimum and latest app versions.
///
/// Remote Config keys:
///   min_android_version     e.g. "1.2.0"  → force update if current < this
///   min_ios_version         e.g. "1.2.0"
///   latest_android_version  e.g. "1.3.0"  → optional update if current < this
///   latest_ios_version      e.g. "1.3.0"
class ForceUpdateService {
  ForceUpdateService._();
  static final ForceUpdateService instance = ForceUpdateService._();

  static const _keyMinAndroid    = 'min_android_version';
  static const _keyMinIos        = 'min_ios_version';
  static const _keyLatestAndroid = 'latest_android_version';
  static const _keyLatestIos     = 'latest_ios_version';

  // Store / update URLs
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.atsIOSDev.recipeQuest';
  static const _appStoreUrl =
      'https://apps.apple.com/app/recipe-quest/id6785156653';

  String get storeUrl => Platform.isIOS ? _appStoreUrl : _playStoreUrl;

  /// Fetches Remote Config and returns the appropriate [UpdateStatus].
  /// Returns [UpdateStatus.none] on any error so the app never gets stuck.
  Future<UpdateStatus> checkUpdate() async {
    try {
      final rc = FirebaseRemoteConfig.instance;

      // Defaults — app works even before any value is published
      await rc.setDefaults({
        _keyMinAndroid:    '1.0.0',
        _keyMinIos:        '1.0.0',
        _keyLatestAndroid: '1.0.0',
        _keyLatestIos:     '1.0.0',
      });

      // Short fetch timeout — don't block the splash too long
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout:         const Duration(seconds: 5),
        minimumFetchInterval: Duration.zero, // always fetch fresh on launch
      ));

      await rc.fetchAndActivate();

      final minVersion = Platform.isIOS
          ? rc.getString(_keyMinIos)
          : rc.getString(_keyMinAndroid);

      final latestVersion = Platform.isIOS
          ? rc.getString(_keyLatestIos)
          : rc.getString(_keyLatestAndroid);

      final info    = await PackageInfo.fromPlatform();
      final current = info.version;

      debugPrint('[ForceUpdate] current=$current  min=$minVersion  latest=$latestVersion');

      if (_isBelow(current, minVersion)) return UpdateStatus.required;
      if (_isBelow(current, latestVersion)) return UpdateStatus.optional;
      return UpdateStatus.none;
    } catch (e) {
      debugPrint('[ForceUpdate] error (skipping): $e');
      return UpdateStatus.none;
    }
  }

  /// Returns true if [current] is strictly less than [minimum].
  bool _isBelow(String current, String minimum) {
    final c = _parse(current);
    final m = _parse(minimum);
    for (int i = 0; i < 3; i++) {
      if (c[i] < m[i]) return true;
      if (c[i] > m[i]) return false;
    }
    return false;
  }

  List<int> _parse(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => i < parts.length
        ? int.tryParse(parts[i]) ?? 0
        : 0);
  }
}
