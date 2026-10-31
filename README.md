# QuiddleBot

An unofficial scorekeeper for the card game Quiddler. Native iOS, SwiftUI, free, no accounts,
no tracking.

**Status:** rewrite in progress (October 2026). The original single-file web version that
started this is [`index.html`](index.html), still live on GitHub Pages at
https://ebenfc.github.io/quiddlebot/.

## Why
Quiddler ships without a score pad, players miss the "no hand below zero" rule for years, and
a tied bonus surprises everyone. The web version replaced paper for a few friends. This is the
App Store version, and the owner's first trip through App Store Connect.

Since 1.1 the scorekeeper taps the cards of each word and the app adds up the hand. Since 1.2
each word gets a word-check mark: found in the built-in list, not in it (tap to look it up in
the iOS dictionary or record that the table accepted it), or accepted by the table. The mark is
a hint; the table's dictionary decides, and the mark never changes a score.

## Layout
```
index.html                web app, served by GitHub Pages from the repo root
docs/rules.md             rules reference and house conventions
docs/privacy.md           privacy policy (served via GitHub Pages)
project.yml               XcodeGen spec; regenerates QuiddleBot.xcodeproj
QuiddleBot/
  Models/                 Game, Round, RuleSet, Scoring (pure), CardValues, Hand, WordList
  Resources/words.txt     the built-in word list (generated; see scripts/build-wordlist.sh)
  Store/GameStore.swift   @Observable state + JSON persistence
  Views/                  SwiftUI screens
QuiddleBotTests/          Swift Testing suite
scripts/make-icon.swift   renders the app icon PNG
scripts/build-wordlist.sh builds words.txt from ENABLE1 + scripts/wordlist/additions.txt
scripts/wordlist/additions.txt   words newer than ENABLE1; edit, rebuild, commit
```

## Build
1. `brew install xcodegen`
2. `xcodegen generate`
3. `open QuiddleBot.xcodeproj`, pick an iPhone simulator, ⌘R. Tests: ⌘U.

## Scoring decisions
- A hand is floored at zero before a lost-challenge penalty is subtracted, so a lost
  challenge is the only way a hand goes negative (`Scoring.handTotal`).
- A blank score field blocks submission rather than counting as 0; a bonus the table
  isn't playing never blocks (`RoundDraft.isComplete`).

## Word list
The word check looks words up in `QuiddleBot/Resources/words.txt`: the public-domain ENABLE1
list (Enhanced North American Benchmark Lexicon, c. 2000) plus the hand-curated additions in
`scripts/wordlist/additions.txt`, lowercase, 2 to 15 letters. ENABLE1 is frozen, so newer
words (qi, za, ok, emoji) live in the additions file. To refresh the list: edit the additions,
download ENABLE1 (the script checks its sha256), run `scripts/build-wordlist.sh enable1.txt`,
and commit the regenerated `words.txt`. Definitions come from the dictionary built into iOS,
which Apple keeps current. ENABLE1 contains offensive words; the check only confirms a word
exists and filters nothing.

## Trademark
Unofficial. Not affiliated with or endorsed by PlayMonster or Cannei, LLC.
QUIDDLER is a registered trademark of Cannei, LLC.
