import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/anagrams_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan_letters.dart';
import '../theme/tile_themes.dart';

/// The play screen. The engine owns ALL state/phases; this widget only
/// renders and animates. Nothing ever pops instantly: deals stagger in,
/// placements spring, reveals flip, wrong guesses shake then bounce back.
class GameScreen extends StatefulWidget {
  final TileAudio audio;
  final TileSettings settings;
  final StoreService store;
  final GameMode mode;
  final int difficulty;
  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.mode,
    required this.difficulty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final AnagramsEngine _engine;
  String _narration = '';
  bool _pauseDialogOpen = false;
  bool _resultHandled = false;
  bool _newBest = false; // snapshot taken before recordGame()

  TileThemeDef get _t => widget.settings.theme;
  TileStyle get _style =>
      TileStyles.all[widget.settings.tileStyle.clamp(0, TileStyles.all.length - 1)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = widget.settings;
    _engine = AnagramsEngine(onEvent: _onEngineEvent);
    _engine.configure(
      mode: widget.mode,
      difficulty: widget.difficulty,
      names: [s.playerNames[0], s.playerNames[1]],
    );
    _engine.addListener(_onEngineTick);
    widget.audio.startGameMusic();
    // Start after the first frame so the rack is laid out for the deal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _engine.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.removeListener(_onEngineTick);
    _engine.dispose();
    widget.audio.startMenuMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _engine.pause();
    } else if (state == AppLifecycleState.resumed && !_pauseDialogOpen) {
      _engine.resume();
    }
  }

  void _onEngineTick() {
    if (!mounted) return;
    setState(() {});
    if (_engine.phase == Phase.over && !_resultHandled) {
      _resultHandled = true;
      _handleResult();
    }
  }

  void _onEngineEvent(EngineEvent e) {
    final a = widget.audio;
    switch (e) {
      case EngineEvent.deal:
        _narration = _engine.mode == GameMode.duel
            ? "${_engine.current.name}'s turn"
            : '';
        break;
      case EngineEvent.place:
        a.place();
        break;
      case EngineEvent.ret:
        a.ret();
        break;
      case EngineEvent.wrong:
        a.invalid();
        _narration = 'Nope, not quite!';
        break;
      case EngineEvent.correct:
        final p = _engine.current;
        a.correct();
        if (p.streak >= 3) a.streak();
        _narration =
            'Correct! ${p.streak >= 2 ? 'Streak x${p.streak} 🔥' : 'Nice!'}';
        break;
      case EngineEvent.skip:
        a.ret();
        break;
      case EngineEvent.shuffle:
        a.shuffle();
        break;
      case EngineEvent.start:
        a.gameStart();
        break;
      case EngineEvent.clockLow:
        a.clockLow();
        _narration = 'Hurry — 10 seconds left!';
        break;
      case EngineEvent.over:
        if (_engine.result?.winner == 0 || _engine.players.length == 1) {
          a.win();
        } else {
          a.lose();
        }
        break;
    }
  }

  Future<void> _handleResult() async {
    final r = _engine.result;
    if (r == null) return;
    final s = widget.settings;
    final timedScore = widget.mode == GameMode.timed ? r.players[0].score : 0;
    final solved = r.players.fold(0, (a, p) => a + p.solved);
    // Snapshot the record BEFORE saving so "New best score!" is accurate.
    _newBest = widget.mode == GameMode.timed &&
        timedScore > 0 &&
        timedScore > s.bestTimed[widget.difficulty.clamp(0, 3)];
    await s.recordGame(
        difficulty: widget.difficulty, timedScore: timedScore, solved: solved);
    // Gentle review nudge once, after a few finished games.
    if (!s.reviewNudged && s.gamesPlayed >= 3) {
      unawaited(s.markReviewNudged());
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _shareResult() {
    widget.audio.click();
    final r = _engine.result;
    String text;
    if (r != null && widget.mode == GameMode.duel) {
      text = r.isTie
          ? 'It was a TIE in Anagrams — ${r.players[0].score} all! Rematch? https://play.google.com/store/apps/details?id=com.gameswajiha.anagrams'
          : '${r.players[r.winner].name} won Anagrams with ${r.players[r.winner].score} points! Think you can do better? https://play.google.com/store/apps/details?id=com.gameswajiha.anagrams';
    } else {
      final p = _engine.players[0];
      text =
          'I scored ${p.score} unscrambling ${p.solved} words in Anagrams! Beat me if you can: https://play.google.com/store/apps/details?id=com.gameswajiha.anagrams';
    }
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _openPause() {
    if (_engine.phase == Phase.over) return;
    widget.audio.click();
    _engine.pause();
    _pauseDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _t.woodMid,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _t.accent, width: 2)),
        title: Text('Paused', style: Atelier.display(22, theme: _t)),
        content: Text('The tiles are waiting patiently.',
            style: Atelier.body(15, theme: _t)),
        actions: [
          TextButton(
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
              _pauseDialogOpen = false;
              _engine.resume();
            },
            child: Text('Resume', style: Atelier.label(15, theme: _t)),
          ),
          TextButton(
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
              _pauseDialogOpen = false;
              _resultHandled = false;
              _narration = '';
              _engine.start();
            },
            child: Text('Restart', style: Atelier.label(15, theme: _t)),
          ),
          TextButton(
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
              _pauseDialogOpen = false;
              Navigator.of(context).pop();
            },
            child: Text('Quit', style: Atelier.label(15, theme: _t)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final e = _engine;
    final width = MediaQuery.of(context).size.width;
    final len = e.wordLength;
    final tileSize = min((width - 96) / len, 58.0);

    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            widget.mode == GameMode.timed
                ? 'Timed Rush'
                : widget.mode == GameMode.relaxed
                    ? 'Relaxed'
                    : 'Pass & Play Duel',
            style: Atelier.display(20, theme: t),
          ),
          centerTitle: true,
          actions: [
            if (e.phase != Phase.over)
              IconButton(
                icon: Icon(Icons.pause, color: t.accentLight),
                onPressed: _openPause,
              ),
          ],
        ),
        body: SafeArea(
          child: e.phase == Phase.over && e.result != null
              ? _ResultView(
                  engine: e,
                  theme: t,
                  settings: widget.settings,
                  isNewBest: _newBest,
                  onShare: _shareResult,
                  onRematch: () {
                    widget.audio.click();
                    _resultHandled = false;
                    _newBest = false;
                    _narration = '';
                    e.start();
                  },
                  onQuit: () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  },
                )
              : Column(
                  children: [
                    const SizedBox(height: 4),
                    _Hud(engine: e, theme: t),
                    const SizedBox(height: 14),
                    // Narration line.
                    SizedBox(
                      height: 24,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _narration,
                          key: ValueKey(_narration),
                          style: Atelier.body(15, theme: t,
                              color: t.accentLight),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Answer rack.
                    _AnswerRack(
                      engine: e,
                      theme: t,
                      style: _style,
                      tileSize: tileSize,
                    ),
                    const SizedBox(height: 22),
                    Text('Tap the tiles',
                        style: Atelier.body(13,
                            theme: t,
                            color: t.ivory.withValues(alpha: 0.6))),
                    const SizedBox(height: 8),
                    // Letter tray (pool).
                    Expanded(
                      child: Center(
                        child: _PoolTray(
                          engine: e,
                          theme: t,
                          style: _style,
                          tileSize: tileSize,
                        ),
                      ),
                    ),
                    // Controls.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CtrlButton(
                            theme: t,
                            icon: Icons.shuffle,
                            label: 'Shuffle',
                            onTap: e.shuffle,
                          ),
                          const SizedBox(width: 10),
                          _CtrlButton(
                            theme: t,
                            icon: Icons.backspace_outlined,
                            label: 'Back',
                            onTap: e.backspace,
                          ),
                          const SizedBox(width: 10),
                          _CtrlButton(
                            theme: t,
                            icon: Icons.skip_next,
                            label: 'Skip',
                            onTap: e.skip,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// HUD: timer bar + score + streak for solo; per-player strips for duel.
class _Hud extends StatelessWidget {
  final AnagramsEngine engine;
  final TileThemeDef theme;
  const _Hud({required this.engine, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final e = engine;
    if (e.mode == GameMode.duel) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int i = 0; i < e.players.length; i++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border.all(
                      color: e.activePlayer == i && e.phase != Phase.over
                          ? t.playerColors[i]
                          : t.accent.withValues(alpha: 0.3),
                      width: e.activePlayer == i ? 2.5 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(e.players[i].name,
                          style: Atelier.label(13, theme: t,
                              color: t.playerColors[i]),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${e.players[i].score}',
                          style: Atelier.display(22, theme: t)),
                      Text('${e.players[i].solved} solved',
                          style: Atelier.body(11,
                              theme: t,
                              color: t.ivory.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    final p = e.players[0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          if (e.mode == GameMode.timed)
            Row(
              children: [
                Text('⏱️ ${e.timeLeft}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: e.timeLeft <= 10
                            ? const Color(0xFFD65348)
                            : t.ivory)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: e.timeLeft / AnagramsEngine.timedSeconds,
                      minHeight: 10,
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          e.timeLeft <= 10
                              ? const Color(0xFFD65348)
                              : t.accent),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Word ${min(e.wordsPlayed + 1, e.totalWords)} of ${e.totalWords}',
                    style: Atelier.label(14, theme: t)),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border.all(color: t.accent.withValues(alpha: 0.5)),
                ),
                child: Text('⭐ ${p.score}',
                    style: Atelier.display(20, theme: t)),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: p.streak >= 2
                      ? const Color(0xFFB45A3C).withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                      color: p.streak >= 2
                          ? const Color(0xFFF0BB72)
                          : t.accent.withValues(alpha: 0.5)),
                ),
                child: Text('🔥 x${p.streak}',
                    style: Atelier.body(16, theme: t)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Answer rack: slots the player builds the word on.
/// - placements spring in (scale pop)
/// - correct: sequential green pulse
/// - skipped: letters flip in one-by-one revealing the word
/// - wrong: red flash + shake, then letters bounce back
class _AnswerRack extends StatelessWidget {
  final AnagramsEngine engine;
  final TileThemeDef theme;
  final TileStyle style;
  final double tileSize;
  const _AnswerRack({
    required this.engine,
    required this.theme,
    required this.style,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final t = theme;
    final revealing = e.phase == Phase.revealing;
    final isCorrect = revealing && e.revealKind == RevealKind.correct;
    final isSkipped = revealing && e.revealKind == RevealKind.skipped;
    final isWrong = revealing && e.revealKind == RevealKind.none;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: t.trayEdge, width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0xAA000000), offset: Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int j = 0; j < e.wordLength; j++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _slot(j, isCorrect, isSkipped, isWrong, t),
            ),
        ],
      ),
    );
  }

  Widget _slot(int j, bool isCorrect, bool isSkipped, bool isWrong,
      TileThemeDef t) {
    final e = engine;
    final idx = e.answer[j];

    // Skipped reveal: flip the true letters in one by one.
    if (isSkipped) {
      final letter = e.revealWord.length > j ? e.revealWord[j] : '';
      return TweenAnimationBuilder<double>(
        key: ValueKey('flip${e.revealToken}_$j'),
        tween: Tween(begin: -pi / 2, end: 0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (_, v, __) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(v),
          child: LetterTile(
            letter: letter,
            size: tileSize,
            face: style.face,
            edge: style.edge,
            textColor: style.text,
            radius: style.radius,
          ),
        ),
      );
    }

    if (idx == null) {
      // Empty slot.
      return Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(style.radius),
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
              color: t.accent.withValues(alpha: 0.35), width: 1.5),
        ),
      );
    }

    final letter = e.pool[idx];
    final tile = LetterTile(
      letter: letter,
      size: tileSize,
      face: style.face,
      edge: style.edge,
      textColor: style.text,
      radius: style.radius,
      highlighted: isCorrect,
      danger: isWrong,
    );

    // Correct: sequential pulse across the slots.
    if (isCorrect) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('pulse${e.revealToken}_$j'),
        tween: Tween(begin: 1.0, end: 1.0),
        duration: Duration(milliseconds: 200 + j * 90),
        builder: (_, __, child) {
          final pulse = TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.15),
            duration: const Duration(milliseconds: 260),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Transform.scale(scale: v, child: tile),
          );
          return pulse;
        },
      );
    }

    // Wrong: shake the rack.
    if (isWrong) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('shake${e.wrongFlashToken}'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        builder: (_, v, __) {
          final dx = sin(v * pi * 4) * 8 * (1 - v);
          return Transform.translate(offset: Offset(dx, 0), child: tile);
        },
      );
    }

    // Normal placement: spring pop.
    return TweenAnimationBuilder<double>(
      key: ValueKey('pop${e.dealToken}_${idx}_$j'),
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform.scale(scale: v, child: tile),
    );
  }
}

