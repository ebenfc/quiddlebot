# Design system: Card Table

QuiddleBot's look is a card table: felt green, bonus gold, and plain cream letter tiles. The
full reference (tokens with contrast ratios, components with live previews, patterns) is the
**QuiddleBot Design System** artifact on claude.ai. This file holds the rules the code relies on.

## Where things live
- `QuiddleBot/DesignSystem/Tokens/`: `DS.Colors`, `DS.Typography` and `ScoreStyle`,
  `DS.Space`, `DS.Radius`, `DS.Size`, `DS.Avatar`, `DS.Motion`, `DS.Haptic`.
- `QuiddleBot/DesignSystem/Components/`: buttons and the bottom bar (with Liquid Glass on
  iOS 26), cards, headings, `ScoreNumeral`, `ValueBadge`, `BonusHeaderRow`, `PlayerAvatar`,
  `PlayerScoreRow`, `RankMedal`, `StatTile`, `SelectableChip`, `NoticeBanner`, `LetterTile`.
- `QuiddleBot/DesignSystem/Previews/DesignSystemCatalog.swift`: every token and component in
  one #Preview, in the artifact's order.
- Colors: `scripts/make-colors.py` is the source. Edit its table, run it, commit the colorsets.

## Rules
1. **Roles, not hues.** Code names `DS.Colors.bonusText`, never "gold". No color literals in views.
2. **Fill and ink are pairs.** A bright fill always carries its own ink (`accent`/`onAccent`,
   `bonusFill`/`onBonus`, `player(n)`/`onPlayer`). Gold *text* uses `bonusText`, a deeper
   shade. Every pair clears 4.5:1, and every color has Increase Contrast variants.
3. **Never color alone.** Status pairs a symbol with its tone; a picked chip shows a checkmark;
   the round being edited shows a pencil; clashing initials become two letters.
4. **Tiles are generic.** Flat cream, SF Rounded, a corner value. No frame, no ornament,
   never Quiddler's card art (trademark: see the README).
5. **Glass is for chrome.** Buttons and the bottom bar get Liquid Glass on iOS 26; cards,
   tiles and keys stay solid. Everything still works on iOS 17.
6. **Motion goes through `DS.Motion`.** Movement becomes a fade under Reduce Motion
   (`motionSafeTransition`, `DS.Motion.movement`); confetti plays once, for a finish.
7. **Dynamic Type everywhere,** with caps only where a layout is fixed: keypad keys (plus the
   large content viewer), the round pills, the scorecard grid, the counter's total card.
8. **One spacing scale:** 2, 4, 8, 12, 16, 20, 24. Radii: tile 8, control 14, card 22.
