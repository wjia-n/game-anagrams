import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';
import 'theme/artisan_letters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = TileSettings();
  await settings.load();
  final audio = TileAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  final store = StoreService();
  unawaited(store.init());
  runApp(AnagramsApp(settings: settings, audio: audio, store: store));
}

class AnagramsApp extends StatefulWidget {
  final TileSettings settings;
  final TileAudio audio;
  final StoreService store;
  const AnagramsApp(
      {super.key,
      required this.settings,
      required this.audio,
      required this.store});

  @override
  State<AnagramsApp> createState() => _AnagramsAppState();
}

class _AnagramsAppState extends State<AnagramsApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Anagrams',
        debugShowCheckedModeBanner: false,
        theme: Atelier.theme(widget.settings.theme),
        home: SplashScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }
}
