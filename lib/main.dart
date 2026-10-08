import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const AnagramsApp());

class AnagramsApp extends StatelessWidget {
  const AnagramsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.cozyPaper,
      title: 'Anagrams',
      tagline: 'Unscramble the chaos — 90 seconds of pure word wizardry!',
      emoji: '🔤',
      slug: 'anagrams',
      howToPlay:
          '• You get 90 seconds on the clock. GO! ⏱️\n• Tap letter tiles to build the 6-letter word.\n• Tap a placed letter to take it back. Shuffle when stuck! 🔀\n• +100 per word, plus a streak bonus that grows as you chain solves.\n• Wrong guess or skip resets your streak. No pressure! 😅',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => AnagramsScreen(players: players, callbacks: cb),
    );
  }
}
