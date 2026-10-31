# /pmf: "Words with Friends for Quiddler" (remote, async multiplayer)

**Decision (2026-10-30, owner):** logged as research; no action on QuiddleBot.

Prior-art and product-market-fit check run 2026-10-29/30 with three web-research agents
(competitors, platform/IP, demand) plus a Gemini pass over Reddit. QuiddleBot stays an in-person
scorekeeper. Kept here so the question isn't researched twice; the validation step and kill
criteria below are what to run if the idea comes back.

**Verdict: Keep as personal, in one lane: 2-player async play over Game Center, as a separately named word-rummy app; QuiddleBot stays the scorekeeper.** Nothing anywhere does "your turn" Quiddler on a phone, but the closest things that exist, LetterMash (free, no account, live browser rooms, 2026 [1]) and Alpha Battle (2024, via Gemini [G6]), each drew 3 upvotes when launched on Reddit and no thread asks for remote play, so build it for your own table and expect no audience beyond it. The QUIDDLER mark covers "providing on-line computer games" [6], so the game cannot carry the name the scorekeeper trades on.

_Goal: share free, owner's own need first · Searched 2026-10-29/30, Reddit via Gemini 2026-10-30 · Coverage gaps: BoardGameGeek forums and USPTO returned 403 (trademark classes from aggregators); Google Play snippet only; Facebook groups unread; Reddit permalinks not fetched directly; two of three agents stalled overnight, findings recovered from partial transcripts and spot-checked_

| Feature | This idea | LetterMash [1] | tommy-games [2] | keywordsgame [3] | Word Wizard [4] | Letterpress [5] |
|---|---|---|---|---|---|---|
| 1. Async turns + push | ✓ | ✗ | ✗ | ✗ | ✗ | ✓ |
| 2. Full Quiddler engine | ✓ | ~ (Quiddler-inspired, 8 rounds) | ✓ | ~ (timed solo variant) | ✓ | ✗ |
| 3. Validation / challenge | ✓ | ? | ? | ~ | ✓ (dictionary) | ✓ (dictionary) |
| 4. Auto scoring + house rules | ✓ | ? | ~ | ~ | ~ (bonuses, no house rules) | ✗ |
| 5. 2–8 players, invites | 2 (3 max) | ~ (room code, live; bot-only in Mar 2026 via Gemini) | ~ (2–8, self-hosted server) | ✗ | ~ (game code) | ✗ (2 players) |
| 6. Live sync play | ✗ (dropped) | ✓ | ✓ | ✗ | ✓ | ✗ |
| 7. In-person scorekeeping | ✓ ships | ✗ | ✗ | ✗ | ✗ | ✗ |
| 8. Word calculator | ✓ ships | ✗ | ✗ | ✗ | ✗ | ✗ |

✓ has it · ~ partial · ✗ doesn't · ? couldn't verify. Word Wizard is a student project whose
deployment was to be removed after grading [4]. Four Tabletop Simulator mods (2014–2020, up
to 1,071 subscribers) have all been removed from Steam [8]. Nothing on Board Game Arena,
Tabletopia, Yucata, the App Store or (snippet only) Google Play. A shared-room web scorekeeper
also appeared in Aug 2026 [21]; it covers row 7 only.

