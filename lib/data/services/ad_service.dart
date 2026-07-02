import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  // TODO: replace with real IDs before release:
  //   Android: ca-app-pub-7475228419610805/7945857057
  //   iOS:     ca-app-pub-7475228419610805/4333915106
  static const _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917'; // test
  static const _iosRewardedId     = 'ca-app-pub-3940256099942544/1712485313'; // test

  static String get _adUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _iosRewardedId
          : _androidRewardedId;

  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  /// Timestamp of the last rewarded ad that was fully watched.
  static DateTime? _lastAdTime;

  static const _adCooldown = Duration(minutes: 5);

  /// Returns true if enough time has passed since the last rewarded ad.
  static bool get shouldShowAd =>
      _lastAdTime == null ||
      DateTime.now().difference(_lastAdTime!) >= _adCooldown;

  /// Call this after the user earns the reward to record the time.
  static void _recordAdShown() => _lastAdTime = DateTime.now();

  /// Call this on app start (after MobileAds.instance.initialize())
  static Future<void> loadRewardedAd() async {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('[AdService] Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint('[AdService] Rewarded ad failed: $error');
        },
      ),
    );
  }

  /// Shows the rewarded ad.
  /// [onRewarded] is called when the user earns the reward (watched enough).
  /// [onNotAvailable] is called if no ad is ready — proceed anyway.
  static Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    required VoidCallback onNotAvailable,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('[AdService] No ad ready — opening video directly');
      _recordAdShown(); // start cooldown so next tap within 5 min skips ad
      onNotAvailable();
      loadRewardedAd(); // pre-load for next time
      return;
    }

    // Track whether the user earned the reward, but wait until ad is dismissed
    // before calling onRewarded — otherwise the action fires while ad is visible.
    bool _rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // pre-load next ad
        if (_rewarded) {
          _recordAdShown(); // record time reward was earned
          onRewarded();     // only now, after ad is gone
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onNotAvailable();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        debugPrint('[AdService] Reward earned: ${reward.amount} ${reward.type}');
        _rewarded = true; // mark — don't call onRewarded yet
      },
    );
  }
}
