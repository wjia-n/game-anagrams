import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'word_lists.dart';

// ---------------------------------------------------------------------------
// Game modes
// ---------------------------------------------------------------------------
enum GameMode { timed, relaxed, duel }

/// Turn phases owned ENTIRELY by the engine. The UI only renders.
/// [dealing]  — new word's letters are dropping onto the tray; input locked,
///              the engine will open input shortly on its own timer.
/// [playing]  — input open.
/// [revealing]— result animation is running (correct/skipped); input locked,
///              the engine advances on its own timer.
/// [over]     — round finished; result is final.
/// Stuck states are impossible by construction: every transient phase is
/// armed with the single [_phaseTimer], and the [_watchdog] re-arms any
/// phase found without a live timer.
enum Phase { idle, dealing, playing, revealing, over }

/// What kind of reveal animation the UI should run.
enum RevealKind { none, correct, skipped }

/// Events the engine emits for audio/UI side-effects.
enum EngineEvent {
  deal,
  place,
  ret,
  wrong,
  correct,
  skip,
  shuffle,
  start,
  over,
  clockLow,
}

class AnagramPlayer {
  String name;
  int score = 0;
  int streak = 0;
  int solved = 0;
  int bestStreak = 0;
  AnagramPlayer({required this.name});
}

/// Final scoreboard handed to the UI when [phase] reaches [Phase.over].
class GameResult {
  final List<AnagramPlayer> players;
  final int mode; // GameMode.index
  final int difficulty;
  final int wordsPlayed;
  final bool isTie;
  final int winner; // -1 for tie
  const GameResult({
    required this.players,
    required this.mode,
    required this.difficulty,
    required this.wordsPlayed,
    required this.isTie,
    required this.winner,
  });
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------
class AnagramsEngine extends ChangeNotifier {
  final Random _rnd = Random();
  final void Function(EngineEvent) onEvent;

  GameMode mode = GameMode.timed;
  int difficulty = 1; // 0 easy(4), 1 classic(5), 2 expert(6), 3 master(7)

  List<AnagramPlayer> players = [AnagramPlayer(name: 'Player 1')];
  int activePlayer = 0;
  Phase phase = Phase.idle;

  // Current word state.
  String word = '';
  List<String> pool = [];
  List<bool> used = [];
  List<int?> answer = [];
  int get wordLength => [4, 5, 6, 7][difficulty.clamp(0, 3)];

  // Timed mode.
  int timeLeft = 90;
  static const timedSeconds = 90;

  // Duel / relaxed progress.
  static const duelWordsPerPlayer = 5;
  static const relaxedWords = 10;
  int wordsPlayed = 0; // words completed in this round

  // Reveal animation state (UI reads these; [revealToken] bumps per reveal).
  RevealKind revealKind = RevealKind.none;
  String revealWord = '';
  int revealToken = 0;

  // Animation tokens for transient effects.
  int wrongFlashToken = 0;
  int recollectToken = 0;
  int dealToken = 0;

  bool paused = false;
  GameResult? result;

  Timer? _phaseTimer; // single phase-transition timer
  Timer? _tick; // 1s clock for timed mode
  Timer? _watchdog; // stuck-state recovery
  void Function()? _pendingThen; // continuation armed with the phase timer
  DateTime _phaseSince = DateTime.now();
  bool _over = false;
  bool _clockLowFired = false;
  String _lastWord = '';

  AnagramsEngine({required this.onEvent});

  int get totalWords =>
      mode == GameMode.duel ? duelWordsPerPlayer * players.length : relaxedWords;

  AnagramPlayer get current => players[activePlayer];

  // ------------------------------------------------------------ lifecycle
  void configure({
    required GameMode mode,
    required int difficulty,
    required List<String> names,
  }) {
    this.mode = mode;
    this.difficulty = difficulty.clamp(0, 3);
    players = mode == GameMode.duel
        ? [AnagramPlayer(name: names[0]), AnagramPlayer(name: names[1])]
        : [AnagramPlayer(name: names[0])];
    activePlayer = 0;
    wordsPlayed = 0;
    _over = false;
    result = null;
    revealKind = RevealKind.none;
    notifyListeners();
  }

