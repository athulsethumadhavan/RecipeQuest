import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isLoaded = false;

  static String get _adUnitId {
    if (Platform.isAndroid) {
      // TODO: replace with real ID before release: ca-app-pub-7475228419610805/6447315815
      return 'ca-app-pub-3940256099942544/6300978111'; // test
    } else {
      // TODO: replace with real ID before release: ca-app-pub-7475228419610805/3558262749
      return 'ca-app-pub-3940256099942544/2934735716'; // test
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) _loadAd();
  }

  Future<void> _loadAd() async {
    // Adaptive banner fills the full screen width
    final screenWidth = MediaQuery.of(context).size.width.truncate();
    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(screenWidth);
    if (adSize == null || !mounted) return;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() { _adSize = adSize; _isLoaded = true; });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: _adSize!.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
