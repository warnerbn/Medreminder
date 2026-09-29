// Draws the app icon and launch-screen logo.
//
//   swiftc -o /tmp/render-icons tools/render-icons.swift
//   /tmp/render-icons Medreminder/Medreminder/Assets.xcassets/AppIcon.appiconset
//   /tmp/render-icons Medreminder/Medreminder/Assets.xcassets/LaunchLogo.imageset launch
//
import AppKit

enum Variant { case light, dark, tinted }

func render(_ variant: Variant, to path: String, size: Int = 1024, background: Bool = true) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    // Draw in 1024-point icon coordinates at any output size.
    ctx.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let full = CGRect(x: 0, y: 0, width: 1024, height: 1024)

    // Background (iOS masks the corners itself).
    if background { switch variant {
    case .light:
        let g = NSGradient(starting: NSColor(red: 0.16, green: 0.72, blue: 0.70, alpha: 1),
                           ending: NSColor(red: 0.05, green: 0.45, blue: 0.55, alpha: 1))!
        g.draw(in: full, angle: -90)
    case .dark:
        NSColor(red: 0.07, green: 0.09, blue: 0.10, alpha: 1).setFill(); full.fill()
    case .tinted:
        NSColor.black.setFill(); full.fill()
    } }

    // Capsule pill, rotated 45 degrees.
    ctx.saveGState()
    ctx.translateBy(x: 512, y: 540)
    ctx.rotate(by: .pi / 4)
    let pillW: CGFloat = 640, pillH: CGFloat = 260
    let pill = CGRect(x: -pillW / 2, y: -pillH / 2, width: pillW, height: pillH)
    let pillPath = NSBezierPath(roundedRect: pill, xRadius: pillH / 2, yRadius: pillH / 2)

    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 36,
                  color: NSColor.black.withAlphaComponent(variant == .light ? 0.25 : 0.5).cgColor)
    let leftColor: NSColor, rightColor: NSColor
    switch variant {
    case .light:  leftColor = .white; rightColor = NSColor(red: 0.85, green: 0.97, blue: 0.95, alpha: 1)
    case .dark:   leftColor = NSColor(red: 0.20, green: 0.80, blue: 0.76, alpha: 1); rightColor = NSColor(red: 0.90, green: 0.96, blue: 0.95, alpha: 1)
    case .tinted: leftColor = .white; rightColor = NSColor(white: 0.55, alpha: 1)
    }
    rightColor.setFill(); pillPath.fill()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    NSGraphicsContext.current!.saveGraphicsState()
    NSBezierPath(rect: CGRect(x: -pillW / 2, y: -pillH / 2, width: pillW / 2, height: pillH)).addClip()
    leftColor.setFill(); pillPath.fill()
    NSGraphicsContext.current!.restoreGraphicsState()
    // Seam between halves.
    let seam = NSBezierPath(); seam.move(to: CGPoint(x: 0, y: -pillH / 2)); seam.line(to: CGPoint(x: 0, y: pillH / 2))
    seam.lineWidth = 10
    (variant == .light ? NSColor(red: 0.05, green: 0.45, blue: 0.55, alpha: 0.35) : NSColor.black.withAlphaComponent(0.35)).setStroke()
    ctx.saveGState(); pillPath.addClip(); seam.stroke(); ctx.restoreGState()
    ctx.restoreGState()

    // Check badge, lower right.
    let badge = CGRect(x: 640, y: 150, width: 250, height: 250)
    let badgeFill: NSColor = variant == .tinted ? NSColor(white: 0.85, alpha: 1)
        : NSColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 24, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    badgeFill.setFill(); NSBezierPath(ovalIn: badge).fill()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    let check = NSBezierPath()
    check.move(to: CGPoint(x: badge.minX + 62, y: badge.midY + 2))
    check.line(to: CGPoint(x: badge.minX + 108, y: badge.midY - 46))
    check.line(to: CGPoint(x: badge.maxX - 58, y: badge.midY + 52))
    check.lineWidth = 34; check.lineCapStyle = .round; check.lineJoinStyle = .round
    (variant == .tinted ? NSColor.black : NSColor.white).setStroke(); check.stroke()

    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let out = CommandLine.arguments[1]
if CommandLine.arguments.count > 2 && CommandLine.arguments[2] == "launch" {
    // Transparent logo for the launch screen: 240pt at 1x/2x/3x.
    for (scale, suffix) in [(1, ""), (2, "@2x"), (3, "@3x")] {
        render(.light, to: "\(out)/LaunchLogo\(suffix).png", size: 240 * scale, background: false)
        render(.dark, to: "\(out)/LaunchLogo-Dark\(suffix).png", size: 240 * scale, background: false)
    }
} else {
    render(.light, to: "\(out)/AppIcon.png")
    render(.dark, to: "\(out)/AppIcon-Dark.png")
    render(.tinted, to: "\(out)/AppIcon-Tinted.png")
}
