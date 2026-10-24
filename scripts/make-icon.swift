// Renders the app icon as a 1024x1024 PNG with no alpha channel (an App Store requirement).
// Original artwork: one tilted letter tile with a bonus badge. Not Quiddler's card art.
// Usage: swift scripts/make-icon.swift QuiddleBot/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import AppKit

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.png>\n".utf8))
    exit(1)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let side = 1024
let S = CGFloat(side)

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

// Background: the web app's navy-to-blue palette.
let navy = NSColor(srgbRed: 0.102, green: 0.102, blue: 0.180, alpha: 1)
let blue = NSColor(srgbRed: 0.059, green: 0.204, blue: 0.376, alpha: 1)
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [navy.cgColor, blue.cgColor] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

// Tile.
ctx.saveGState()
ctx.translateBy(x: S / 2, y: S / 2)
ctx.rotate(by: -7 * .pi / 180)
let tile = CGRect(x: -290, y: -330, width: 580, height: 660)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 64, cornerHeight: 64, transform: nil)
ctx.setShadow(offset: CGSize(width: 0, height: -28), blur: 70,
              color: NSColor.black.withAlphaComponent(0.5).cgColor)
ctx.setFillColor(NSColor(srgbRed: 0.98, green: 0.97, blue: 0.94, alpha: 1).cgColor)
ctx.addPath(tilePath)
ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)

// Letter, centred and nudged up to leave room for the badge.
let letter = NSAttributedString(string: "Q", attributes: [
    .font: NSFont.systemFont(ofSize: 470, weight: .black),
    .foregroundColor: navy,
])
let letterSize = letter.size()
letter.draw(at: CGPoint(x: -letterSize.width / 2, y: -letterSize.height / 2 + 40))

// Bonus badge in the tile's bottom-right corner.
let gold = NSColor(srgbRed: 1.0, green: 0.84, blue: 0.0, alpha: 1)
let badge = NSAttributedString(string: "+10", attributes: [
    .font: NSFont.systemFont(ofSize: 108, weight: .heavy),
    .foregroundColor: gold,
])
let badgeSize = badge.size()
badge.draw(at: CGPoint(x: tile.maxX - badgeSize.width - 44, y: tile.minY + 36))
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()
guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not encode PNG")
}
try png.write(to: output)
print("wrote \(output.path) (\(png.count) bytes)")
