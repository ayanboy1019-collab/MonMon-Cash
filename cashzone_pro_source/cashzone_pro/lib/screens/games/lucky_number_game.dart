// ============================================================
//  lucky_number_game.dart  –  Number guessing game
//  Guess 1-100. Closer guess = more coins. Cooldown 1 hour.
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class LuckyNumberGame extends StatefulWidget {
  const LuckyNumberGame({super.key});
  @override State<LuckyNumberGame> createState() => _LuckyNumberGameState();
}

class _LuckyNumberGameState extends State<LuckyNumberGame> {
  final _ctrl = TextEditingController();
  int _secret = Random().nextInt(100) + 1;
  int _attempts = 3;
  String _hint = '';
  bool _done = false;

  Future<void> _guess() async {
    if (_done || _ctrl.text.isEmpty) return;
    final n = int.tryParse(_ctrl.text);
    if (n == null || n < 1 || n > 100) { setState(() => _hint = 'Enter 1-100'); return; }
    _attempts--;
    final diff = (n - _secret).abs();
    if (n == _secret || _attempts == 0) {
      final coins = diff == 0 ? 500 : (diff <= 5 ? 300 : diff <= 15 ? 150 : 50);
      setState(() { _done = true; _hint = n == _secret ? '🎯 Exact! +$coins coins!' : 'Secret was $_secret. +$coins coins'; });
      final cs = context.read<CoinService>();
      final ok = await cs.checkAndSetCooldown(gameId: 'lucky_num', cooldown: const Duration(hours: 1));
      if (ok) await cs.awardCoins(amount: coins, source: 'lucky_number');
      await context.read<AdService>().showInterstitialIfReady();
    } else {
      setState(() => _hint = n < _secret ? '⬆️ Higher! ($_attempts left)' : '⬇️ Lower! ($_attempts left)');
    }
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
            Text('Lucky Number', style: AppTheme.heading2),
          ])),
        Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Guess a number between\n1 and 100', style: AppTheme.bodyText.copyWith(fontSize: 18, color: AppTheme.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('3 attempts • Closer = more coins', style: AppTheme.labelText),
          const SizedBox(height: 32),
          Container(padding: const EdgeInsets.all(20), decoration: gradientCard(), child: Column(children: [
            Text('Coins: 500 exact • 300 ±5 • 150 ±15 • 50 else', style: AppTheme.labelText, textAlign: TextAlign.center),
          ])),
          const SizedBox(height: 32),
          if (!_done) ...[
            TextField(controller: _ctrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: '??')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _guess, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              child: const Text('GUESS', style: TextStyle(fontSize: 18))),
          ],
          if (_hint.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(_hint, style: TextStyle(color: _done ? AppTheme.accentGold : AppTheme.accentNeon, fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ],
          if (_done) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Games')),
          ],
        ])))),
      ]))),
  );
}