  /// Start (or restart) the round. Engine-owned from here on.
  void start() {
    _cancelAll();
    activePlayer = 0;
    wordsPlayed = 0;
    _over = false;
    _clockLowFired = false;
    result = null;
    timeLeft = timedSeconds;
    for (final p in players) {
      p.score = 0;
      p.streak = 0;
      p.solved = 0;
      p.bestStreak = 0;
    }
    // Clock only ticks in timed mode.
    if (mode == GameMode.timed) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    onEvent(EngineEvent.start);
    _deal();
    notifyListeners();
  }

  void _onTick() {
    if (paused || _over || mode != GameMode.timed) return;
    if (phase == Phase.over || phase == Phase.idle) return;
    timeLeft--;
    if (timeLeft == 10 && !_clockLowFired) {
      _clockLowFired = true;
      onEvent(EngineEvent.clockLow);
    }
    if (timeLeft <= 0) {
      timeLeft = 0;
      _finish();
    }
    notifyListeners();
  }

  void _deal() {
    if (_over) return;
    final len = wordLength;
    final list = WordLists.forLength(len);
    var w = list[_rnd.nextInt(list.length)];
    var guard = 0;
    while ((w == _lastWord || _poolIsSolved(w)) && guard++ < 40) {
      w = list[_rnd.nextInt(list.length)];
    }
    _lastWord = w;
    word = w;
    pool = w.split('')..shuffle(_rnd);
    if (pool.join() == w) pool = w.split('').reversed.toList();
    used = List.filled(len, false);
    answer = List.filled(len, null);
    revealKind = RevealKind.none;
    dealToken++;
    onEvent(EngineEvent.deal);
    _enterPhase(Phase.dealing, const Duration(milliseconds: 550), () {
      if (_over) return;
      _enterPhase(Phase.playing);
    });
  }

  /// Shuffle that is guaranteed NOT to show the solved word (used for the
  /// fresh deal above).
  bool _poolIsSolved(String w) {
    final p = w.split('')..shuffle(_rnd);
    return p.join() == w;
  }

  // ------------------------------------------------------------- input
  bool get inputOpen => phase == Phase.playing && !paused && !_over;

  void tapPool(int i) {
    if (!inputOpen || i < 0 || i >= pool.length || used[i]) return;
    final slot = answer.indexOf(null);
    if (slot == -1) return;
    used[i] = true;
    answer[slot] = i;
    onEvent(EngineEvent.place);
    notifyListeners();
    if (!answer.contains(null)) _check();
  }

  void tapAnswer(int j) {
    if (!inputOpen || j < 0 || j >= answer.length || answer[j] == null) return;
    used[answer[j]!] = false;
    answer[j] = null;
    onEvent(EngineEvent.ret);
    notifyListeners();
  }

  void backspace() {
    if (!inputOpen) return;
    for (var j = answer.length - 1; j >= 0; j--) {
      if (answer[j] != null) {
        tapAnswer(j);
        return;
      }
    }
  }

  void shuffle() {
    if (!inputOpen) return;
    final free = [for (var i = 0; i < pool.length; i++) if (!used[i]) i];
    if (free.length < 2) return;
    final letters = [for (final i in free) pool[i]]..shuffle(_rnd);
    var k = 0;
    for (final i in free) {
      pool[i] = letters[k++];
    }
    // Keep it scrambled.
    if (free.length == pool.length && pool.join() == word) {
      pool = pool.reversed.toList();
    }
    onEvent(EngineEvent.shuffle);
    notifyListeners();
  }

  void skip() {
    if (!inputOpen) return;
    final p = current;
    p.streak = 0;
    revealKind = RevealKind.skipped;
    revealWord = word;
    revealToken++;
    onEvent(EngineEvent.skip);
    _enterPhase(Phase.revealing, const Duration(milliseconds: 1600), _advance);
  }

  // -------------------------------------------------------------- logic
  void _check() {
    final guess = answer.map((i) => pool[i!]).join();
    final p = current;
    if (guess == word) {
      final pts = 100 + 25 * p.streak;
      p.score += pts;
      p.streak++;
      p.solved++;
      if (p.streak > p.bestStreak) p.bestStreak = p.streak;
      revealKind = RevealKind.correct;
      revealWord = word;
      revealToken++;
      onEvent(EngineEvent.correct);
      _enterPhase(Phase.revealing, const Duration(milliseconds: 1000), _advance);
    } else {
      p.streak = 0;
      wrongFlashToken++;
      onEvent(EngineEvent.wrong);
      notifyListeners();
      // Bounce the letters back to the tray after the flash.
      _enterPhase(Phase.revealing, const Duration(milliseconds: 650), () {
        if (_over) return;
        for (var j = 0; j < answer.length; j++) {
          if (answer[j] != null) {
            used[answer[j]!] = false;
            answer[j] = null;
          }
        }
        recollectToken++;
        _enterPhase(Phase.playing);
      });
    }
  }

