import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/services/payment_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  AdSize?   _adSize;
  bool      _isLoaded = false;

  static String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2018956823856869/1526167792';
    } else {
      return 'ca-app-pub-2018956823856869/4160069993';
    }
  }

  @override
  void initState() {
    super.initState();
    // Rebuild whenever subscription status changes
    PaymentService.adFreeNotifier.addListener(_onAdFreeChanged);
  }

  void _onAdFreeChanged() {
    if (PaymentService.isAdFree) {
      // Subscription active — dispose the ad and hide
      _bannerAd?.dispose();
      if (mounted) setState(() { _bannerAd = null; _isLoaded = false; });
    } else {
      // Subscription expired — reload the ad
      if (mounted) _loadAd();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !PaymentService.isAdFree) _loadAd();
  }

  Future<void> _loadAd() async {
    if (PaymentService.isAdFree) return; // double-check
    final screenWidth = MediaQuery.of(context).size.width.truncate();
    final adSize = await AdSize
        .getCurrentOrientationAnchoredAdaptiveBannerAdSize(screenWidth);
    if (adSize == null || !mounted || PaymentService.isAdFree) return;

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
    PaymentService.adFreeNotifier.removeListener(_onAdFreeChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide instantly when ad-free
    if (PaymentService.isAdFree) return const SizedBox.shrink();
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
