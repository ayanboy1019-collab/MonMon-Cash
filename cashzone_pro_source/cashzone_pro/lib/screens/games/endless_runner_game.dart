// endless_runner_game.dart – Tap to jump over obstacles. Flame engine recommended.
// This version uses a simple Flutter-based prototype with timers.
// Integrate flame package for full physics + sprite animations.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class EndlessRunnerGame extends StatefulWidget {
  const EndlessRunnerGame({super.key});
  @override State<EndlessRunnerGame> createState() => _EndlessRunnerGameState();
}

class _EndlessRunnerGameState extends State<EndlessRunnerGame> with SingleTickerProviderStateMixin {
  double _playerY = 0; // 0 = ground, negative = jumping
  double _velocity = 0;
  double _obstacleX = 1.0; // normalized screen position
  int _score = 0, _coins = 0;
  bool _isPlaying = false, _isDead = false;
  Timer? _gameTimer;
  late AnimationController _jumpCtrl;

  static const _gravity = 0.008;
  static const _jumpForce = -0.25;
  static const _obstacleSpeed = 0.012;

  @override void initState() { super.initState();
    _jumpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300)); }
  @override void dispose() { _gameTimer?.cancel(); _jumpCtrl.dispose(); super.dispose(); }

  void _start() {
    setState(() { _playerY = 0; _velocity = 0; _obstacleX = 1.2; _score = 0; _coins = 0; _isDead = false; _isPlaying = true; });
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _jump() {
    if (!_isPlaying || _isDead) return;
    if (_playerY >= -0.01) { // only jump from ground
      HapticFeedback.lightImpact();
      _velocity = _jumpForce;
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _velocity += _gravity;
      _playerY = (_playerY + _velocity).clamp(-0.5, 0.0);
      _obstacleX -= _obstacleSpeed + (_score * 0.0001); // speed up over time
      if (_obstacleX < -0.15) { _obstacleX = 1.2; _score++; if (_score % 5 == 0) _coins += 10; }
      // Collision detection (simplified)
      if (_obstacleX.abs() < 0.08 && _playerY > -0.12) { _endGame(); }
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() { _isPlaying = false; _isDead = true; });
    _claim();
  }

  Future<void> _claim() async {
    final cs = context.read<CoinService>();
    final ok = await cs.checkAndSetCooldown(gameId: 'runner', cooldown: const Duration(hours: 1));
    final awarded = ok ? await cs.awardCoins(amount: _coins.clamp(0, 500), source: 'endless_runner', metadata: {'score': _score}) : 0;
    await context.read<AdService>().showInterstitialIfReady();
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Game Over! 🏃', style: AppTheme.heading2, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('Score: $_score', style: const TextStyle(color: AppTheme.accentNeon, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8), Text('+$awarded Coins', style: AppTheme.coinText),
      ]), actions: [ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Collect!'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final groundY = size.height * 0.65;
    final playerX = size.width * 0.2;
    return Scaffold(
      body: Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient), child: SafeArea(child: GestureDetector(
        onTapDown: (_) => _jump(),
        child: Stack(children: [
          // Header
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () { _gameTimer?.cancel(); Navigator.pop(context); }),
            Text('Endless Run', style: AppTheme.heading2), const Spacer(),
            Text('Score: $_score', style: const TextStyle(color: AppTheme.accentNeon, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(width: 16),
            Text('🪙 $_coins', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700, fontSize: 16)),
          ])),
          // Ground
          Positioned(left: 0, right: 0, top: groundY + 10, child: Container(height: 4, color: AppTheme.borderColor)),
          // Player
          if (_isPlaying || _isDead) Positioned(
            left: playerX, top: groundY + _playerY * size.height - 40,
            child: Text(_isDead ? '💀' : '🏃', style: const TextStyle(fontSize: 40))),
          // Obstacle
          if (_isPlaying || _isDead) Positioned(
            left: size.width * _obstacleX, top: groundY - 30,
            child: const Text('🌵', style: TextStyle(fontSize: 40))),
          // Start screen
          if (!_isPlaying && !_isDead) Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🏃', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text('Tap to jump over obstacles!', style: AppTheme.bodyText),
            Text('+10 coins every 5 obstacles cleared', style: AppTheme.labelText),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _start, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              child: const Text('START RUNNING', style: TextStyle(fontSize: 18))),
          ])),
          if (_isPlaying) Align(alignment: Alignment.bottomCenter,
            child: Padding(padding: const EdgeInsets.only(bottom: 32),
              child: Text('TAP TO JUMP', style: AppTheme.labelText.copyWith(color: AppTheme.textMuted, letterSpacing: 3)))),
        ]),
      ))),
    );
  }
}
