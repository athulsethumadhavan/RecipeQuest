import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  // ── Replace with your real Ad Unit IDs from AdMob ─────────────────────────
  // Use test IDs during development, replace before release
  static const _androidRewardedId =
      'ca-app-pub-3940256099942544/5224354917'; // test ID
  static const _iosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';  // test ID

  static String get _adUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _iosRewardedId
          : _androidRewardedId;

  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

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
      debugPrint('[AdService] No ad ready — proceeding without ad');
      onNotAvailable();
      // Pre-load for next time
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // pre-load next ad
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
        onRewarded();
      },
    );
  }
}
