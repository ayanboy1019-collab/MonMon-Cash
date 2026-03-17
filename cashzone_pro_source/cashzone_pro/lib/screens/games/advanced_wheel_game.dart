// advanced_wheel_game.dart – Premium 12-segment wheel. Cooldown 6h. Max 1000 coins.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class AdvancedWheelGame extends StatefulWidget {
  const AdvancedWheelGame({super.key});
  @override State<AdvancedWheelGame> createState() => _AdvancedWheelGameState();
}

class _AdvancedWheelGameState extends State<AdvancedWheelGame> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  late ConfettiController _confetti;
  bool _spinning = false;
  double _angle = 0;

  static const _prizes = [100,200,50,500,150,1000,75,300,250,400,125,600];
  static const _colors = [Color(0xFFEF4444),Color(0xFF3B82F6),Color(0xFF10B981),Color(0xFFFFD700),
    Color(0xFF8B5CF6),Color(0xFFEC4899),Color(0xFFFF6B35),Color(0xFF06B6D4),
    Color(0xFF22C55E),Color(0xFFF59E0B),Color(0xFF6366F1),Color(0xFFE11D48)];

  @override void initState() { super.initState(); _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _ctrl = AnimationController(vsync: this); }
  @override void dispose() { _ctrl.dispose(); _confetti.dispose(); super.dispose(); }

  Future<void> _spin() async {
    if (_spinning) return;
    final ok = await context.read<CoinService>().checkAndSetCooldown(gameId: 'adv_wheel', cooldown: const Duration(hours: 6));
    if (!ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⏳ Come back in 6 hours!'))); return; }
    final winIdx = Random().nextInt(_prizes.length);
    final target = _angle + (6 + Random().nextInt(4)) * 2 * pi + winIdx * (2 * pi / _prizes.length);
    _ctrl.duration = const Duration(seconds: 6);
    _anim = Tween<double>(begin: _angle, end: target).animate(CurvedAnimation(parent: _ctrl, curve: Curves.decelerate));
    setState(() => _spinning = true);
    _ctrl.reset(); await _ctrl.forward();
    _angle = target; setState(() => _spinning = false);
    _confetti.play();
    final coins = _prizes[winIdx];
    final awarded = await context.read<CoinService>().awardCoins(amount: coins, source: 'adv_wheel');
    await context.read<AdService>().showInterstitialIfReady();
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🎰 Mega Win!', style: AppTheme.heading2, textAlign: TextAlign.center),
        const SizedBox(height: 12), Text('+$awarded Coins', style: AppTheme.coinText),
      ]), actions: [ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Collect!'))],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient), child: SafeArea(child: Stack(children: [
      Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive)),
      Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
          Text('Mega Wheel', style: AppTheme.heading2),
          const Spacer(), Text('Cooldown: 6h', style: AppTheme.labelText.copyWith(color: AppTheme.accentGold)),
        ])),
        const Spacer(),
        Stack(alignment: Alignment.center, children: [
          const Align(alignment: Alignment.topCenter, child: Icon(Icons.arrow_drop_down, color: AppTheme.accentGold, size: 48)),
          AnimatedBuilder(animation: _ctrl, builder: (_, __) => Transform.rotate(
            angle: _ctrl.isAnimating ? _anim.value : _angle,
            child: CustomPaint(size: const Size(300, 300), painter: _AdvWheelPainter(_prizes, _colors)))),
          GestureDetector(onTap: _spin, child: Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient,
              boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.5), blurRadius: 20)]),
            child: _spinning ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : const Text('SPIN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)))),
        ]),
        const Spacer(),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: _prizes.asMap().entries.map((e) =>
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _colors[e.key].withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: _colors[e.key].withOpacity(0.4))),
            child: Text('${e.value} 🪙', style: TextStyle(color: _colors[e.key], fontWeight: FontWeight.w700, fontSize: 12)))).toList()),
        const SizedBox(height: 24),
      ]),
    ]))),
  );
}

class _AdvWheelPainter extends CustomPainter {
  final List<int> prizes; final List<Color> colors;
  _AdvWheelPainter(this.prizes, this.colors);
  @override void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2); final r = size.width / 2;
    final seg = 2 * pi / prizes.length;
    for (int i = 0; i < prizes.length; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * seg - pi / 2, seg, true, Paint()..color = colors[i]);
      canvas.drawLine(c, Offset(c.dx + r * cos(i * seg - pi / 2), c.dy + r * sin(i * seg - pi / 2)), Paint()..color = Colors.black26..strokeWidth = 2);
      final ta = i * seg - pi / 2 + seg / 2;
      final tp = Offset(c.dx + r * 0.65 * cos(ta), c.dy + r * 0.65 * sin(ta));
      final tpaint = TextPainter(text: TextSpan(text: '${prizes[i]}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
      canvas.save(); canvas.translate(tp.dx, tp.dy); canvas.rotate(ta + pi / 2);
      tpaint.paint(canvas, Offset(-tpaint.width / 2, -tpaint.height / 2)); canvas.restore();
    }
    canvas.drawCircle(c, r, Paint()..color = AppTheme.accentGold..style = PaintingStyle.stroke..strokeWidth = 4);
  }
  @override bool shouldRepaint(_) => false;
}
