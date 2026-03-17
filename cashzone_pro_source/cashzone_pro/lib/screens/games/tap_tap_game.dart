// ============================================================
//  tap_tap_game.dart  –  30-second tapping challenge
//
//  Earn coins based on total taps in 30 seconds.
//  Anti-abuse: max 10 taps/second tracked via timestamps.
//  Cooldown: 30 minutes server-side.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class TapTapGame extends StatefulWidget {
  const TapTapGame({super.key});

  @override
  State<TapTapGame> createState() => _TapTapGameState();
}

class _TapTapGameState extends State<TapTapGame>
    with SingleTickerProviderStateMixin {

  static const int _gameDuration = 30;  // seconds
  static const int _maxCoins = 150;
  static const double _coinsPerTap = 0.5; // taps needed per coin

  int _taps = 0;
  int _timeLeft = _gameDuration;
  bool _isPlaying = false;
  bool _isFinished = false;
  Timer? _timer;
  late AnimationController _pulseController;
  late ConfettiController _confettiController;

  // Anti-cheat: track tap timestamps in last second
  final List<DateTime> _recentTaps = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100));
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _taps = 0;
      _timeLeft = _gameDuration;
      _isPlaying = true;
      _isFinished = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });
  }

  void _onTap() {
    if (!_isPlaying) return;

    // Anti-cheat: max 10 taps/second
    final now = DateTime.now();
    _recentTaps.removeWhere((t) => now.difference(t).inMilliseconds > 1000);
    if (_recentTaps.length >= 10) return; // ignore excess taps
    _recentTaps.add(now);

    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() => _taps++);
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isFinished = true;
    });
    _confettiController.play();
    _claimCoins();
  }

  Future<void> _claimCoins() async {
    final earned = (_taps * _coinsPerTap).floor().clamp(0, _maxCoins);

    final coinService = context.read<CoinService>();
    final allowed = await coinService.checkAndSetCooldown(
      gameId: 'tap_tap',
      cooldown: const Duration(minutes: 30),
    );

    if (!allowed) {
      // Cooldown hit – still show result but no coins
      _showResultDialog(0);
      return;
    }

    final awarded = await coinService.awardCoins(
      amount: earned,
      source: 'tap_tap',
      metadata: {'taps': _taps},
    );

    await context.read<AdService>().showInterstitialIfReady();
    if (mounted) _showResultDialog(awarded);
  }

  void _showResultDialog(int awarded) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆 Game Over!', style: AppTheme.heading2, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('$_taps Taps', style: const TextStyle(
              color: AppTheme.accentNeon, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('+$awarded Coins', style: AppTheme.coinText),
            const SizedBox(height: 8),
            Text('Next game available in 30 minutes', style: AppTheme.bodyText,
              textAlign: TextAlign.center),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Collect!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                ),
              ),
              Column(
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 16),

                  // ── Timer & Score ─────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoBox('Time', '$_timeLeft s', AppTheme.accentRed),
                      _infoBox('Taps', '$_taps', AppTheme.accentNeon),
                      _infoBox('Coins', '${(_taps * _coinsPerTap).floor().clamp(0, _maxCoins)}',
                        AppTheme.accentGold),
                    ],
                  ),

                  const Spacer(),

                  // ── Tap Button ────────────────────────
                  if (!_isPlaying && !_isFinished)
                    Column(
                      children: [
                        Text('Tap as fast as you can!', style: AppTheme.bodyText),
                        const SizedBox(height: 8),
                        Text('Max $_maxCoins coins in 30 seconds',
                          style: AppTheme.labelText),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 18)),
                          child: const Text('START GAME', style: TextStyle(fontSize: 20)),
                        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      ],
                    )
                  else if (_isPlaying)
                    GestureDetector(
                      onTapDown: (_) => _onTap(),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Transform.scale(
                          scale: 1.0 - (_pulseController.value * 0.05),
                          child: Container(
                            width: 220, height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                              boxShadow: [BoxShadow(
                                color: AppTheme.primaryPurple.withOpacity(
                                  0.4 + _pulseController.value * 0.3),
                                blurRadius: 30 + _pulseController.value * 20,
                                spreadRadius: 5,
                              )],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.touch_app_rounded,
                                  color: Colors.white, size: 80),
                                const Text('TAP!', style: TextStyle(
                                  color: Colors.white, fontSize: 28,
                                  fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      const Text('Tap Tap', style: AppTheme.heading2),
    ]),
  );

  Widget _infoBox(String label, String value, Color color) =>
    Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: neonCard(color: color, radius: 16),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: AppTheme.labelText.copyWith(fontSize: 11)),
        ],
      ),
    );
}
