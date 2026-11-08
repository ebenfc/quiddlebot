// Renders the app icon in its three iOS appearances, 1024x1024 each, and writes the
// asset catalog entry that ties them together:
//   AppIcon.png         default: felt-green table, cream tile (no alpha, an App Store rule)
//   AppIcon-Dark.png    dark appearance (iOS 18+): the same tile on a near-black table
//   AppIcon-Tinted.png  tinted appearance (iOS 18+): grayscale; iOS applies the user's tint
// Original artwork: one tilted letter tile with a gold bonus badge, the app's own "Card
// Table" tile. Not Quiddler's card art. Colors are the design system's tokens
// (scripts/make-colors.py).
// Usage: swift scripts/make-icon.swift QuiddleBot/Assets.xcassets/AppIcon.appiconset
import AppKit

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <AppIcon.appiconset>\n".utf8))
    exit(1)
}
let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let side = 1024
let S = CGFloat(side)

func rgb(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

struct Palette {
    var backgroundTop: NSColor
    var backgroundBottom: NSColor
    var tile: NSColor
    var letter: NSColor
    var badge: NSColor
    var badgeInk: NSColor
}

let light = Palette(backgroundTop: rgb(0x2A7A5C), backgroundBottom: rgb(0x154733),  // accent
                    tile: rgb(0xFBF3DC), letter: rgb(0x1F5E46),                      // tileFace, accent
                    badge: rgb(0xF2C14E), badgeInk: rgb(0x3A2600))                   // bonusFill, onBonus
let dark = Palette(backgroundTop: rgb(0x1B201D), backgroundBottom: rgb(0x0D110F),   // surface, canvas
                   tile: rgb(0xE4DAC0), letter: rgb(0x1F5E46),
                   badge: rgb(0xF2C14E), badgeInk: rgb(0x3A2600))
let tinted = Palette(backgroundTop: rgb(0x000000), backgroundBottom: rgb(0x000000),
                     tile: rgb(0xFFFFFF), letter: rgb(0x5A5A5A),
                     badge: rgb(0xB0B0B0), badgeInk: rgb(0x000000))

func render(_ p: Palette, to name: String) throws {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
                                     bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
                                     isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 32),
          let gc = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("could not create a bitmap context")
    }
    rep.size = NSSize(width: side, height: side)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext

    // The table.
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: [p.backgroundTop.cgColor, p.backgroundBottom.cgColor] as CFArray,
                              locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

    // The tile, tilted as if just laid down.
    ctx.saveGState()
    ctx.translateBy(x: S / 2, y: S / 2)
    ctx.rotate(by: -7 * .pi / 180)
    let tile = CGRect(x: -290, y: -330, width: 580, height: 660)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 64, cornerHeight: 64, transform: nil)
    ctx.setShadow(offset: CGSize(width: 0, height: -28), blur: 70,
                  color: NSColor.black.withAlphaComponent(0.45).cgColor)
    ctx.setFillColor(p.tile.cgColor)
    ctx.addPath(tilePath)
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // The letter, nudged up to leave room for the badge.
    let letter = NSAttributedString(string: "Q", attributes: [
        .font: NSFont.systemFont(ofSize: 470, weight: .black),
        .foregroundColor: p.letter,
    ])
    let letterSize = letter.size()
    letter.draw(at: CGPoint(x: -letterSize.width / 2, y: -letterSize.height / 2 + 50))

    // The bonus: a gold pill with dark ink, like the app's ValueBadge.
    let badgeText = NSAttributedString(string: "+10", attributes: [
        .font: NSFont.systemFont(ofSize: 96, weight: .heavy),
        .foregroundColor: p.badgeInk,
    ])
    let textSize = badgeText.size()
    let pill = CGRect(x: tile.maxX - textSize.width - 92, y: tile.minY + 34,
                      width: textSize.width + 56, height: textSize.height + 14)
    ctx.setFillColor(p.badge.cgColor)
    ctx.addPath(CGPath(roundedRect: pill, cornerWidth: pill.height / 2, cornerHeight: pill.height / 2,
                       transform: nil))
    ctx.fillPath()
    badgeText.draw(at: CGPoint(x: pill.midX - textSize.width / 2, y: pill.midY - textSize.height / 2))
    ctx.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode PNG")
    }
    let url = folder.appending(path: name)
    try png.write(to: url)
    print("wrote \(url.path) (\(png.count) bytes)")
}

try render(light, to: "AppIcon.png")
try render(dark, to: "AppIcon-Dark.png")
try render(tinted, to: "AppIcon-Tinted.png")

let contents = """
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "filename" : "AppIcon-Dark.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ],
      "filename" : "AppIcon-Tinted.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

"""
try contents.write(to: folder.appending(path: "Contents.json"), atomically: true, encoding: .utf8)
print("wrote \(folder.appending(path: "Contents.json").path)")