// ---------------------------------------------------------------------------
/// Letter tray: pool tiles. Deals drop in staggered; placed tiles sink;
/// a wrong guess bounces them back after the flash.
class _PoolTray extends StatelessWidget {
  final AnagramsEngine engine;
  final TileThemeDef theme;
  final TileStyle style;
  final double tileSize;
  const _PoolTray({
    required this.engine,
    required this.theme,
    required this.style,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final t = theme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.tray.withValues(alpha: 0.9), t.trayEdge.withValues(alpha: 0.9)],
        ),
        border: Border.all(color: t.trayEdge, width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0xAA000000), offset: Offset(0, 6), blurRadius: 12),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (int i = 0; i < e.pool.length; i++)
            _poolTile(i, e, t),
        ],
      ),
    );
  }

  Widget _poolTile(int i, AnagramsEngine e, TileThemeDef t) {
    final placed = e.used[i];
    final inputOpen = e.inputOpen;
    Widget tile = Opacity(
      opacity: placed ? 0.22 : 1.0,
      child: LetterTile(
        letter: e.pool[i],
        size: tileSize,
        face: style.face,
        edge: style.edge,
        textColor: style.text,
        radius: style.radius,
        dimmed: placed,
      ),
    );

    // Bounce back after a wrong guess.
    if (!placed) {
      tile = TweenAnimationBuilder<double>(
        key: ValueKey('bounce${e.recollectToken}_$i'),
        tween: Tween(begin: 0.7, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.elasticOut,
        builder: (_, v, __) => Transform.scale(scale: v, child: tile),
      );
    }

    // Staggered deal drop-in.
    tile = TweenAnimationBuilder<double>(
      key: ValueKey('deal${e.dealToken}_$i'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + i * 70),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 46),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: tile,
    );

    return GestureDetector(
      onTap: inputOpen ? () => e.tapPool(i) : null,
      child: tile,
    );
  }
}

