// main.dart - PangPang Bricks 진입점
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game/breakout_game.dart';
import 'game/game_constants.dart';
import 'ui/game_hud.dart';
import 'ui/splash_screen.dart';
import 'services/score_service.dart';
import 'services/music_service.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob 초기화
  await MobileAds.instance.initialize();

  // 서비스 초기화
  await ScoreService().initialize();
  await AudioService().initialize();
  await MusicService().initialize();

  // 세로 모드 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 상태바 숨기기
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const PangPangBricksApp());
}

class PangPangBricksApp extends StatefulWidget {
  const PangPangBricksApp({super.key});

  @override
  State<PangPangBricksApp> createState() => _PangPangBricksAppState();
}

class _PangPangBricksAppState extends State<PangPangBricksApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PangPang Bricks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GameConstants.backgroundColor,
      ),
      home: _showSplash
          ? SplashScreen(
              onComplete: () {
                setState(() {
                  _showSplash = false;
                });
              },
            )
          : const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BreakoutGame game;

  @override
  void initState() {
    super.initState();
    game = BreakoutGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 게임 화면
          GameWidget(
            game: game,
          ),
          // HUD 오버레이
          ValueListenableBuilder<int>(
            valueListenable: _GameUpdateNotifier(game),
            builder: (context, _, __) {
              return GameHUD(game: game);
            },
          ),
        ],
      ),
    );
  }
}

/// 게임 상태 변경 알림을 위한 헬퍼 클래스
class _GameUpdateNotifier extends ValueNotifier<int> {
  final BreakoutGame game;
  int _tickCount = 0;

  _GameUpdateNotifier(this.game) : super(0) {
    _startListening();
  }

  void _startListening() {
    // 10fps로 게임 상태 체크 (성능 최적화)
    // HUD는 점수/라이프 표시이므로 60fps 불필요
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      _tickCount++;
      value = _tickCount;
      return true;
    });
  }
}
