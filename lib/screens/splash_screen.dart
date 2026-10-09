import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan_letters.dart';
import '../theme/tile_themes.dart';
import 'menu_screen.dart';

/// Launch splash: company moment (WAJIHA logo) -> game splash
/// (logo + name + animated loading line + "Credits: WAJIHA").
class SplashScreen extends StatefulWidget {
  final TileAudio audio;
  final TileSettings settings;
  final StoreService store;
  const SplashScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _showCompany = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    unawaited(widget.audio.prewarm());
    unawaited(widget.audio.startMenuMusic());
    // Company moment.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showCompany = false);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    return Scaffold(
      backgroundColor: theme.woodDeep,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showCompany
            ? _CompanySplash(theme: theme)
            : _GameSplash(theme: theme, loader: _loader),
      ),
    );
  }
}

/// Company splash moment — the official WAJIHA logo, untouched.
class _CompanySplash extends StatelessWidget {
  final TileThemeDef theme;
  const _CompanySplash({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('company'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/wajiha_logo.png', width: 120, height: 120),
          const SizedBox(height: 18),
          Text('WAJIHA', style: Atelier.display(30, theme: theme)),
          const SizedBox(height: 4),
          Text('handcrafted games',
              style: Atelier.body(14, theme: theme,
                  color: theme.ivory.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final TileThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return WoodBackdrop(
      key: const ValueKey('game'),
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/anagrams_logo.webp', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Anagrams', style: Atelier.display(52, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'WOODEN LETTER TILES EDITION',
              style: Atelier.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                theme.accentLight,
                                theme.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Sanding the tiles…' : 'Ready!',
                      style: Atelier.body(13,
                          theme: theme,
                          color: theme.ivory.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Atelier.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