// ---------------------------------------------------------------------------
class _CtrlButton extends StatelessWidget {
  final TileThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CtrlButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.32),
          border: Border.all(color: t.accent.withValues(alpha: 0.6), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: t.accentLight, size: 20),
            const SizedBox(width: 6),
            Text(label, style: Atelier.label(14, theme: t)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Game-over scoreboard with staggered reveal, share, rematch, quit.
class _ResultView extends StatelessWidget {
  final AnagramsEngine engine;
  final TileThemeDef theme;
  final TileSettings settings;
  final bool isNewBest;
  final VoidCallback onShare;
  final VoidCallback onRematch;
  final VoidCallback onQuit;
  const _ResultView({
    required this.engine,
    required this.theme,
    required this.settings,
    required this.isNewBest,
    required this.onShare,
    required this.onRematch,
    required this.onQuit,
  });

  String get _headline {
    final e = engine;
    if (e.mode == GameMode.duel) {
      final r = e.result!;
      if (r.isTie) return 'It\'s a tie!';
      return '${r.players[r.winner].name} wins!';
    }
    if (e.mode == GameMode.timed) {
      if (isNewBest) return '🏆 New best score!';
      return '⏱️ Time\'s up!';
    }
    return 'All words done!';
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final e = engine;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Staggered headline.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (_, v, __) => Transform.scale(
              scale: v,
              child: Text(_headline,
                  style: Atelier.display(30, theme: t),
                  textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 16),
          // Player cards, staggered.
          for (int i = 0; i < e.players.length; i++)
            TweenAnimationBuilder<double>(
              key: ValueKey('res$i'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + i * 160),
              curve: Curves.easeOut,
              builder: (_, v, __) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, (1 - v) * 30),
                  child: _PlayerCard(
                    theme: t,
                    player: e.players[i],
                    isWinner: e.result!.winner == i,
                    accent: t.playerColors[i % t.playerColors.length],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WoodButton(
                  label: '🔁 Rematch', onTap: onRematch, theme: t, width: 150),
              const SizedBox(width: 12),
              WoodButton(
                  label: 'Share',
                  onTap: onShare,
                  theme: t,
                  width: 110,
                  primary: false),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onQuit,
            child: Text('Back to menu', style: Atelier.label(14, theme: t)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final TileThemeDef theme;
  final AnagramPlayer player;
  final bool isWinner;
  final Color accent;
  const _PlayerCard({
    required this.theme,
    required this.player,
    required this.isWinner,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.woodMid.withValues(alpha: 0.9),
            t.woodDeep.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
            color: isWinner ? t.accentLight : accent, width: isWinner ? 3 : 2),
      ),
      child: Row(
        children: [
          if (isWinner)
            Text('👑 ', style: Atelier.display(24, theme: t)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: Atelier.label(16, theme: t)),
                const SizedBox(height: 2),
                Text(
                    '${player.solved} words · best streak x${player.bestStreak}',
                    style: Atelier.body(13,
                        theme: t,
                        color: t.ivory.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Text('${player.score}', style: Atelier.display(30, theme: t)),
        ],
      ),
    );
  }
}
