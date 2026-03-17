// ============================================================
//  scratch_to_win_game.dart  –  Scratch card mini-game
//
//  Flow: User scratch the card → random coins revealed
//  Cooldown: 1 hour (enforced server-side via CoinService)
//  Max reward: 200 coins/session
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class ScratchToWinGame extends StatefulWidget {
  const ScratchToWinGame({super.key});

  @override
  State<ScratchToWinGame> createState() => _ScratchToWinGameState();
}

class _ScratchToWinGameState extends State<ScratchToWinGame>
    with SingleTickerProviderStateMixin {

  // Scratch mask – list of scratched points
  final List<Offset> _scratchedPoints = [];
  bool _isRevealed = false;
  bool _isClaiming = false;
  int _rewardCoins = 0;
  late ConfettiController _confettiController;
  late AnimationController _shakeController;

  // Prize tiers (weights determine probability)
  static const List<_Prize> _prizes = [
    _Prize(50,  'Common',   AppTheme.accentGreen,  60),  // 60% chance
    _Prize(100, 'Uncommon', AppTheme.primaryBlue,  25),  // 25% chance
    _Prize(150, 'Rare',     AppTheme.primaryPurple, 10), // 10% chance
    _Prize(200, 'Jackpot!', AppTheme.accentGold,    5),  //  5% chance
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _shakeController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _rewardCoins = _selectPrize();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // Weighted random prize selection
  int _selectPrize() {
    final rand = Random();
    final roll = rand.nextInt(100);
    int cumulative = 0;
    for (final prize in _prizes) {
      cumulative += prize.weight;
      if (roll < cumulative) return prize.coins;
    }
    return _prizes.first.coins;
  }

  _Prize get _currentPrize =>
      _prizes.firstWhere((p) => p.coins == _rewardCoins,
          orElse: () => _prizes.first);

  void _onScratch(DragUpdateDetails details) {
    if (_isRevealed) return;
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _scratchedPoints.add(local);
      // Auto-reveal after 40 scratch points
      if (_scratchedPoints.length >= 40) {
        _reveal();
      }
    });
  }

  void _reveal() {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);
    _confettiController.play();
  }

  Future<void> _claimCoins() async {
    if (_isClaiming || !_isRevealed) return;
    setState(() => _isClaiming = true);

    final coinService = context.read<CoinService>();

    // Check cooldown (1 hour per session)
    final allowed = await coinService.checkAndSetCooldown(
      gameId: 'scratch_win',
      cooldown: const Duration(hours: 1),
    );

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ Come back in 1 hour!')),
      );
      setState(() => _isClaiming = false);
      return;
    }

    final awarded = await coinService.awardCoins(
      amount: _rewardCoins,
      source: 'scratch_win',
      metadata: {'prize': _rewardCoins},
    );

    // Show interstitial ad after claiming
    if (mounted) {
      await context.read<AdService>().showInterstitialIfReady();
    }

    setState(() => _isClaiming = false);

    if (!mounted) return;
    _showResultDialog(awarded);
  }

  void _showResultDialog(int awarded) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(awarded > 0 ? '🎉 You Won!' : '⏳ Limit Reached',
          style: AppTheme.heading2, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 64),
            const SizedBox(height: 8),
            Text(awarded > 0 ? '+$awarded Coins' : '0 Coins',
              style: AppTheme.coinText),
            const SizedBox(height: 8),
            Text(awarded > 0
                ? 'Added to your wallet!'
                : 'Daily limit reached. Try again tomorrow!',
              style: AppTheme.bodyText, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // back to games
            },
            child: const Text('Collect & Exit'),
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
              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  colors: const [
                    AppTheme.accentGold, AppTheme.primaryPurple,
                    AppTheme.accentNeon, Colors.white,
                  ],
                ),
              ),

              Column(
                children: [
                  // ── App Bar ────────────────────────
                  _buildAppBar(),
                  const SizedBox(height: 20),

                  // ── Instructions ───────────────────
                  Text('Scratch the card to reveal your prize!',
                    style: AppTheme.bodyText.copyWith(fontSize: 15)),
                  const SizedBox(height: 8),
                  Text('Prize: ${_currentPrize.coins} coins',
                    style: TextStyle(color: _currentPrize.color,
                      fontSize: 18, fontWeight: FontWeight.w700)),

                  const SizedBox(height: 32),

                  // ── Scratch Card ───────────────────
                  Center(child: _buildScratchCard()),

                  const Spacer(),

                  // ── Claim Button ───────────────────
                  if (_isRevealed)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isClaiming ? null : _claimCoins,
                          child: _isClaiming
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : Text('Claim $_rewardCoins Coins 🎉',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.3),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Keep scratching... ${_scratchedPoints.length}/40',
                        style: AppTheme.bodyText,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Scratch & Win', style: AppTheme.heading2),
        ],
      ),
    );
  }

  Widget _buildScratchCard() {
    const size = 280.0;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _currentPrize.color.withOpacity(0.3),
            blurRadius: 24, spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Revealed Prize (bottom layer) ─────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_currentPrize.color.withOpacity(0.3), AppTheme.bgCard],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on,
                      color: AppTheme.accentGold, size: 80),
                    const SizedBox(height: 16),
                    Text('+${_currentPrize.coins}', style: AppTheme.coinText),
                    Text(_currentPrize.label,
                      style: TextStyle(color: _currentPrize.color,
                        fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

            // ── Scratch Mask (top layer) ──────────
            if (!_isRevealed)
              GestureDetector(
                onPanUpdate: _onScratch,
                child: CustomPaint(
                  size: const Size(size, size),
                  painter: _ScratchPainter(_scratchedPoints),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── CustomPainter for the scratch mask ────────────────────
class _ScratchPainter extends CustomPainter {
  final List<Offset> points;
  _ScratchPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill with silver scratch surface
    final bgPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // "Erase" scratched areas
    final erasePaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(point, 22, erasePaint);
    }

    // Scratch texture lines
    final linePaint = Paint()
      ..color = const Color(0xFFB0B8C0)
      ..strokeWidth = 1;
    for (int i = 0; i < size.height.toInt(); i += 8) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), linePaint);
    }
  }

  @override
  bool shouldRepaint(_ScratchPainter old) => true;
}

// ── Prize data class ──────────────────────────────────────
class _Prize {
  final int coins;
  final String label;
  final Color color;
  final int weight; // probability weight out of 100
  const _Prize(this.coins, this.label, this.color, this.weight);
}