**Where you're likely wrong**
- "An evolution of QuiddleBot." The scorekeeper's name is descriptive use ("Scorekeeper for Quiddler"). An online game *is* the Class 41 service Cannei registered [6]; every Tabletop Simulator Quiddler mod has been removed [8], Cannei has filed a GitHub DMCA before (over SET card art, 2016) [9], and Apple has forced renames at a rights-holder's request [10]. Put the game in a second app with its own name, original card art, and no "Quiddler" in name, subtitle or keywords. The mechanics and deck list are not protectable [11][12], which is how LetterMash operates.
- "Async works for any word game." Async Scrabble is about 25 turns a player. Quiddler runs 8 rounds that each continue until someone goes out, so roughly 40 turns a player (own estimate, unsourced), and each player waits on everyone else between turns. A 4-player game at Words-with-Friends pace runs for weeks; Gemini's case-against adds that rummy tension (watching discards, counting hoarded letters) decays across days [G]. Two players is the realistic lane; show the full discard history to offset the memory loss.
- "Nobody has built digital Quiddler." Three browser versions shipped in 2026 alone [1][2][22], plus Alpha Battle (2024, via Gemini [G6]), a student multiplayer build [4], a 2023 web port [24] and a 2022 one-day Python clone [23]. The empty slot is *async on phones*, not digital Quiddler.
- "The publisher left a gap." No official Quiddler app appears ever to have existed; PlayMonster's own SET apps are delisted [20] and setgame.com has served a 503 since at least July [19], which took the official daily Quiddler puzzle with it: one r/SetCardGame user "check[s] every week to see if it's back" (via Gemini [G16]). The audience is small: Quiddler's Wikipedia page gets ~700 views a month in 2026, about a quarter of Bananagrams and a thirtieth of Rummikub [15]; BGG rank #4267 with 4,003 ratings vs Bananagrams #2153 with 13,777 [16].

**Genuinely unique**
- Turns over days with a "your turn" push, on iPhone, with no server and no accounts, via Game Center turn-based matches [13]. Not found in any Quiddler-alike; the genre shows the pattern works (Letterpress [5]).
- The already-tested scorer and house-rule set (floor at zero, tie cancels the bonus, challenge penalties, two-player single bonus) as the engine's rules layer; every clone found hand-rolls scoring. The floor-at-zero ambiguity is a real, upvoted pain point on r/boardgames (via Gemini [G2]), which validates the scorekeeper more than the remote game.

**Risks**
- IP: Class 41 registration [6], TTS removals [8], prior DMCA [9], App Store 5.2.1 and 4.1(c) [10]. Mitigation is a different name and original art; the deck and rules are public [12].
- Platform: Game Center is Apple-only, so Android friends are out; turn pushes only fire in TestFlight/App Store builds, not debug runs [13b]; the match-data size limit is undocumented [13].
- Dictionary: ENABLE is public domain [14]. The official rules say "choose your dictionaries before the game begins" [12], so built-in validation removes the challenge mechanic. Pick one. Gemini found challenge-rule confusion in the wild (2014, via Gemini [G1]), which argues for validation.
- Demand (via Gemini, Reddit): no thread asks for remote or async Quiddler. LetterMash on r/wordgames (Mar 2026) and Alpha Battle on r/playmygame (Jun 2024) drew 3 upvotes each [G3][G6]. Rules-confusion threads (scoring floor 2024, 4 upvotes; challenges 2014) are real but validate the scorekeeper, not remote play [G2][G1]. Counter-signal: Quiddler is praised as the game played "instead of playing on our phones" [G11]. Expect your friends and nobody else.
- Maintenance: engine, dictionary, match state machine and hand/word UI is several times the scorekeeper's surface. "No accounts, no tracking" survives only because Game Center holds the identity.
- Strongest case against: "We already play over FaceTime with two decks, LetterMash is free in a browser tab, and you'd spend months on a game two people play that can't even say 'Quiddler' on the store."
- Can't honestly answer: whether Cannei/PlayMonster would object to a renamed clone. A renamed SET clone has 1.2K ratings and is untouched [17]; the Quiddler TTS mods were not.

**Cheap validation (≤1 week)**
- Step 1: play two full games with one distant friend on LetterMash [1] (free, no account, room code) over a call. Note whether the pain was scheduling a live session (async needed) or nothing (live play already solves it).
- Step 2: in your next two physical games, count turns per player per round, to size how long an async game would run.
- Step 3: one-day spike: a bare Game Center turn-based "pass a number" app on TestFlight; invite the same friend; time the invite.
- Kill if: fewer than 2 distant friends with iPhones say they'd play a weekly async game; or the LetterMash games went fine and nobody minded scheduling; or the turn count implies more than ~50 turns a player; or the Game Center invite takes a friend more than 10 minutes.

