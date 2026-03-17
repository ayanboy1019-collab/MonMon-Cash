// ============================================================
//  games_tab.dart  –  Grid of all 10 mini-games
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_theme.dart';
import 'scratch_to_win_game.dart';
import 'spin_wheel_game.dart';
import 'tap_tap_game.dart';
import 'bird_shooting_game.dart';
import 'mind_puzzle_game.dart';
import 'lucky_number_game.dart';
import 'card_flip_game.dart';
import 'advanced_wheel_game.dart';
import 'quiz_game.dart';
import 'endless_runner_game.dart';

class GameInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int maxCoins;
  final String cooldown;
  final Widget Function() screenBuilder;

  const GameInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.maxCoins,
    required this.cooldown,
    required this.screenBuilder,
  });
}

final List<GameInfo> allGames = [
  GameInfo(
    title: 'Scratch & Win',
    subtitle: 'Scratch to reveal coins',
    icon: Icons.auto_fix_high_rounded,
    color: const Color(0xFFFF6B35),
    maxCoins: 200,
    cooldown: '1 hour',
    screenBuilder: () => const ScratchToWinGame(),
  ),
  GameInfo(
    title: 'Coin Spin',
    subtitle: 'Spin the lucky wheel',
    icon: Icons.casino_rounded,
    color: AppTheme.accentGold,
    maxCoins: 300,
    cooldown: '2 hours',
    screenBuilder: () => const SpinWheelGame(),
  ),
  GameInfo(
    title: 'Tap Tap',
    subtitle: 'Tap fast to earn',
    icon: Icons.touch_app_rounded,
    color: const Color(0xFF10B981),
    maxCoins: 150,
    cooldown: '30 min',
    screenBuilder: () => const TapTapGame(),
  ),
  GameInfo(
    title: 'Bird Shooter',
    subtitle: '1-min shooting game',
    icon: Icons.sports_esports_rounded,
    color: const Color(0xFFEF4444),
    maxCoins: 250,
    cooldown: '1 hour',
    screenBuilder: () => const BirdShootingGame(),
  ),
  GameInfo(
    title: 'Mind Puzzle',
    subtitle: 'Brain teasers for coins',
    icon: Icons.psychology_rounded,
    color: const Color(0xFF8B5CF6),
    maxCoins: 400,
    cooldown: '2 hours',
    screenBuilder: () => const MindPuzzleGame(),
  ),
  GameInfo(
    title: 'Lucky Number',
    subtitle: 'Guess & win big',
    icon: Icons.looks_one_rounded,
    color: const Color(0xFF3B82F6),
    maxCoins: 500,
    cooldown: '1 hour',
    screenBuilder: () => const LuckyNumberGame(),
  ),
  GameInfo(
    title: 'Card Flip',
    subtitle: 'Match cards for coins',
    icon: Icons.style_rounded,
    color: const Color(0xFFF59E0B),
    maxCoins: 300,
    cooldown: '1 hour',
    screenBuilder: () => const CardFlipGame(),
  ),
  GameInfo(
    title: 'Mega Wheel',
    subtitle: 'Advanced spin rewards',
    icon: Icons.rotate_right_rounded,
    color: const Color(0xFF06B6D4),
    maxCoins: 1000,
    cooldown: '6 hours',
    screenBuilder: () => const AdvancedWheelGame(),
  ),
  GameInfo(
    title: 'Quiz Master',
    subtitle: 'Answer & earn',
    icon: Icons.quiz_rounded,
    color: const Color(0xFFEC4899),
    maxCoins: 600,
    cooldown: '2 hours',
    screenBuilder: () => const QuizGame(),
  ),
  GameInfo(
    title: 'Endless Run',
    subtitle: 'Run & collect coins',
    icon: Icons.directions_run_rounded,
    color: const Color(0xFF22C55E),
    maxCoins: 500,
    cooldown: '1 hour',
    screenBuilder: () => const EndlessRunnerGame(),
  ),
];

class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('🎮 Mini Games', style: AppTheme.heading1),
                    Text('Play & earn real coins', style: AppTheme.bodyText),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Game Grid ─────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: allGames.length,
                itemBuilder: (ctx, i) => _GameCard(game: allGames[i], index: i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameInfo game;
  final int index;

  const _GameCard({required this.game, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => game.screenBuilder()));
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: game.color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: game.color.withOpacity(0.2),
              blurRadius: 15, spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon in colored circle
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: game.color.withOpacity(0.15),
                border: Border.all(color: game.color.withOpacity(0.4)),
              ),
              child: Icon(game.icon, color: game.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(game.title, style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 15,
              fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(game.subtitle, style: AppTheme.labelText.copyWith(fontSize: 11),
              textAlign: TextAlign.center),
            const SizedBox(height: 10),
            // Max coins badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                    color: AppTheme.accentGold, size: 14),
                  const SizedBox(width: 4),
                  Text('${game.maxCoins} max',
                    style: const TextStyle(color: AppTheme.accentGold,
                      fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().scale(
        begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeOut),
    );
  }
}
