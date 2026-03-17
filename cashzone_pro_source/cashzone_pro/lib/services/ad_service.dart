// ============================================================
//  ad_service.dart  –  Google Mobile Ads / AppLovin wrapper
//
//  Replace TEST IDs with real IDs before publishing.
//  AppLovin: add applovin_max package and init separately.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  // ── Ad Unit IDs ────────────────────────────────────────
  // IMPORTANT: Replace these test IDs with real ad unit IDs
  static const String _interstitialId = kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'  // Google test ID
      : 'YOUR_REAL_INTERSTITIAL_ID';

  static const String _rewardedId = kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'  // Google test ID
      : 'YOUR_REAL_REWARDED_ID';

  static const String _bannerId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'  // Google test ID
      : 'YOUR_REAL_BANNER_ID';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;

  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;
  bool _isBannerLoaded = false;
  bool get isRewardedLoaded => _isRewardedLoaded;
  bool get isBannerLoaded => _isBannerLoaded;

  // Track ad frequency to prevent spam (admin-configurable)
  int _interstitialShowCount = 0;
  static const int _interstitialFrequency = 3; // every N game completions

  // ── Initialize all ad types ───────────────────────────
  void initializeAds() {
    _loadInterstitialAd();
    _loadRewardedAd();
    _loadBannerAd();
  }

  // ── Interstitial Ads ──────────────────────────────────
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoaded = false;
          // Retry after delay
          Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
        },
      ),
    );
  }

  // Show interstitial – only every N game completions
  Future<void> showInterstitialIfReady() async {
    _interstitialShowCount++;
    if (_interstitialShowCount % _interstitialFrequency != 0) return;
    if (!_isInterstitialLoaded || _interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialLoaded = false;
        _loadInterstitialAd(); // preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
  }

  // ── Rewarded Ads ──────────────────────────────────────
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoaded = false;
          Future.delayed(const Duration(minutes: 2), _loadRewardedAd);
        },
      ),
    );
  }

  // Show rewarded ad and call onReward with coin amount on completion
  Future<void> showRewardedAd({
    required Function(int coins) onReward,
    required Function onFailure,
    int rewardCoins = 100,
  }) async {
    if (!_isRewardedLoaded || _rewardedAd == null) {
      onFailure();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isRewardedLoaded = false;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        onFailure();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onReward(rewardCoins); // Award our custom coin amount
      },
    );
  }

  // ── Banner Ads ────────────────────────────────────────
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerLoaded = false;
        },
      ),
    )..load();
  }

  BannerAd? get bannerAd => _bannerAd;

  // ── Dispose ───────────────────────────────────────────
  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}