  /// Word done (solved or skipped): next word / next duelist / finish.
  void _advance() {
    if (_over) return;
    wordsPlayed++;
    if (mode == GameMode.duel) {
      activePlayer = (activePlayer + 1) % players.length;
      if (wordsPlayed >= totalWords) {
        _finish();
        return;
      }
    } else if (mode == GameMode.relaxed && wordsPlayed >= relaxedWords) {
      _finish();
      return;
    }
    // Timed mode just keeps dealing until the clock dies.
    _deal();
  }

  void _finish() {
    if (_over) return;
    _over = true;
    _cancelPhase();
    _tick?.cancel();
    _tick = null;
    int winner = -1;
    bool tie = false;
    if (players.length > 1) {
      if (players[0].score == players[1].score) {
        tie = true;
      } else {
        winner = players[0].score > players[1].score ? 0 : 1;
      }
    } else {
      winner = 0;
    }
    result = GameResult(
      players: players,
      mode: mode.index,
      difficulty: difficulty,
      wordsPlayed: wordsPlayed,
      isTie: tie,
      winner: winner,
    );
    _enterPhase(Phase.over);
    onEvent(EngineEvent.over);
  }

  // ---------------------------------------------------- phase machinery
  void _enterPhase(Phase p, [Duration? after, void Function()? then]) {
    phase = p;
    _phaseSince = DateTime.now();
    _cancelPhase();
    _pendingThen = then;
    if (after != null && then != null) {
      _phaseTimer = Timer(after, () {
        _phaseTimer = null;
        _pendingThen = null;
        if (paused || _over) return;
        then();
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _cancelPhase() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
  }

  void _cancelAll() {
    _cancelPhase();
    _tick?.cancel();
    _tick = null;
    _watchdog?.cancel();
    _watchdog = null;
  }

  /// Stuck-state recovery: any transient phase without a live timer gets
  /// re-armed. Runs every 3s; also restarts a lost clock.
  void _recover() {
    if (_over || phase == Phase.idle || paused) return;
    if ((phase == Phase.dealing || phase == Phase.revealing) &&
        _phaseTimer == null) {
      // Phase lost its timer (e.g. app was force-suspended). Recover
      // gracefully: dealing -> open input; revealing -> re-run the stored
      // continuation, or the wrong-guess bounce-back for revealKind.none.
      if (phase == Phase.dealing) {
        _enterPhase(Phase.playing);
      } else if (_pendingThen != null) {
        final then = _pendingThen;
        _pendingThen = null;
        then();
        notifyListeners();
      } else if (revealKind == RevealKind.none) {
        for (var j = 0; j < answer.length; j++) {
          if (answer[j] != null) {
            used[answer[j]!] = false;
            answer[j] = null;
          }
        }
        recollectToken++;
        _enterPhase(Phase.playing);
      } else {
        _advance();
      }
    }
    if (mode == GameMode.timed &&
        phase != Phase.over &&
        _tick == null &&
        !paused) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }
  }

  // ------------------------------------------------------------- pause
  void pause() {
    if (paused || _over) return;
    paused = true;
    _cancelPhase();
    _tick?.cancel();
    _tick = null;
    notifyListeners();
  }

  void resume() {
    if (!paused || _over) return;
    paused = false;
    // Re-arm whatever phase we were in.
    switch (phase) {
      case Phase.dealing:
        _enterPhase(Phase.dealing, const Duration(milliseconds: 400), () {
          if (_over) return;
          _enterPhase(Phase.playing);
        });
        break;
      case Phase.revealing:
        final then = _pendingThen;
        _enterPhase(Phase.revealing, const Duration(milliseconds: 700),
            then ?? _advance);
        break;
      case Phase.playing:
        if (mode == GameMode.timed) {
          _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
        }
        break;
      case Phase.idle:
      case Phase.over:
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
