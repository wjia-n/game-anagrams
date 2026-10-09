# Anagrams — Rules

The authoritative source of truth for the game. If the implementation
conflicts with this document, fix the implementation.

## 1. Objective

Unscramble the wooden letter tiles on your tray to build the hidden word
on the answer rack. Solve as many words as you can:

- **Timed Rush:** 90 seconds — maximize your score.
- **Relaxed:** no clock — solve 10 words at your own pace.
- **Pass & Play Duel:** 2 players take turns, 5 words each — highest
  score wins.

## 2. Setup

1. Pick a game mode: Timed Rush, Relaxed, or Pass & Play Duel.
2. Pick a difficulty tier: Easy (4 letters), Classic (5 letters),
   Expert (6 letters), Master (7 letters, Pro).
3. The engine picks a random word of the tier's length from the word bank
   and deals its letters onto the tray, shuffled so the solved word is
   never showing.
4. The 90-second clock (Timed Rush only) starts when the first word deals.

## 3. Turn order

- Solo modes: one turn per word; words keep coming until the round ends.
- Duel: Player 1 and Player 2 alternate one word at a time, 5 words each
  (10 turns total). The active player's strip is highlighted and the
  narration announces whose turn it is. Scores are never shared between
  players.

## 4. Legal moves

- Tap a tray tile to place it into the first empty rack slot.
- Tap a placed rack tile to return it to the tray.
- Tap Back to remove the most recently placed tile.
- Tap Shuffle to re-scramble only the tiles still on the tray.
- Tap Skip to abandon the current word (see §8).
- Pause at any time; the engine freezes timers and resumes cleanly.

## 5. Illegal moves

- Tapping a tray tile that is already placed: ignored.
- Tapping an empty rack slot: ignored.
- Any input while letters are dealing, a reveal animation is running, the
  game is paused, or the round is over: ignored.
- No interaction can place more letters than the word length, skip past
  the final word, or act for the wrong player in a duel.

## 6. Captures

Not applicable — there is no capturing in Anagrams.

## 7. Special rules

- The dealt scramble is guaranteed NOT to show the solved word.
- Shuffling never re-deals letters; only unused tray tiles move, and the
  result is never the solved word.
- Skipping reveals the hidden word with a letter-flip animation, then the
  next word deals.

## 8. Scoring

- Solved word: **+100 points + 25 per current streak step**.
  (1st solve: 100; 2nd in a row: 125; 3rd: 150; …)
- A wrong full guess or a skip **resets the streak to 0** (no points lost).
- Best streak per player is tracked and shown on the scoreboard.

## 9. Winning conditions

- **Timed Rush / Relaxed:** beat your personal best score (persisted per
  difficulty tier); a new best earns the "New best score!" headline.
- **Pass & Play Duel:** the player with the higher score after 10 turns
  wins and gets the 👑 crown. Equal scores are a tie.

## 10. Draw conditions

- Only possible in Duel: equal final scores produce the "It's a tie!"
  headline. Solo modes have no draws.

## 11. AI strategy

Not applicable — Anagrams is played by humans (solo or pass-and-play).
There are no bots.

## 12. Edge cases

- Word lists contain only words of exactly the tier length (validated at
  build time); a missing bucket falls back to the 6-letter list.
- If the random pick repeats the previous word, it is re-picked (up to 40
  tries).
- A forced app suspension mid-animation: the engine watchdog re-arms the
  lost phase timer within 3 seconds — the game never freezes.
- Pausing during a reveal resumes the exact same reveal continuation.
- Lifecycle pause uses audio pause()/resume(), so music continues where
  it stopped.
- Timer reaching zero mid-reveal: the round ends after the reveal; the
  solved word still counts (it finished before time ran out).
- Returning a tile during a wrong-guess flash is blocked until the
  letters bounce back to the tray.

## 13. Test cases

1. Start Timed Rush: first word deals staggered, clock ticks from 90.
2. Place all letters correctly: sequential green pulse, score += 100,
   streak becomes 1, next word deals.
3. Place a second correct word: score += 125, streak 2.
4. Full wrong guess: rack shakes red, streak resets, letters bounce back
   to the tray, no score change.
5. Skip: word flips in letter-by-letter, streak resets, next word deals.
6. Shuffle: only tray letters move; solved word never appears.
7. Let the clock hit 0: scoreboard appears with staggered cards,
   stats persist (games played, words solved, best score).
8. Relaxed: no clock; after 10 words the scoreboard appears.
9. Duel: players alternate, active strip highlighted, 10 turns, winner
   or tie headline correct.
10. Background the app mid-game: music pauses; on return the game
    resumes from the frozen phase with no stuck state.
11. Rename Player 1 / Player 2: names persist across app restarts in the
    exact order (JSON string, never a StringList).
12. Lock checks (free): Master tier, Pro themes, Pro tile styles, custom
    creator all refuse to apply without Pro.
