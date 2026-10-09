import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan_letters.dart';
import '../theme/tile_themes.dart';
import 'custom_theme_screen.dart';
import 'pro_screen.dart';

/// Settings: audio, renameable players, themes, tile styles, custom theme
/// creator, stats, share, review, reset.
class SettingsScreen extends StatelessWidget {
  final TileAudio audio;
  final TileSettings settings;
  final StoreService store;
  const SettingsScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  TileThemeDef get _t => settings.theme;

  void _review() {
    audio.click();
    try {
      InAppReview.instance
          .requestReview()
          .catchError((_) {})
          .timeout(const Duration(seconds: 3), onTimeout: () {});
    } catch (_) {}
  }

  void _share() {
    audio.click();
    SharePlus.instance.share(
      ShareParams(
        text:
            'Anagrams — unscramble wooden letter tiles against the clock! https://play.google.com/store/apps/details?id=com.gameswajiha.anagrams',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = settings;
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
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Atelier.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sound', style: Atelier.label(15, theme: t)),
                  const SizedBox(height: 8),
                  WoodCard(
                    theme: t,
                    child: Column(
                      children: [
                        _SwitchRow(
                          theme: t,
                          label: '🎵 Music',
                          value: s.musicOn,
                          onChanged: (v) {
                            s.setMusic(v);
                            audio.configure(
                                musicOn: v,
                                sfxOn: s.sfxOn,
                                volume: s.volume);
                            if (v) audio.startMenuMusic();
                            audio.click();
                          },
                        ),
                        _SwitchRow(
                          theme: t,
                          label: '🔔 Sound effects',
                          value: s.sfxOn,
                          onChanged: (v) {
                            s.setSfx(v);
                            audio.configure(
                                musicOn: s.musicOn,
                                sfxOn: v,
                                volume: s.volume);
                            audio.click();
                          },
                        ),
                        Row(
                          children: [
                            Text('🔊 Volume',
                                style: Atelier.body(15, theme: t)),
                            Expanded(
                              child: Slider(
                                value: s.volume,
                                activeColor: t.accent,
                                inactiveColor:
                                    t.accent.withValues(alpha: 0.3),
                                onChanged: (v) {
                                  s.setVolume(v);
                                  audio.configure(
                                      musicOn: s.musicOn,
                                      sfxOn: s.sfxOn,
                                      volume: v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Players', style: Atelier.label(15, theme: t)),
                  const SizedBox(height: 8),
                  WoodCard(
                    theme: t,
                    child: Column(
                      children: [
                        for (int i = 0; i < 2; i++)
                          _PlayerNameRow(
                            theme: t,
                            settings: s,
                            audio: audio,
                            index: i,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Workshop theme',
                          style: Atelier.label(15, theme: t)),
                      const Spacer(),
                      if (!s.isPro)
                        TextButton(
                          onPressed: () {
                            audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProScreen(
                                    audio: audio,
                                    settings: s,
                                    store: store),
                              ),
                            );
                          },
                          child: Text('🔒 Unlock all',
                              style: Atelier.label(12, theme: t)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ThemeGrid(
                      theme: t, settings: s, audio: audio, store: store),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: s.isPro
                        ? () {
                            audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomThemeScreen(
                                    audio: audio, settings: s),
                              ),
                            );
                          }
                        : () {
                            audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProScreen(
                                    audio: audio,
                                    settings: s,
                                    store: store),
                              ),
                            );
                          },
                    child: Text(
                        s.isPro
                            ? '🎨 Custom theme creator'
                            : '🎨 Custom theme creator (PRO)',
                        style: Atelier.label(14, theme: t)),
                  ),
                  const SizedBox(height: 16),
                  Text('Letter tiles', style: Atelier.label(15, theme: t)),
                  const SizedBox(height: 8),
                  _TileStyleGrid(
                      theme: t, settings: s, audio: audio, store: store),
                  const SizedBox(height: 16),
                  Text('Stats', style: Atelier.label(15, theme: t)),
                  const SizedBox(height: 8),
                  WoodCard(
                    theme: t,
                    child: Column(
                      children: [
                        _StatRow(
                            theme: t,
                            label: 'Games played',
                            value: '${s.gamesPlayed}'),
                        _StatRow(
                            theme: t,
                            label: 'Words solved',
                            value: '${s.wordsSolved}'),
                        for (int i = 0; i < 4; i++)
                          _StatRow(
                            theme: t,
                            label:
                                'Best · ${TileSettings.difficultyNames[i]}',
                            value: '${s.bestTimed[i]}',
                          ),
                        _StatRow(
                            theme: t,
                            label: 'Best relaxed round',
                            value: '${s.bestRelaxed} words'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      spacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _CtrlChip(
                            theme: t,
                            label: '⭐ Rate us',
                            onTap: _review),
                        _CtrlChip(
                            theme: t, label: '📤 Share', onTap: _share),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('Anagrams v2.0 · Credits: WAJIHA',
                        style: Atelier.body(12,
                            theme: t,
                            color: t.ivory.withValues(alpha: 0.5))),
                  ),
                  const SizedBox(height: 20),
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
class _SwitchRow extends StatelessWidget {
  final TileThemeDef theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow(
      {required this.theme,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Atelier.body(15, theme: theme))),
        Switch(
          value: value,
          activeThumbColor: theme.accentLight,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PlayerNameRow extends StatefulWidget {
  final TileThemeDef theme;
  final TileSettings settings;
  final TileAudio audio;
  final int index;
  const _PlayerNameRow(
      {required this.theme,
      required this.settings,
      required this.audio,
      required this.index});

  @override
  State<_PlayerNameRow> createState() => _PlayerNameRowState();
}

class _PlayerNameRowState extends State<_PlayerNameRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.settings.playerNames[widget.index]);
    _focus = FocusNode();
    // Commit on focus loss: persist + snap the field to the cleaned name.
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit(silent: true);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _commit({bool silent = false}) {
    widget.settings.setPlayerName(widget.index, _ctrl.text);
    final clean = widget.settings.playerNames[widget.index];
    if (_ctrl.text != clean) _ctrl.text = clean;
    if (!silent) widget.audio.click();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text('Player ${widget.index + 1}',
                style: Atelier.body(14, theme: t)),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: Atelier.body(15, theme: t),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: t.accentDark),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              // Save on EVERY keystroke to the single JSON-string key.
              onChanged: (v) =>
                  widget.settings.setPlayerName(widget.index, v),
              onSubmitted: (_) => _commit(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final TileThemeDef theme;
  final String label;
  final String value;
  const _StatRow(
      {required this.theme, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Atelier.body(14, theme: theme))),
          Text(value, style: Atelier.label(14, theme: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Theme picker grid: 16 workshop themes, Pro ones locked with a badge.
class _ThemeGrid extends StatelessWidget {
  final TileThemeDef theme;
  final TileSettings settings;
  final TileAudio audio;
  final StoreService store;
  const _ThemeGrid(
      {required this.theme,
      required this.settings,
      required this.audio,
      required this.store});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = settings;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: TileThemes.all.length + (s.isPro ? 1 : 0),
      itemBuilder: (_, i) {
        final isCustom = i == TileThemes.all.length;
        final def = isCustom ? s.customTheme : TileThemes.all[i];
        final locked = !isCustom &&
            i >= TileThemes.freeCount &&
            !s.isPro;
        final selected = !isCustom
            ? s.themeId == def.id
            : s.themeId == 'custom';
        return GestureDetector(
          onTap: () {
            audio.click();
            if (locked) {
              // Locked theme: take the user to PRO instead of doing nothing.
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProScreen(
                      audio: audio, settings: s, store: store),
                ),
              );
              return;
            }
            s.setTheme(isCustom ? 'custom' : def.id);
          },
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [def.woodMid, def.woodDark],
                      ),
                      border: Border.all(
                        color: selected ? t.accentLight : t.accentDark,
                        width: selected ? 3 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: def.tileFace,
                          border:
                              Border.all(color: def.tileEdge, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text('A',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: def.tileText)),
                      ),
                    ),
                  ),
                  if (locked)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock,
                            size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                locked ? '🔒 ${def.name}' : def.name,
                style: Atelier.body(10, theme: t),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
/// Tile-style picker: 12 physical materials, Pro ones locked.
class _TileStyleGrid extends StatelessWidget {
  final TileThemeDef theme;
  final TileSettings settings;
  final TileAudio audio;
  final StoreService store;
  const _TileStyleGrid(
      {required this.theme,
      required this.settings,
      required this.audio,
      required this.store});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = settings;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: TileStyles.all.length,
      itemBuilder: (_, i) {
        final st = TileStyles.all[i];
        final locked = TileStyles.isPro(i) && !s.isPro;
        final selected = s.tileStyle == i;
        return GestureDetector(
          onTap: () {
            audio.click();
            if (locked) {
              // Locked style: take the user to PRO instead of doing nothing.
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProScreen(
                      audio: audio, settings: s, store: store),
                ),
              );
              return;
            }
            s.setTileStyle(i);
          },
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: st.face,
                      border: Border.all(
                        color: selected ? t.accentLight : st.edge,
                        width: selected ? 3 : 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x88000000),
                            offset: Offset(0, 3),
                            blurRadius: 6),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text('A',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: st.text)),
                  ),
                  if (locked)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock,
                            size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                locked ? '🔒 ${st.name}' : st.name,
                style: Atelier.body(10, theme: t),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CtrlChip extends StatelessWidget {
  final TileThemeDef theme;
  final String label;
  final VoidCallback onTap;
  const _CtrlChip(
      {required this.theme, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.3),
          border:
              Border.all(color: t.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label, style: Atelier.label(14, theme: t)),
      ),
    );
  }
}
