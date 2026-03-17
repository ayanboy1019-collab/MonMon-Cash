// ============================================================
//  card_flip_game.dart  –  Match pairs memory game
//  8 pairs of cards. Coins per match. Cooldown: 1 hour.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class _Card {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;
  _Card(this.id, this.emoji) : isFlipped = false, isMatched = false;
}

class CardFlipGame extends StatefulWidget {
  const CardFlipGame({super.key});
  @override State<CardFlipGame> createState() => _CardFlipGameState();
}

class _CardFlipGameState extends State<CardFlipGame> {
  static const _emojis = ['🍎','🎮','⭐','🚀','🎯','💎','🦁','🌈'];
  late List<_Card> _cards;
  int? _firstIndex, _secondIndex;
  int _matches = 0;
  int _moves = 0;
  bool _isChecking = false;
  bool _started = false;
  late ConfettiController _confetti;

  @override void initState() { super.initState(); _confetti = ConfettiController(duration: const Duration(seconds: 3)); _init(); }
  @override void dispose() { _confetti.dispose(); super.dispose(); }

  void _init() {
    final doubled = [..._emojis, ..._emojis];
    doubled.shuffle();
    _cards = doubled.asMap().entries.map((e) => _Card(e.key, e.value)).toList();
    _matches = 0; _moves = 0; _firstIndex = null; _secondIndex = null;
  }

  Future<void> _tap(int i) async {
    if (_isChecking || _cards[i].isFlipped || _cards[i].isMatched) return;
    HapticFeedback.selectionClick();
    setState(() => _cards[i].isFlipped = true);

    if (_firstIndex == null) {
      _firstIndex = i;
    } else {
      _secondIndex = i;
      _moves++;
      _isChecking = true;

      if (_cards[_firstIndex!].emoji == _cards[_secondIndex!].emoji) {
        // Match!
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _cards[_firstIndex!].isMatched = true;
          _cards[_secondIndex!].isMatched = true;
          _matches++;
          _firstIndex = null; _secondIndex = null;
          _isChecking = false;
        });
        if (_matches == _emojis.length) { _confetti.play(); _claim(); }
      } else {
        // No match - flip back
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {
          _cards[_firstIndex!].isFlipped = false;
          _cards[_secondIndex!].isFlipped = false;
          _firstIndex = null; _secondIndex = null;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _claim() async {
    // Bonus: fewer moves = more coins (max 300, min 100)
    final coins = (300 - ((_moves - _emojis.length) * 5)).clamp(100, 300);
    final cs = context.read<CoinService>();
    final ok = await cs.checkAndSetCooldown(gameId: 'card_flip', cooldown: const Duration(hours: 1));
    final awarded = ok ? await cs.awardCoins(amount: coins, source: 'card_flip', metadata: {'moves': _moves}) : 0;
    await context.read<AdService>().showInterstitialIfReady();
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🎉 All Matched!', style: AppTheme.heading2, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('$_moves Moves', style: const TextStyle(color: AppTheme.accentNeon, fontSize: 22, fontWeight: FontWeight.w700)),
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
          Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
                Text('Card Flip', style: AppTheme.heading2),
                const Spacer(),
                Text('$_matches/${_emojis.length} pairs | $_moves moves', style: AppTheme.labelText),
              ])),
            Expanded(child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _cards.length,
              itemBuilder: (_, i) {
                final card = _cards[i];
                return GestureDetector(
                  onTap: () => _tap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: card.isMatched ? AppTheme.accentGreen.withOpacity(0.2)
                           : card.isFlipped ? AppTheme.bgCardLight
                           : AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: card.isMatched ? AppTheme.accentGreen : AppTheme.borderColor),
                    ),
                    child: Center(child: card.isFlipped || card.isMatched
                      ? Text(card.emoji, style: const TextStyle(fontSize: 28))
                      : const Icon(Icons.question_mark, color: Colors.white54, size: 24)),
                  ),
                );
              },
            )),
          ]),
        ])),
      ),
    );
  }
}
