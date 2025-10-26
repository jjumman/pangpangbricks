// app_open_ad_service.dart - 앱 오프닝 광고 서비스
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 앱 오프닝 광고를 관리하는 싱글톤 서비스
class AppOpenAdService {
  static final AppOpenAdService _instance = AppOpenAdService._internal();
  factory AppOpenAdService() => _instance;
  AppOpenAdService._internal();

  // 광고 단위 ID
  static const String _adUnitId = 'ca-app-pub-9825630307332726/2606788550';

  AppOpenAd? _appOpenAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;

  /// 광고 로드 상태 확인
  bool get isAdLoaded => _isAdLoaded;

  /// 광고 표시 상태 확인
  bool get isAdShowing => _isAdShowing;

  /// 광고 로드 (3초 타임아웃 포함)
  Future<bool> loadAd({Duration timeout = const Duration(seconds: 3)}) async {
    final completer = Completer<bool>();

    // 타임아웃 설정
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    try {
      await AppOpenAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isAdLoaded = true;
            timer.cancel();
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          },
          onAdFailedToLoad: (error) {
            print('AppOpenAd failed to load: $error');
            _isAdLoaded = false;
            timer.cancel();
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        ),
      );
    } catch (e) {
      print('Error loading AppOpenAd: $e');
      timer.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  /// 광고 표시
  Future<void> showAd({required void Function() onAdDismissed}) async {
    if (_appOpenAd == null || !_isAdLoaded) {
      onAdDismissed();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAdShowing = true;
        print('AppOpenAd showed full screen content');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('AppOpenAd failed to show: $error');
        _isAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        onAdDismissed();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        onAdDismissed();
      },
    );

    await _appOpenAd!.show();
  }

  /// 광고 리소스 해제
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAdLoaded = false;
    _isAdShowing = false;
  }
}
