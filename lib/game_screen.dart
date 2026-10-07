import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

// All entries are 6 letters; the filter below guarantees it even if one slips.
const _rawWords = [
  'planet', 'rocket', 'banana', 'guitar', 'castle', 'pocket', 'bottle', 'candle',
  'cheese', 'monkey', 'dragon', 'wizard', 'pirate', 'kitten', 'garden', 'forest',
  'desert', 'island', 'meadow', 'valley', 'basket', 'blanket', 'pillow', 'mirror',
  'window', 'curtain', 'carpet', 'orange', 'papaya', 'coconut', 'jaguar', 'cougar',
  'beaver', 'badger', 'ferret', 'weasel', 'hamster', 'parrot', 'falcon', 'turtle',
  'dolphin', 'salmon', 'anchor', 'sailor', 'lantern', 'tunnel', 'bridge', 'ladder',
  'hammer', 'wrench', 'engine', 'bumper', 'pepper', 'garlic', 'carrot', 'celery',
  'muffin', 'waffle', 'noodle', 'pickle', 'butter', 'relish', 'soccer', 'tennis',
  'hockey', 'boxing', 'karate', 'ballet', 'dancer', 'singer', 'actors', 'poetry',
  'novels', 'comics', 'puzzle', 'riddle', 'jokers', 'circus', 'spells', 'parade',
];

class AnagramsScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const AnagramsScreen({super.key, required this.players, required this.callbacks});
  @override
  State<AnagramsScreen> createState() => _AnagramsScreenState();
}

class _AnagramsScreenState extends State<AnagramsScreen> {
  final _rnd = Random();
  late final List<String> _words;
  String _word = '';
  List<String> _pool = [];
  List<bool> _used = [];
  List<int?> _answer = [];
  int _timeLeft = 90;
  int _score = 0;
  int _streak = 0;
  int _solved = 0;
  bool _over = false;
  bool _wrong = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _words = _rawWords.where((w) => w.length == 6).toList();
    _nextWord();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          t.cancel();
          _finish();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextWord() {
    var w = _words[_rnd.nextInt(_words.length)];
    var guard = 0;
    while (w == _word && guard++ < 20) {
      w = _words[_rnd.nextInt(_words.length)];
    }
    _word = w;
    _pool = w.split('')..shuffle(_rnd);
    // never show it already solved
    if (_pool.join() == w) {
      _pool = w.split('').reversed.toList();
    }
    _used = List.filled(6, false);
    _answer = List.filled(6, null);
    _wrong = false;
    setState(() {});
  }

  void _tapPool(int i) {
    if (_over || _used[i]) return;
    final slot = _answer.indexOf(null);
    if (slot == -1) return;
    Sfx.tap();
    setState(() {
      _used[i] = true;
      _answer[slot] = i;
    });
    if (!_answer.contains(null)) _check();
  }

  void _tapAnswer(int j) {
    if (_over || _answer[j] == null) return;
    Sfx.tap();
    setState(() {
      _used[_answer[j]!] = false;
      _answer[j] = null;
      _wrong = false;
    });
  }

  void _backspace() {
    if (_over) return;
    for (var j = 5; j >= 0; j--) {
      if (_answer[j] != null) {
        _tapAnswer(j);
        return;
      }
    }
  }

  void _shuffle() {
    if (_over) return;
    Sfx.click();
    setState(() {
      final free = [for (var i = 0; i < 6; i++) if (!_used[i]) _pool[i]];
      free.shuffle(_rnd);
      var k = 0;
      for (var i = 0; i < 6; i++) {
        if (!_used[i]) _pool[i] = free[k++];
      }
      _wrong = false;
    });
  }

  void _skip() {
    if (_over) return;
    Sfx.tap();
    setState(() {
      _streak = 0;
    });
    _nextWord();
  }

  void _check() {
    final guess = _answer.map((i) => _pool[i!]).join();
    if (guess == _word) {
      final pts = 100 + 25 * _streak;
      Sfx.win();
      setState(() {
        _score += pts;
        _streak++;
        _solved++;
      });
      widget.players[0].score = _score;
      widget.callbacks.refreshHud();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && !_over) _nextWord();
      });
    } else {
      Sfx.lose();
      setState(() {
        _wrong = true;
        _streak = 0;
      });
    }
  }

  void _finish() {
    if (_over) return;
    _over = true;
    Sfx.win();
    widget.callbacks.finish(
      headline: '⚡ Time! You scored $_score!',
      subline: _solved == 0
          ? 'The letters outsmarted you this time. Rematch? 🔤'
          : '$_solved words unscrambled — certified word wizard! 🧙',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Column(
      children: [
        // timer bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('⏱️ $_timeLeft',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _timeLeft <= 10 ? Colors.red : t.text)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _timeLeft / 90,
                    minHeight: 12,
                    backgroundColor: t.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _timeLeft <= 10 ? Colors.red : t.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: t.surface, borderRadius: t.radius),
              child: Text('⭐ $_score',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: t.primary)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _streak >= 2
                    ? Colors.orange.withValues(alpha: 0.2)
                    : t.surface,
                borderRadius: t.radius,
                border: _streak >= 2
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
              ),
              child: Text('🔥 x$_streak streak',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // answer slots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var j = 0; j < 6; j++)
              GestureDetector(
                onTap: () => _tapAnswer(j),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _wrong ? Colors.red.withValues(alpha: 0.25) : t.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _wrong ? Colors.red : t.primary.withValues(alpha: 0.5),
                        width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _answer[j] == null ? '' : _pool[_answer[j]!].toUpperCase(),
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900, color: t.text),
                  ),
                ),
              ),
          ],
        ),
        if (_wrong)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Nope, not quite! Try again 😅',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 18),
        Text('Tap the letters 👇',
            style: TextStyle(color: t.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        // letter pool
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 6; i++)
              GestureDetector(
                onTap: () => _tapPool(i),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _used[i] ? 0.25 : 1.0,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _used[i] ? null : t.headerGradient,
                      color: _used[i] ? t.surface : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _used[i]
                          ? null
                          : [
                              BoxShadow(
                                  color: t.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ],
                    ),
                    alignment: Alignment.center,
                    child: Text(_pool[i].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WajihaButton(label: 'Shuffle 🔀', onTap: _shuffle, primary: false, fontSize: 15),
            const SizedBox(width: 8),
            WajihaButton(label: '⌫', onTap: _backspace, primary: false, fontSize: 18),
            const SizedBox(width: 8),
            WajihaButton(label: 'Skip ⏭️', onTap: _skip, primary: false, fontSize: 15),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
