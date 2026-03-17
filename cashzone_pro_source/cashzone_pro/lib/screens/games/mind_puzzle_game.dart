// mind_puzzle_game.dart – Math puzzles for coins
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class MindPuzzleGame extends StatefulWidget {
  const MindPuzzleGame({super.key});
  @override State<MindPuzzleGame> createState() => _MindPuzzleGameState();
}

class _MindPuzzleGameState extends State<MindPuzzleGame> {
  final _rand = Random();
  late int _a, _b, _answer;
  late String _op;
  final _ctrl = TextEditingController();
  int _score = 0, _round = 0;
  static const _totalRounds = 10;
  String _feedback = '';

  @override void initState() { super.initState(); _nextPuzzle(); }

  void _nextPuzzle() {
    _a = _rand.nextInt(20) + 1; _b = _rand.nextInt(20) + 1;
    final ops = ['+', '-', '×'];
    _op = ops[_rand.nextInt(ops.length)];
    _answer = _op == '+' ? _a + _b : _op == '-' ? _a - _b : _a * _b;
    setState(() { _feedback = ''; });
    _ctrl.clear();
  }

  void _submit() {
    final n = int.tryParse(_ctrl.text);
    if (n == null) return;
    if (n == _answer) { _score += 40; setState(() => _feedback = '✅ Correct! +40'); }
    else { setState(() => _feedback = '❌ Answer was $_answer'); }
    _round++;
    if (_round >= _totalRounds) { _claim(); return; }
    Future.delayed(const Duration(milliseconds: 800), _nextPuzzle);
  }

  Future<void> _claim() async {
    final cs = context.read<CoinService>();
    final ok = await cs.checkAndSetCooldown(gameId: 'mind_puzzle', cooldown: const Duration(hours: 2));
    final awarded = ok ? await cs.awardCoins(amount: _score.clamp(0, 400), source: 'mind_puzzle') : 0;
    await context.read<AdService>().showInterstitialIfReady();
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Mind Puzzle Complete! 🧠', style: AppTheme.heading2, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('+$awarded Coins', style: AppTheme.coinText),
      ]),
      actions: [ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Collect!'))],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
            Text('Mind Puzzle', style: AppTheme.heading2), const Spacer(),
            Text('$_round/$_totalRounds', style: AppTheme.labelText),
          ])),
        LinearProgressIndicator(value: _round / _totalRounds, backgroundColor: AppTheme.borderColor,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple), minHeight: 8),
        Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$_score pts', style: AppTheme.coinText),
          const SizedBox(height: 32),
          Container(padding: const EdgeInsets.all(30), decoration: gradientCard(),
            child: Text('$_a $_op $_b = ?', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 40, fontWeight: FontWeight.w900))),
          const SizedBox(height: 24),
          TextField(controller: _ctrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center, decoration: const InputDecoration(hintText: 'Your answer')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
            child: const Text('SUBMIT', style: TextStyle(fontSize: 18))),
          if (_feedback.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_feedback, style: TextStyle(color: _feedback.startsWith('✅') ? AppTheme.accentGreen : AppTheme.accentRed, fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ])))),
      ]))),
  );
}
