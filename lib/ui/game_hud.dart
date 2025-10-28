// game_hud.dart - 게임 HUD (점수, 라이프 등)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/breakout_game.dart';
import '../game/game_constants.dart';
import '../services/score_service.dart';
import '../services/audio_service.dart';
import '../services/music_service.dart';
import '../models/score_record.dart';

/// 게임 HUD 위젯
class GameHUD extends StatefulWidget {
  final BreakoutGame game;

  const GameHUD({super.key, required this.game});

  @override
  State<GameHUD> createState() => _GameHUDState();
}

class _GameHUDState extends State<GameHUD> {
  bool _isAudioEnabled = true;

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
      AudioService().setEnabled(_isAudioEnabled);
      MusicService().setEnabled(_isAudioEnabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.zero, // SafeArea 최소값 제거
      child: Padding(
        padding: const EdgeInsets.only(top: 0, left: 12.0, right: 12.0, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 버튼들 (종료, 오디오)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 종료 버튼 (좌측)
                GestureDetector(
                  onTap: () {
                    exit(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
                // 오디오 토글 버튼 (우측)
                GestureDetector(
                  onTap: _toggleAudio,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isAudioEnabled
                          ? GameConstants.paddleColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                      border: Border.all(
                        color: _isAudioEnabled
                            ? GameConstants.paddleColor
                            : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _isAudioEnabled ? Icons.volume_up : Icons.volume_off,
                      color: _isAudioEnabled
                          ? GameConstants.paddleColor
                          : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 상단 정보 - Transform으로 위로 이동
            Transform.translate(
              offset: const Offset(0, 4), // 4픽셀 위로 이동
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 레벨 정보
                  _buildInfoBox(
                    'LEVEL',
                    widget.game.currentLevel.toString(),
                    GameConstants.brickNormalColor,
                  ),
                  // 점수
                  _buildInfoBox(
                    'SCORE',
                    widget.game.score.toString(),
                    GameConstants.paddleColor,
                  ),
                  // 라이프
                  _buildInfoBox(
                    'LIVES',
                    widget.game.lives.toString(),
                    GameConstants.ballColor,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 하단 안내 메시지
            if (widget.game.gameState == GameState.menu)
              _buildCenterMessage('TAP TO START'),
            if (widget.game.gameState == GameState.playing && !widget.game.balls.first.isLaunched)
              _buildCenterMessage('TAP TO LAUNCH'),
            if (widget.game.gameState == GameState.paused)
              _buildCenterMessage('PAUSED'),
            if (widget.game.gameState == GameState.levelComplete)
              _buildCenterMessage('LEVEL COMPLETE!\nTAP TO CONTINUE'),
            if (widget.game.gameState == GameState.gameOver)
              _buildGameOverScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120.0), // 패들과 겹치지 않도록 더 아래로
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: GameConstants.backgroundColor.withOpacity(0.8),
            border: Border.all(color: GameConstants.paddleColor, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: GameConstants.paddleColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => widget.game.restartGame(),
      child: Center(
        child: FutureBuilder<Map<String, dynamic>>(
        future: _getGameOverData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildCenterMessage('GAME OVER\nTAP TO RESTART');
          }

          final data = snapshot.data!;
          final rank = data['rank'] as int;
          final topScores = data['topScores'] as List<ScoreRecord>;

          return Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: GameConstants.backgroundColor.withOpacity(0.95),
              border: Border.all(color: GameConstants.ballColor, width: 3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: GameConstants.ballColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GAME OVER 타이틀
                Text(
                  'GAME OVER',
                  style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.ballColor,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 20),

                // 현재 점수 & 순위
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GameConstants.paddleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: GameConstants.paddleColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'YOUR SCORE',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          color: GameConstants.textSecondaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.game.score.toString(),
                        style: GoogleFonts.orbitron(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: GameConstants.paddleColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'RANK #$rank',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3
                              ? GameConstants.brickExplosiveColor
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // TOP 5 순위표
                Text(
                  'TOP 5 SCORES',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.textSecondaryColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),

                ...List.generate(
                  topScores.length > 5 ? 5 : topScores.length,
                  (index) {
                    final record = topScores[index];
                    final isCurrentScore = record.score == widget.game.score &&
                        index + 1 == rank;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentScore
                            ? GameConstants.paddleColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrentScore
                            ? Border.all(
                                color: GameConstants.paddleColor,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '#${index + 1}',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: index < 3
                                        ? GameConstants.brickExplosiveColor
                                        : GameConstants.textSecondaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                record.displayName,
                                style: GoogleFonts.orbitron(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            record.score.toString(),
                            style: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // TAP TO RESTART
                Text(
                  'TAP TO RESTART',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.paddleColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getGameOverData() async {
    final rank = await ScoreService().getRank(widget.game.score);
    final topScores = await ScoreService().getTopScores(10);

    return {
      'rank': rank,
      'topScores': topScores,
    };
  }
}
