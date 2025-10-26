// splash_screen.dart - 스플래시 화면
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/game_constants.dart';
import '../services/app_open_ad_service.dart';

/// 스플래시 화면 - 앱 시작 시 3초간 표시하며 광고 로드
class SplashScreen extends StatefulWidget {
  final void Function() onComplete;

  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _adService = AppOpenAdService();
  bool _adLoadAttempted = false;

  @override
  void initState() {
    super.initState();

    // 페이드 인 애니메이션 설정
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // 스플래시 화면 로직 시작
    _initializeSplash();
  }

  /// 스플래시 화면 초기화 및 광고 로드
  Future<void> _initializeSplash() async {
    // 3초 대기 시작과 동시에 광고 로드 시작
    final waitFuture = Future.delayed(const Duration(seconds: 3));

    // 광고 로드 시도 (3초 타임아웃)
    if (!_adLoadAttempted) {
      _adLoadAttempted = true;
      final adLoaded = await _adService.loadAd(
        timeout: const Duration(seconds: 3),
      );

      // 3초 대기 완료 후
      await waitFuture;

      // 광고가 로드되었으면 표시, 아니면 바로 게임 시작
      if (adLoaded && mounted) {
        await _adService.showAd(onAdDismissed: () {
          if (mounted) {
            widget.onComplete();
          }
        });
      } else {
        if (mounted) {
          widget.onComplete();
        }
      }
    } else {
      // 이미 광고 로드 시도했으면 3초만 대기
      await waitFuture;
      if (mounted) {
        widget.onComplete();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 게임 타이틀
              Text(
                'PANG PANG',
                style: GoogleFonts.orbitron(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: GameConstants.paddleColor,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      blurRadius: 20,
                      color: GameConstants.paddleColor,
                    ),
                    Shadow(
                      blurRadius: 40,
                      color: GameConstants.paddleColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'BRICKS',
                style: GoogleFonts.orbitron(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: GameConstants.ballColor,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      blurRadius: 20,
                      color: GameConstants.ballColor,
                    ),
                    Shadow(
                      blurRadius: 40,
                      color: GameConstants.ballColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              // 로딩 인디케이터
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    GameConstants.paddleColor.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
