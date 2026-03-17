// ============================================================
//  spin_wheel_game.dart  –  Animated lucky spin wheel
//
//  Uses CustomPainter for the wheel + AnimationController
//  for smooth spin. Cooldown: 2 hours (server-side).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class SpinWheelGame extends StatefulWidget {
  const SpinWheelGame({super.key});

  @override
  State<SpinWheelGame> createState() => _SpinWheelGameState();
}

class _SpinWheelGameState extends State<SpinWheelGame>
    with SingleTickerProviderStateMixin {

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late ConfettiController _confettiController;

  bool _isSpinning = false;
  bool _hasSpun = false;
  double _currentAngle = 0.0;
  int _winIndex = 0;

  // Wheel segments
  static const List<_Segment> _segments = [
    _Segment(50,   '50',   Color(0xFFEF4444)),
    _Segment(100,  '100',  Color(0xFF3B82F6)),
    _Segment(75,   '75',   Color(0xFF10B981)),
    _Segment(200,  '200',  Color(0xFFFFD700)),
    _Segment(25,   '25',   Color(0xFF8B5CF6)),
    _Segment(150,  '150',  Color(0xFFEC4899)),
    _Segment(300,  '300',  Color(0xFFFF6B35)),
    _Segment(125,  '125',  Color(0xFF06B6D4)),
  ];

  static const double _segmentAngle = 2 * pi / 8; // 8 segments

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _spinController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;

    // Check cooldown
    final coinService = context.read<CoinService>();
    final allowed = await coinService.checkAndSetCooldown(
      gameId: 'spin_wheel',
      cooldown: const Duration(hours: 2),
    );
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ Come back in 2 hours!')));
      return;
    }

    // Pick random winning segment
    _winIndex = Random().nextInt(_segments.length);

    // Calculate target angle: multiple full rotations + land on win segment
    final spins = 5 + Random().nextInt(5); // 5-10 full rotations
    final targetSegmentAngle = _winIndex * _segmentAngle + _segmentAngle / 2;
    final targetAngle = spins * 2 * pi + targetSegmentAngle;

    setState(() => _isSpinning = true);

    _spinController.reset();
    _spinController.duration = const Duration(seconds: 5);
    _spinAnimation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + targetAngle,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    ));

    await _spinController.forward();

    _currentAngle = _spinAnimation.value;
    setState(() {
      _isSpinning = false;
      _hasSpun = true;
    });

    _confettiController.play();
    _claimWin();
  }

  Future<void> _claimWin() async {
    final coins = _segments[_winIndex].coins;
    final coinService = context.read<CoinService>();
    final awarded = await coinService.awardCoins(
      amount: coins,
      source: 'spin_wheel',
    );

    await context.read<AdService>().showInterstitialIfReady();

    if (!mounted) return;
    _showWinDialog(awarded, _segments[_winIndex]);
  }

  void _showWinDialog(int awarded, _Segment segment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉 ${segment.label} Coins!',
              style: AppTheme.heading2.copyWith(fontSize: 28),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: segment.color.withOpacity(0.2),
                border: Border.all(color: segment.color, width: 3),
              ),
              child: Center(
                child: Text('+$awarded',
                  style: TextStyle(color: segment.color, fontSize: 24,
                    fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Added to your wallet!', style: AppTheme.bodyText),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Awesome!'),
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
                  colors: const [AppTheme.accentGold, AppTheme.primaryPurple, Colors.white],
                ),
              ),
              Column(
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 8),
                  Text('Spin to win up to 300 coins!', style: AppTheme.bodyText),
                  const SizedBox(height: 16),
                  Text('Cooldown: 2 hours per spin', style: AppTheme.labelText),
                  const Spacer(),

                  // ── Wheel ────────────────────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pointer / Arrow
                      Align(
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.arrow_drop_down,
                          color: AppTheme.accentGold, size: 48),
                      ),
                      // Animated wheel
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (_, __) {
                          final angle = _spinController.isAnimating
                              ? _spinAnimation.value
                              : _currentAngle;
                          return Transform.rotate(
                            angle: angle,
                            child: CustomPaint(
                              size: const Size(280, 280),
                              painter: _WheelPainter(_segments),
                            ),
                          );
                        },
                      ),
                      // Center button
                      GestureDetector(
                        onTap: _isSpinning ? null : _spin,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [BoxShadow(
                              color: AppTheme.primaryPurple.withOpacity(0.5),
                              blurRadius: 20,
                            )],
                          ),
                          child: _isSpinning
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : const Text('SPIN', style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Spin Prizes Legend ────────────────
                  _buildPrizeLegend(),
                  const SizedBox(height: 24),
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
      const Text('Coin Spin', style: AppTheme.heading2),
    ]),
  );

  Widget _buildPrizeLegend() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _segments.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: s.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: s.color.withOpacity(0.4)),
        ),
        child: Text('${s.coins} 🪙',
          style: TextStyle(color: s.color, fontWeight: FontWeight.w700, fontSize: 13)),
      )).toList(),
    );
  }
}

// ── Wheel painter ──────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final List<_Segment> segments;
  _WheelPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = 2 * pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segAngle - pi / 2;
      final paint = Paint()..color = segments[i].color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, segAngle, true, paint,
      );

      // Divider lines
      final linePaint = Paint()
        ..color = Colors.black26
        ..strokeWidth = 2;
      final lineEnd = Offset(
        center.dx + radius * cos(startAngle),
        center.dy + radius * sin(startAngle),
      );
      canvas.drawLine(center, lineEnd, linePaint);

      // Text labels
      final textAngle = startAngle + segAngle / 2;
      final textRadius = radius * 0.65;
      final textPos = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: segments[i].label,
          style: const TextStyle(color: Colors.white,
            fontSize: 14, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(textPos.dx, textPos.dy);
      canvas.rotate(textAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Outer ring
    canvas.drawCircle(center, radius,
      Paint()..color = AppTheme.accentGold..style = PaintingStyle.stroke..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}

class _Segment {
  final int coins;
  final String label;
  final Color color;
  const _Segment(this.coins, this.label, this.color);
}
