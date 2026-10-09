import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/anagrams_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan_letters.dart';
import '../theme/tile_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu: logo, mode + difficulty pickers, renameable profile,
/// and navigation to Play / Settings / Pro / How-to-play.
class MenuScreen extends StatefulWidget {
  final TileAudio audio;
  final TileSettings settings;
  final StoreService store;
  const MenuScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  TileThemeDef get _t => widget.settings.theme;
  final _nameCtrl = TextEditingController();
  final _name2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _nameCtrl.text = widget.settings.playerNames[0];
    _name2Ctrl.text = widget.settings.playerNames[1];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _name2Ctrl.dispose();
    super.dispose();
  }

  void _play() {
    widget.audio.click();
    final s = widget.settings;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: s,
          store: widget.store,
          mode: GameMode.values[s.mode],
          difficulty: s.difficulty,
        ),
      ),
    );
  }

  void _share() {
    widget.audio.click();
    SharePlus.instance.share(
      ShareParams(
        text:
            'I\'m unscrambling wooden letter tiles in Anagrams — try to beat my score! https://play.google.com/store/apps/details?id=com.gameswajiha.anagrams',
      ),
    );
  }

  void _howToPlay() {
    widget.audio.click();
    final t = _t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.woodMid,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.accent, width: 2)),
        title: Text('How to Play', style: Atelier.display(22, theme: t)),
        content: SingleChildScrollView(
          child: Text(
            '• Tiles land on your tray scrambled — tap them to build the hidden word on the rack.\n\n'
            '• Tap a placed tile to take it back. Shuffle when stuck!\n\n'
            '• Each solved word: +100 points plus +25 per streak step. Chain solves to grow your streak — a wrong guess or a skip resets it.\n\n'
            '• TIMED RUSH: 90 seconds on the clock. Solve as many as you can!\n\n'
            '• RELAXED: no clock — solve 10 words at your own pace.\n\n'
            '• PASS & PLAY DUEL: take turns with a friend, 5 words each. Highest score wins!',
            style: Atelier.body(14, theme: t),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
            child: Text('Got it!', style: Atelier.label(15, theme: t)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  // Top bar: settings, share, pro.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.settings, color: t.accentLight),
                        onPressed: () {
                          widget.audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                audio: widget.audio,
                                settings: s,
                                store: widget.store,
                              ),
                            ),
                          );
                        },
                      ),
                      if (s.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: t.accent.withValues(alpha: 0.25),
                            border: Border.all(color: t.accentLight),
                          ),
                          child: Text('✦ PRO ✦',
                              style: Atelier.label(13, theme: t)),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            widget.audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProScreen(
                                  audio: widget.audio,
                                  settings: s,
                                  store: widget.store,
                                ),
                              ),
                            );
                          },
                          child: Text('Get PRO',
                              style: Atelier.label(14, theme: t)),
                        ),
                      IconButton(
                        icon: Icon(Icons.share, color: t.accentLight),
                        onPressed: _share,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Logo + name.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black54,
                            offset: Offset(0, 8),
                            blurRadius: 18),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/anagrams_logo.webp',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Anagrams', style: Atelier.display(44, theme: t)),
                  Text('Unscramble the wooden tiles!',
                      style: Atelier.body(15, theme: t,
                          color: t.ivory.withValues(alpha: 0.7))),
                  const SizedBox(height: 20),
                  // Profile name (renameable, persisted as ONE JSON string).
                  WoodCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NameField(
                          theme: t,
                          label: s.mode == 2 ? 'Player 1 name' : 'Your name',
                          controller: _nameCtrl,
                          index: 0,
                          settings: s,
                          audio: widget.audio,
                        ),
                        if (s.mode == 2) ...[
                          const SizedBox(height: 10),
                          _NameField(
                            theme: t,
                            label: 'Player 2 name',
                            controller: _name2Ctrl,
                            index: 1,
                            settings: s,
                            audio: widget.audio,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Mode picker.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Game mode',
                        style: Atelier.label(14, theme: t)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              widget.audio.click();
                              s.setMode(i);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: s.mode == i
                                    ? t.accent.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.3),
                                border: Border.all(
                                  color: s.mode == i
                                      ? t.accentLight
                                      : t.accent.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                TileSettings.modeNames[i],
                                style: Atelier.body(13, theme: t),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Difficulty tiers.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Word length',
                        style: Atelier.label(14, theme: t)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int i = 0; i < 4; i++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              widget.audio.click();
                              if (i == 3 && !s.isPro) {
                                // Master is Pro-only: show the Pro screen
                                // instead of silently doing nothing.
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProScreen(
                                      audio: widget.audio,
                                      settings: s,
                                      store: widget.store,
                                    ),
                                  ),
                                );
                                return;
                              }
                              s.setDifficulty(i);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: s.difficulty == i
                                    ? t.accent.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.3),
                                border: Border.all(
                                  color: s.difficulty == i
                                      ? t.accentLight
                                      : t.accent.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Text(TileSettings.difficultyNames[i],
                                      style: Atelier.body(12, theme: t)),
                                  Text(
                                    i == 3 && !s.isPro
                                        ? '🔒 PRO'
                                        : TileSettings.difficultyLetters[i],
                                    style: Atelier.label(10, theme: t),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  WoodButton(
                    label: '▶  PLAY',
                    onTap: _play,
                    theme: t,
                    width: 260,
                    fontSize: 20,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _howToPlay,
                    child: Text('How to play',
                        style: Atelier.label(14, theme: t)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 24, height: 24),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Atelier.body(12,
                              theme: t,
                              color: t.ivory.withValues(alpha: 0.55))),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Renameable player-name field: saves to the single order-preserving
/// JSON-string key on EVERY keystroke, and commits (clean + sync) on focus
/// loss or keyboard-done. Never uses setStringList (unordered StringSet
/// on Android scrambles slot order).
class _NameField extends StatefulWidget {
  final TileThemeDef theme;
  final String label;
  final TextEditingController controller;
  final int index;
  final TileSettings settings;
  final TileAudio audio;
  const _NameField({
    required this.theme,
    required this.label,
    required this.controller,
    required this.index,
    required this.settings,
    required this.audio,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit(silent: true);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Persist the name. Commits also snap the field to the cleaned name.
  void _commit({bool silent = false}) {
    widget.settings.setPlayerName(widget.index, widget.controller.text);
    final clean = widget.settings.playerNames[widget.index];
    if (widget.controller.text != clean) {
      widget.controller.text = clean;
    }
    if (!silent) widget.audio.click();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Atelier.label(13, theme: t)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                style: Atelier.body(16, theme: t),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: t.accentDark),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onChanged: (v) =>
                    widget.settings.setPlayerName(widget.index, v),
                onSubmitted: (_) => _commit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.check_circle, color: t.accentLight),
              onPressed: _commit,
            ),
          ],
        ),
      ],
    );
  }
}
