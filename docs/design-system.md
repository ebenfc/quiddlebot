# Design system: clean iOS

QuiddleBot looks like a native iOS app and stays out of the way of the game: system fonts,
system grouped backgrounds, flat cards, gray letter tiles and a keypad that matches the system
keyboard. The only brand notes are the green accent and gold for bonuses. (It started as
"Card Table", with cream tiles, rounded type and soft shadows; that was dropped as too themed.)
The **QuiddleBot Design System** artifact on claude.ai still shows the old Card Table look.
This file holds the rules the code relies on.

## Where things live
- `QuiddleBot/DesignSystem/Tokens/`: `DS.Colors`, `DS.Typography` and `ScoreStyle`,
  `DS.Space`, `DS.Radius`, `DS.Size`, `DS.Avatar`, `DS.Motion`, `DS.Haptic`.
- `QuiddleBot/DesignSystem/Components/`: buttons and the bottom bar (with Liquid Glass on
  iOS 26), cards, headings, `ScoreNumeral`, `ValueBadge`, `BonusHeaderRow`, `PlayerAvatar`,
  `PlayerScoreRow`, `RankMedal`, `StatTile`, `SelectableChip`, `NoticeBanner`, `LetterTile`.
- `QuiddleBot/DesignSystem/Previews/DesignSystemCatalog.swift`: every token and component in
  one #Preview, in the artifact's order.
- Colors: brand colors (accent, bonus, status, seats, medals) come from the asset catalog;
  `scripts/make-colors.py` is the source. Surfaces, outlines and tiles use system colors
  (`systemGroupedBackground` and friends) in `DSColors.swift`, so their old colorsets
  (`DSCanvas`, `DSSurface`, `DSSurfaceSunken`, `DSOutline`, `DSTile*`) are unused.

## Rules
1. **Roles, not hues.** Code names `DS.Colors.bonusText`, never "gold". No color literals in views.
2. **Fill and ink are pairs.** A bright fill always carries its own ink (`accent`/`onAccent`,
   `bonusFill`/`onBonus`, `player(n)`/`onPlayer`). Gold *text* uses `bonusText`, a deeper
   shade. Every pair clears 4.5:1, and every color has Increase Contrast variants.
3. **Never color alone.** Status pairs a symbol with its tone; a picked chip shows a checkmark;
   the round being edited shows a pencil; clashing initials become two letters.
4. **Plain iOS first.** System font (no rounded design), flat cards with no shadow, gray
   letter tiles with their points in the corner, and a keypad that looks like the system
   keyboard (gray fills, plain letters, no outline, shadow or point numbers). Nothing that
   evokes Quiddler's card art (trademark: see the README).
5. **Glass is for chrome.** Buttons and the bottom bar get Liquid Glass on iOS 26; cards,
   tiles and keys stay solid. Everything still works on iOS 17.
6. **Motion goes through `DS.Motion`.** Movement becomes a fade under Reduce Motion
   (`motionSafeTransition`, `DS.Motion.movement`); confetti plays once, for a finish.
7. **Dynamic Type everywhere,** with caps only where a layout is fixed: keypad keys (plus the
   large content viewer), the round pills, the scorecard grid, the counter's total card.
8. **One spacing scale:** 2, 4, 8, 12, 16, 20, 24. Radii: tile 8, control 14, card 22.
