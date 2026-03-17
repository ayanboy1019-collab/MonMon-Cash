// ============================================================
//  quiz_game.dart  –  10-question quiz for coins
//  +60 coins per correct answer, -0 per wrong (no penalty)
//  Cooldown: 2 hours. Max session: 600 coins.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';

class _Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  const _Question(this.question, this.options, this.correctIndex);
}

const _questions = [
  _Question('What is the capital of Pakistan?',
    ['Karachi','Lahore','Islamabad','Peshawar'], 2),
  _Question('How many days in a leap year?',
    ['364','365','366','367'], 2),
  _Question('Which planet is closest to the Sun?',
    ['Venus','Mars','Earth','Mercury'], 3),
  _Question('1 dollar = how many cents?',
    ['10','50','100','1000'], 2),
  _Question('What color do you get mixing red & blue?',
    ['Green','Purple','Orange','Brown'], 1),
  _Question('How many sides does a hexagon have?',
    ['5','6','7','8'], 1),
  _Question('What is 15 × 4?',
    ['45','50','60','70'], 2),
  _Question('Which is the largest ocean?',
    ['Atlantic','Indian','Arctic','Pacific'], 3),
  _Question('Who invented the telephone?',
    ['Edison','Bell','Tesla','Marconi'], 1),
  _Question('What is the square root of 144?',
    ['10','11','12','13'], 2),
];

class QuizGame extends StatefulWidget {
  const QuizGame({super.key});
  @override State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  int _currentQ = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;
  late ConfettiController _confetti;

  @override
  void initState() { super.initState(); _confetti = ConfettiController(duration: const Duration(seconds: 3)); }
  @override
  void dispose() { _confetti.dispose(); super.dispose(); }

  void _select(int i) {
    if (_answered) return;
    final correct = i == _questions[_currentQ].correctIndex;
    setState(() { _selected = i; _answered = true; if (correct) _score += 60; });
    Future.delayed(const Duration(milliseconds: 1200), _next);
  }

  void _next() {
    if (_currentQ + 1 >= _questions.length) {
      setState(() => _finished = true);
      _confetti.play();
      _claim();
    } else {
      setState(() { _currentQ++; _selected = null; _answered = false; });
    }
  }

  Future<void> _claim() async {
    final cs = context.read<CoinService>();
    final ok = await cs.checkAndSetCooldown(gameId: 'quiz', cooldown: const Duration(hours: 2));
    final awarded = ok ? await cs.awardCoins(amount: _score, source: 'quiz') : 0;
    await context.read<AdService>().showInterstitialIfReady();
    if (!mounted) return;
    _showResult(awarded);
  }

  void _showResult(int awarded) => showDialog(
    context: context, barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Quiz Complete!', style: AppTheme.heading2, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text('$_score Points', style: const TextStyle(color: AppTheme.accentNeon, fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('+$awarded Coins', style: AppTheme.coinText),
      ]),
      actions: [ElevatedButton(
        onPressed: () { Navigator.pop(context); Navigator.pop(context); },
        child: const Text('Collect!'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQ];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Stack(children: [
            Align(alignment: Alignment.topCenter,
              child: ConfettiWidget(confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive)),
            Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
                  Text('Quiz Master', style: AppTheme.heading2),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: neonCard(color: AppTheme.accentGold, radius: 12),
                    child: Text('$_score pts', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700))),
                ])),
              // Progress
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  value: (_currentQ + 1) / _questions.length,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  borderRadius: BorderRadius.circular(4), minHeight: 8)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Question ${_currentQ + 1}/${_questions.length}', style: AppTheme.labelText),
                  Text('+60 per correct answer', style: AppTheme.labelText.copyWith(color: AppTheme.accentGreen)),
                ])),
              const SizedBox(height: 16),
              // Question
              Padding(padding: const EdgeInsets.all(20),
                child: Container(padding: const EdgeInsets.all(20),
                  decoration: gradientCard(),
                  child: Text(q.question, style: AppTheme.heading2.copyWith(fontSize: 20), textAlign: TextAlign.center)
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95))),
              const SizedBox(height: 16),
              // Options
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: q.options.length,
                itemBuilder: (_, i) {
                  Color border = AppTheme.borderColor;
                  if (_answered) {
                    if (i == q.correctIndex) border = AppTheme.accentGreen;
                    else if (i == _selected) border = AppTheme.accentRed;
                  }
                  return GestureDetector(
                    onTap: () => _select(i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border, width: 2)),
                      child: Text(q.options[i], style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideX(begin: 0.1),
                  );
                },
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
