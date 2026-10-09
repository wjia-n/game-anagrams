import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/tile_themes.dart';

/// Persisted settings + stats for Anagrams. Survives app restarts.
///
/// Stores: audio toggles, player names (2 slots), theme/appearance choices
/// (incl. custom theme colors), mode/difficulty setup, Pro unlock state,
/// and lifetime stats.
class TileSettings extends ChangeNotifier {
  static const _kMusic = 'anagrams_music_on';
  static const _kSfx = 'anagrams_sfx_on';
  static const _kVolume = 'anagrams_volume';
  static const _kDifficulty = 'anagrams_difficulty'; // 0..3
  static const _kMode = 'anagrams_mode'; // 0 timed, 1 relaxed, 2 duel
  static const _kNames = 'anagrams_player_names'; // legacy unordered StringSet
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old key scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'anagrams_player_names_json';
  static const _kTheme = 'anagrams_theme_id';
  static const _kTileStyle = 'anagrams_tile_style';
  static const _kGames = 'anagrams_games_played';
  static const _kWordsSolved = 'anagrams_words_solved';
  static const _kBestTimed = 'anagrams_best_timed_'; // + difficulty idx
  static const _kBestRelaxed = 'anagrams_best_relaxed';
  static const _kReviewNudged = 'anagrams_review_nudged';
  static const _kIsPro = 'anagrams_is_pro';
  static const _kCustomPrefix = 'anagrams_custom_';

  static const defaultNames = ['Word Wizard', 'Letter Lion'];
  static const difficultyNames = ['Easy', 'Classic', 'Expert', 'Master'];
  static const difficultyLetters = ['4 letters', '5 letters', '6 letters', '7 letters'];
  static const modeNames = ['Timed Rush', 'Relaxed', 'Pass & Play Duel'];

  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int difficulty = 1;
  int mode = 0;
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int tileStyle = 0;
  int gamesPlayed = 0;
  int wordsSolved = 0;
  List<int> bestTimed = [0, 0, 0, 0]; // best score per difficulty
  int bestRelaxed = 0; // most words solved in a relaxed round
  bool reviewNudged = false;
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Oak.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'woodDark': 0xFF2E1D12,
    'woodMid': 0xFF4A2F1C,
    'woodDeep': 0xFF1A100A,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'ivory': 0xFFF5EFE0,
    'tray': 0xFF1E4D3B,
    'trayEdge': 0xFF3B2416,
    'tileFace': 0xFFE8D5A3,
    'tileEdge': 0xFFB89B5E,
    'tileText': 0xFF2E1D12,
    'pc0': 0xFFA31621,
    'pc1': 0xFF1D4E9E,
  };

  TileThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return TileThemeDef(
      id: 'custom',
      name: 'My Creation',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodDeep: c('woodDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ivory: c('ivory'),
      tray: c('tray'),
      trayEdge: c('trayEdge'),
      tileFace: c('tileFace'),
      tileEdge: c('tileEdge'),
      tileText: c('tileText'),
      playerColors: [c('pc0'), c('pc1')],
    );
  }

  TileThemeDef get theme =>
      TileThemes.byId(themeId, custom: customTheme);

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 3);
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 2);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    tileStyle = (p.getInt(_kTileStyle) ?? 0).clamp(0, TileStyles.all.length - 1);
    gamesPlayed = p.getInt(_kGames) ?? 0;
    wordsSolved = p.getInt(_kWordsSolved) ?? 0;
    bestTimed = [
      for (int i = 0; i < 4; i++) p.getInt('$_kBestTimed$i') ?? 0
    ];
    bestRelaxed = p.getInt(_kBestRelaxed) ?? 0;
    reviewNudged = p.getBool(_kReviewNudged) ?? false;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kMode, mode);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kTileStyle, tileStyle);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kWordsSolved, wordsSolved);
    for (int i = 0; i < 4; i++) {
      await p.setInt('$_kBestTimed$i', bestTimed[i]);
    }
    await p.setInt(_kBestRelaxed, bestRelaxed);
    await p.setBool(_kReviewNudged, reviewNudged);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || TileThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (TileStyles.isPro(tileStyle)) {
      tileStyle = 0;
      changed = true;
    }
    if (difficulty > 2) {
      difficulty = 2;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 3);
    if (!isPro && v > 2) return; // Master is Pro-only
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || TileThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTileStyle(int v) async {
    v = v.clamp(0, TileStyles.all.length - 1);
    if (!isPro && TileStyles.isPro(v)) return;
    tileStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> markReviewNudged() async {
    reviewNudged = true;
    await _save();
  }

  /// Record a finished round: [difficulty] tier, timed [score] (0 if not
  /// timed), total [solved] words, and whether the new records are bests.
  Future<void> recordGame(
      {required int difficulty,
      required int timedScore,
      required int solved}) async {
    gamesPlayed++;
    wordsSolved += solved;
    if (timedScore > 0) {
      final i = difficulty.clamp(0, 3);
      if (timedScore > bestTimed[i]) bestTimed[i] = timedScore;
    }
    if (solved > bestRelaxed) bestRelaxed = solved;
    notifyListeners();
    await _save();
  }
}
