#!/usr/bin/env python3
"""Writes the design-system colorsets into QuiddleBot/Assets.xcassets/DesignSystem.

One table, four appearances per color: light, dark, light + Increase Contrast,
dark + Increase Contrast. Edit the table, run `python3 scripts/make-colors.py`, commit.
The Design System artifact and DS.Colors (QuiddleBot/DesignSystem/Tokens/DSColors.swift)
mirror these names and values.
"""
import json, os, sys

#            name               light      dark       light HC   dark HC
COLORS = [
    ("DSAccent",        "#1F5E46", "#7FD1A8", "#154733", "#A6E3C4"),
    ("DSOnAccent",      "#FFFFFF", "#0F2A1F", "#FFFFFF", "#071A12"),
    ("DSBonusFill",     "#F2C14E", "#F2C14E", "#E8B12E", "#F7D27A"),
    ("DSOnBonus",       "#3A2600", "#3A2600", "#2A1B00", "#2A1B00"),
    ("DSBonusText",     "#8A5700", "#F2C14E", "#6E4500", "#F7D27A"),
    ("DSCanvas",        "#F6F1E4", "#0D110F", "#F6F1E4", "#000000"),
    ("DSSurface",       "#FFFFFF", "#1B201D", "#FFFFFF", "#1B201D"),
    ("DSSurfaceSunken", "#EDE6D3", "#272D29", "#E2D9C2", "#323A35"),
    ("DSOutline",       "#DCD2BC", "#3A413C", "#A89D84", "#6B746E"),
    ("DSTileFace",      "#FBF3DC", "#E4DAC0", "#FFF8E6", "#F0E7CF"),
    ("DSTileEdge",      "#D9C9A0", "#B9AC88", "#A8956A", "#8C7F5E"),
    ("DSTileInk",       "#1B1B1B", "#1B1B1B", "#000000", "#000000"),
    ("DSPositive",      "#2D6A2E", "#86D99A", "#1F5220", "#A9E8B8"),
    ("DSWarning",       "#9A3412", "#FDBA74", "#7C2A0E", "#FED7AA"),
    ("DSNegative",      "#B91C1C", "#FCA5A5", "#8F1515", "#FECACA"),
    ("DSPlayer1",       "#B3362B", "#F4A08F", "#952A20", "#F8BDB0"),
    ("DSPlayer2",       "#1F5FA8", "#8FB8F0", "#174C88", "#B0CDF5"),
    ("DSPlayer3",       "#7D3C98", "#D7A6E8", "#66307D", "#E4C2F0"),
    ("DSPlayer4",       "#0B6E7F", "#7CCFDB", "#085966", "#A3DEE7"),
    ("DSOnPlayer",      "#FFFFFF", "#14181A", "#FFFFFF", "#000000"),
    ("DSSilver",        "#C9CED6", "#C9CED6", "#B4BAC4", "#DDE1E7"),
    ("DSBronze",        "#D9A066", "#D9A066", "#C98B4E", "#E6B888"),
    # The global tint: same values as DSAccent, under the name Xcode looks for.
    ("AccentColor",     "#1F5E46", "#7FD1A8", "#154733", "#A6E3C4"),
]

def components(hex_):
    h = hex_.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return {"alpha": "1.000", "red": f"{r:.3f}", "green": f"{g:.3f}", "blue": f"{b:.3f}"}

def entry(hex_, appearances):
    e = {"color": {"color-space": "srgb", "components": components(hex_)}, "idiom": "universal"}
    if appearances:
        e["appearances"] = appearances
    return e

DARK = {"appearance": "luminosity", "value": "dark"}
HIGH = {"appearance": "contrast", "value": "high"}

def colorset(light, dark, light_hc, dark_hc):
    return {
        "colors": [
            entry(light, None),
            entry(dark, [DARK]),
            entry(light_hc, [HIGH]),
            entry(dark_hc, [DARK, HIGH]),
        ],
        "info": {"author": "xcode", "version": 1},
    }

def write(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)
        f.write("\n")

root = os.path.join(os.path.dirname(__file__), "..", "QuiddleBot", "Assets.xcassets")
folder = os.path.join(root, "DesignSystem")
write(os.path.join(folder, "Contents.json"), {"info": {"author": "xcode", "version": 1}})
for name, *values in COLORS:
    base = root if name == "AccentColor" else folder
    write(os.path.join(base, f"{name}.colorset", "Contents.json"), colorset(*values))
print(f"wrote {len(COLORS)} colorsets", file=sys.stderr)