**Unverified / blocked**
- Alpha Battle: 2-player Quiddler-inspired mobile web game announced on r/playmygame, June 2024 (via Gemini [G6]; the post is confirmed by a search snippet); no live URL found, so not in the matrix.
- Reddit permalinks in Gemini's table: date-consistent but not fetched; 6 of 12 rows lack upvote counts.
- BGG forums including a thread titled "Saving Quiddler" (id 3215042), Facebook groups: no demand quotes could be read.
- Google Play: no Quiddler app seen in snippets; not verified.
- Steam Workshop removal reason: unstated (DMCA or other).
- USPTO TSDR and Justia returned 403; classes taken from trademarkregistration.app and Trademarkia.
- quiddler.org: registered 2026-05-02 via NameCheap, nothing answers on 80 or 443 [25]; not a competitor.
- LetterMash's exact deck and whether it has any async mode: Product Hunt listing only, the site is JS-rendered.

**Sources**
1. LetterMash — https://www.producthunt.com/products/lettermash (verified; launched 2026, free, no account, real-time 6-digit rooms, bots) and https://lettermash.net (title and meta only)
2. tommy-games — https://github.com/rileygramlich/tommy-games (verified; MIT, 0 stars, pushed 2026-10-12; online play needs a self-hosted WebSocket server, tables close after 10 idle minutes)
3. Keywords Game Quiddler page — https://keywordsgame.com/quiddler-game-online-made-easy/ (verified; single-player, timed, © 2025)
4. Quiddler Word Wizard — https://github.com/CALewis1955/quiddler-word-wizard (verified README; deployment at quiddler-frontend.onrender.com returned 503)
5. Letterpress — https://apps.apple.com/us/app/letterpress-word-game/id526619424 (verified)
6. QUIDDLER Reg. 3736896, Class 41 "providing on-line computer games", Cannei LLC, renewed 2019 — https://trademarkregistration.app/Trademark/Details/77765500 (verified, aggregator)
7. QUIDDLER Reg. 2350879, Class 28 "card games" — https://www.trademarkia.com/quiddler-75548253 (verified)
8. Tabletop Simulator mods removed — https://steamcommunity.com/sharedfiles/filedetails/?id=261966497 (2014, 1,071 subscribers) and ?id=2078849577 (2020) (verified)
9. GitHub DMCA, Set card art, 2016 — https://github.com/github/dmca/blob/master/2016/2016-05-25-Set.md (verified)
10. App Store Review Guidelines 5.2.1, 4.1(c), 4.2 — https://developer.apple.com/app-store/review/guidelines/ (verified); "Memory" renames — https://giga.law/daily-news/2012/11/14/apple-warns-app-developers-about-memory-name (verified)
11. US Copyright Office Circular 33 — https://www.copyright.gov/circs/circ33.pdf (verified)
12. Official rules PDF, © 2019 Cannei — https://www.playmonster.com/wp-content/uploads/2019/09/Quiddler_RULES.pdf (verified)
13. GKTurnBasedMatch — https://developer.apple.com/documentation/gamekit/gkturnbasedmatch (verified); 13b. turn notifications only in TestFlight/App Store builds — https://developer.apple.com/forums/thread/826543 (verified, anecdotal)
14. ENABLE word list, public domain — https://sources.debian.org/src/scowl/6-2/r/enable/README (verified)
15. Wikipedia pageviews, Quiddler vs Bananagrams vs Rummikub, 2024-01 to 2026-07 — https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/en.wikipedia/all-access/user/Quiddler/monthly/2024010100/2026100100 (verified)
16. BGG stats via mirror — https://boardgame-directory.vercel.app/games/339 (verified mirror; BGG itself 403)
17. SET: Card Game & Brain Puzzle (unofficial, 1.2K ratings, updated 2026-10-05) — https://apps.apple.com/us/app/set-card-game-brain-puzzle/id1506464825 (verified)
18. PlayMonster acquires Set Enterprises, 2019-04-30 — https://playmonster.com/?p=24092 (verified)
19. setgame.com 503 "Technical Difficulties", last-modified 2026-07-06 — https://www.setgame.com/quiddler (verified by curl 2026-10-30)
20. PlayMonster iOS apps delisted — https://itunes.apple.com/lookup?id=796785243,775474270&country=us (verified, 0 results)
21. Quiddler Scorekeeper, shared rooms, Aug 2026 — https://github.com/jparker2006/quiddler-scorekeeper (verified)
22. AutoQ, solo Quiddler variant, 2026 — https://github.com/sipnstrut/AutoQ (verified)
23. One-day Python clone, Dec 2022 — https://dev.to/megdiv/one-day-code-challenge-bmj (verified)
24. quiddler-online, 2023 — https://github.com/turtle11235/quiddler-online (verified, no licence, 0 stars)
25. quiddler.org RDAP: registered 2026-05-02, NameCheap; HTTPS refused (verified)
G. Gemini report "Market Viability and Feasibility Analysis: Asynchronous Digital Platform for Quiddler", Google Doc "Quiddler App Market Research", 2026-10-30 (owner's Drive). Reddit permalinks via Gemini, not fetched: G1 r/boardgames/comments/2f4vyt (challenge rule, 2014); G2 r/boardgames/comments/19conmg (scoring order of operations, 2024, 4 upvotes); G3 r/wordgames/comments/1sec6ah (LetterMash launch, Mar 2026, 3 upvotes); G6 r/playmygame/comments/1dc1b21 (Alpha Battle, Jun 2024, 3 upvotes; title confirmed by search snippet); G11 r/boardgames/comments/1oc0a0g (hidden gems, "instead of playing on our phones"); G16 r/SetCardGame/comments/1l51y28 (SET website broken, misses online Quiddler, 2025).

---

## The Gemini check (what came back, and what it changed)

Checked against `gemini-handoff.md`'s rules:
- **Permalinks:** 12 of 12 evidence rows carry one, plus 27 works cited. 10 are Reddit threads,
  which can't be fetched from here; their post IDs are consistent with the stated ages (e.g.
  `2f4vyt` ≈ 2014, `7sjfhz` ≈ 2018, `1dc1wch` ≈ mid-2024, `1sec6ah` ≈ early 2026). The two
  non-Reddit permalinks (Steam mod 261966497, keywordsgame.com) match pages the agents fetched.
  Upvote counts are missing on 6 of 12 rows, so "RECURRING/PRESENT" labels rest on Gemini's own
  denominators (n of 196 snippets).
