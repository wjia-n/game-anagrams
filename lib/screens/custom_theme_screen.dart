import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan_letters.dart';
import '../theme/tile_themes.dart';

/// Custom theme creator (Pro): pick every material color of your own
/// workshop. Live preview on real letter tiles.
class CustomThemeScreen extends StatelessWidget {
  final TileAudio audio;
  final TileSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  static const _swatches = [
    0xFF2E1D12,
    0xFF4A2F1C,
    0xFF1A100A,
    0xFF3B2416,
    0xFF5C3A21,
    0xFF241309,
    0xFFC9A227,
    0xFFE8CE7A,
    0xFF8A6D1A,
    0xFFF5EFE0,
    0xFF1E4D3B,
    0xFFE8D5A3,
    0xFFB89B5E,
    0xFFA31621,
    0xFF1D4E9E,
    0xFF2E6B4E,
    0xFF26314A,
    0xFFD9A441,
    0xFFC97A4A,
    0xFF101623,
    0xFFE4EBF8,
    0xFF8A6238,
    0xFFB45A3C,
    0xFF2B241C,
  ];

  static const _labels = {
    'woodDark': 'Background wood',
    'woodMid': 'Card wood',
    'woodDeep': 'Deep shadow',
    'accent': 'Trim metal',
    'accentLight': 'Trim highlight',
    'accentDark': 'Trim shadow',
    'ivory': 'Text',
    'tray': 'Letter tray',
    'trayEdge': 'Tray frame',
    'tileFace': 'Tile face',
    'tileEdge': 'Tile edge',
    'tileText': 'Tile letters',
    'pc0': 'Player 1 color',
    'pc1': 'Player 2 color',
  };

  TileThemeDef get _t => settings.theme;

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
          title: Text('Custom Theme', style: Atelier.display(22, theme: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                audio.click();
                s.resetCustomColors();
                s.setTheme('custom');
              },
              child: Text('Reset', style: Atelier.label(13, theme: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) {
              final preview = s.customTheme;
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live preview.
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [preview.woodMid, preview.woodDeep],
                          ),
                          border: Border.all(color: preview.accent, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final ch in ['A', 'N', 'A'])
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: LetterTile(
                                  letter: ch,
                                  size: 52,
                                  face: preview.tileFace,
                                  edge: preview.tileEdge,
                                  textColor: preview.tileText,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          audio.click();
                          s.setTheme('custom');
                        },
                        child: Text('Use this theme',
                            style: Atelier.label(14, theme: t)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final key in _labels.keys)
                      _ColorRow(
                        label: _labels[key]!,
                        current:
                            Color(s.customColors[key] ?? 0xFF000000),
                        onPick: (c) {
                          s.setCustomColor(key, c.value);
                          s.setTheme('custom');
                          audio.click();
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color current;
  final ValueChanged<Color> onPick;
  const _ColorRow(
      {required this.label, required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: current,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in CustomThemeScreen._swatches)
                GestureDetector(
                  onTap: () => onPick(Color(v)),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(v),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: current.value == v
                            ? Colors.white
                            : Colors.white24,
                        width: current.value == v ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
