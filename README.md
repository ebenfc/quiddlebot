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

## Layout
```
index.html                web app, served by GitHub Pages from the repo root
docs/rules.md             rules reference and house conventions
docs/privacy.md           privacy policy (served via GitHub Pages)
project.yml               XcodeGen spec; regenerates QuiddleBot.xcodeproj
QuiddleBot/
  Models/                 Game, Round, RuleSet, Scoring (pure), CardValues
  Store/GameStore.swift   @Observable state + JSON persistence
  Views/                  SwiftUI screens
QuiddleBotTests/          Swift Testing suite
scripts/make-icon.swift   renders the app icon PNG
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

## Trademark
Unofficial. Not affiliated with or endorsed by PlayMonster or Cannei, LLC.
QUIDDLER is a registered trademark of Cannei, LLC.