- **Part A leaned on Part B** in its interpretation: Words With Friends scam threads are spun as
  "validating a no-accounts, free app", and rules questions as demand for "a digital engine".
  The raw quotes are usable; the spin is not.
- **Errors in the report** (discount these): it says the deck distribution and point values are
  "highly proprietary" and a rebranded engine invites a DMCA (mechanics aren't copyrightable
  [11]; the real issue is the Class 41 trademark, which Gemini missed [6]); it says async play
  needs a developer-run backend with "infinite, compounding server costs" (Game Center hosts
  turn-based matches and sends the pushes [13]); it says tommy-games has no Quiddler and is a
  pet-simulator studio (it confused an unrelated itch.io "Tommy Games" with the verified repo
  [2]); it calls LetterMash single-player only (its Mar 2026 Reddit post described bot matches;
  the newer Product Hunt listing lists private lobbies [1]).
- **What changed:** demand moved from "thin" to "thin, confirmed on Reddit": no thread asks for
  remote or async Quiddler, and the two nearest launches drew 3 upvotes each. One new
  near-equivalent surfaced (Alpha Battle, unverified). A new design risk surfaced: async
  Quiddler has far more turns than async Scrabble. The verdict moves from "Narrow to a lane" to
  "Keep as personal" in that same lane, and the lane narrows to 2 players.
