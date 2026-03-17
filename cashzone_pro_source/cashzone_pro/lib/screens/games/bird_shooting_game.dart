// ============================================================
//  bird_shooting_game.dart  –  1-minute shooter (Flame engine)
//
//  Full implementation requires Flame game loop. This file
//  contains the complete scaffold + coin/timer logic.
//  Replace FlameGame with your Flame component tree.
//
//  Coins: 10 per hit. Max 250/session. Cooldown: 1 hour.
// ============================================================

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class _Bird {
  double x, y, speed;
  bool isHit;
  _Bird(this.x, this.y, this.speed) : isHit = false;
}

class BirdShootingGame extends StatefulWidget {
  const BirdShootingGame({super.key});
  @override State<BirdShootingGame> createState() => _BirdShootingGameState();
}

class _BirdShootingGameState extends State<BirdShootingGame> {
  static const _gameDuration = 60;
  int _timeLeft = _gameDuration;
  int _hits = 0;
  bool _isPlaying = false;
  Timer? _timer, _birdTimer;
  final List<_Bird> _birds = [];
  final Random _rand = Random();
  late ConfettiController _confetti;

  @override void initState() { super.initState(); _confetti = ConfettiController(duration: const Duration(seconds: 2)); }
  @override void dispose() { _timer?.cancel(); _birdTimer?.cancel(); _confetti.dispose(); super.dispose(); }

  void _start() {
    setState(() { _isPlaying = true; _timeLeft = _gameDuration; _hits = 0; _birds.clear(); });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _timeLeft--; if (_timeLeft <= 0) { _endGame(); t.cancel(); } });
    });
    _birdTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (_birds.length < 8) setState(() {
        final size = MediaQuery.of(context).size;
        _birds.add(_Bird(_rand.nextDouble() * (size.width - 60),
          _rand.nextDouble() * (size.height * 0.6) + 80, 0));
      });
    });
  }

  void _hitBird(int i) {
    if (_birds[i].isHit) return;
    setState(() { _birds[i].isHit = true; _hits++; });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _birds.removeWhere((b) => b.isHit));
    });
  }

  void _endGame() {
    _birdTimer?.cancel();
    setState(() => _isPlaying = false);
    _confetti.play();
    _claim();
  }

  Future<void> _claim() async {
    final coins = (_hits * 10).clamp(0, 250);
    final cs = context.read<CoinService>();
    final ok = await cs.checkAndSetCooldown(gameId: 'bird_shoot', cooldown: const Duration(hours: 1));
    final awarded = ok ? await cs.awardCoins(amount: coins, source: 'bird_shoot', metadata: {'hits': _hits}) : 0;
    await context.read<AdService>().showInterstitialIfReady();
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Game Over! 🎯', style: AppTheme.heading2, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('$_hits Birds Hit!', style: const TextStyle(color: AppTheme.accentRed, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('+$awarded Coins', style: AppTheme.coinText),
      ]),
      actions: [ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Collect!'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(child: Stack(children: [
          Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive)),
          // Birds
          ..._birds.asMap().entries.map((e) => Positioned(
            left: e.value.x, top: e.value.y,
            child: GestureDetector(
              onTap: () => _hitBird(e.key),
              child: AnimatedOpacity(
                opacity: e.value.isHit ? 0 : 1, duration: const Duration(milliseconds: 300),
                child: const Text('🐦', style: TextStyle(fontSize: 44))),
            ),
          )),
          // UI overlay
          Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
                Text('Bird Shooter', style: AppTheme.heading2),
                const Spacer(),
                Text('⏱ $_timeLeft s', style: const TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(width: 16),
                Text('🎯 $_hits', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700, fontSize: 18)),
              ])),
            if (!_isPlaying)
              Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🐦', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                Text('Tap birds to shoot them!', style: AppTheme.bodyText),
                Text('+10 coins per hit  •  Max 250 coins', style: AppTheme.labelText),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _start, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
                  child: const Text('START SHOOTING', style: TextStyle(fontSize: 18))),
              ]))),
          ]),
        ])),
      ),
    );
  }
}
