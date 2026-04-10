#!/usr/bin/swift

import AppKit
import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 2 else {
    fputs("Usage: generate-app-icon.swift <output-png-path>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: arguments[1])
let canvasSize = CGSize(width: 1024, height: 1024)

let image = NSImage(size: canvasSize)
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
    fputs("Unable to create graphics context.\n", stderr)
    exit(1)
}

let rect = CGRect(origin: .zero, size: canvasSize)
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

// ─── Background ──────────────────────────────────────────
let panelRect = rect.insetBy(dx: 42, dy: 42)
let bgPath = NSBezierPath(roundedRect: panelRect, xRadius: 220, yRadius: 220)
context.saveGState()
bgPath.addClip()
context.setFillColor(color(14, 14, 22).cgColor)
context.fill(panelRect)
context.restoreGState()

color(255, 255, 255, 0.04).setStroke()
bgPath.lineWidth = 3
bgPath.stroke()

// ─── Gauge Arc — solid amber, 270° ──────────────────────
let gc = NSPoint(x: 512, y: 480)
let gr: CGFloat = 238
let gw: CGFloat = 40

// Glow layer (drawn slightly wider, blurred)
context.saveGState()
context.setShadow(offset: .zero, blur: 34, color: color(245, 158, 11, 0.50).cgColor)
let glowArc = NSBezierPath()
glowArc.appendArc(withCenter: gc, radius: gr, startAngle: 225, endAngle: -45, clockwise: true)
glowArc.lineWidth = gw
glowArc.lineCapStyle = .round
color(245, 158, 11).setStroke()
glowArc.stroke()
context.restoreGState()

// Crisp arc on top (no shadow, sharp)
let arc = NSBezierPath()
arc.appendArc(withCenter: gc, radius: gr, startAngle: 225, endAngle: -45, clockwise: true)
arc.lineWidth = gw
arc.lineCapStyle = .round
color(245, 158, 11).setStroke()
arc.stroke()

// ─── Tick Marks (major only, every 45°) ──────────────────
let tickBase = gr + gw / 2 + 10
for i in 0...6 {
    let t = CGFloat(i) / 6.0
    let deg: CGFloat = 225.0 - t * 270.0
    let rad: CGFloat = deg * .pi / 180
    let len: CGFloat = 16
    let p1 = NSPoint(x: gc.x + tickBase * cos(rad), y: gc.y + tickBase * sin(rad))
    let p2 = NSPoint(x: gc.x + (tickBase + len) * cos(rad), y: gc.y + (tickBase + len) * sin(rad))

    let tick = NSBezierPath()
    tick.move(to: p1)
    tick.line(to: p2)
    tick.lineWidth = 2.5
    tick.lineCapStyle = .round
    color(255, 255, 255, 0.18).setStroke()
    tick.stroke()
}

// ─── Needle (solid white, pointing to ~78%) ──────────────
let needleDeg: CGFloat = 225.0 - 0.78 * 270.0
let needleRad: CGFloat = needleDeg * .pi / 180
let needleLen: CGFloat = gr - 32
let needleTip = NSPoint(x: gc.x + needleLen * cos(needleRad), y: gc.y + needleLen * sin(needleRad))
let needleStart = NSPoint(x: gc.x + 16 * cos(needleRad), y: gc.y + 16 * sin(needleRad))

context.saveGState()
context.setShadow(offset: .zero, blur: 14, color: color(255, 255, 255, 0.35).cgColor)
let needle = NSBezierPath()
needle.move(to: needleStart)
needle.line(to: needleTip)
needle.lineWidth = 6
needle.lineCapStyle = .round
color(255, 255, 255, 0.92).setStroke()
needle.stroke()
context.restoreGState()

// Bright tip dot
context.saveGState()
context.setShadow(offset: .zero, blur: 10, color: color(255, 255, 255, 0.6).cgColor)
let tipR: CGFloat = 6
context.setFillColor(color(255, 255, 255).cgColor)
context.fillEllipse(in: CGRect(x: needleTip.x - tipR, y: needleTip.y - tipR, width: tipR * 2, height: tipR * 2))
context.restoreGState()

// ─── Center Pivot ────────────────────────────────────────
let pivR: CGFloat = 14
context.setFillColor(color(28, 26, 42).cgColor)
context.fillEllipse(in: CGRect(x: gc.x - pivR, y: gc.y - pivR, width: pivR * 2, height: pivR * 2))
let pivInner: CGFloat = 5
context.setFillColor(color(245, 158, 11).cgColor)
context.fillEllipse(in: CGRect(x: gc.x - pivInner, y: gc.y - pivInner, width: pivInner * 2, height: pivInner * 2))

// ─── Small ↓↑ arrows in the gauge gap ───────────────────
let arrowY = gc.y - gr + 55
let sz: CGFloat = 22
let gap: CGFloat = 20

// Download arrow (cool blue)
let dCx = gc.x - gap
context.saveGState()
context.setShadow(offset: .zero, blur: 6, color: color(100, 180, 255, 0.4).cgColor)
color(100, 180, 255, 0.65).setStroke()
let dS = NSBezierPath()
dS.move(to: NSPoint(x: dCx, y: arrowY + sz / 2))
dS.line(to: NSPoint(x: dCx, y: arrowY - sz / 2))
dS.lineWidth = 4; dS.lineCapStyle = .round; dS.stroke()
let dH = NSBezierPath()
dH.move(to: NSPoint(x: dCx - 8, y: arrowY - sz / 2 + 10))
dH.line(to: NSPoint(x: dCx, y: arrowY - sz / 2))
dH.line(to: NSPoint(x: dCx + 8, y: arrowY - sz / 2 + 10))
dH.lineWidth = 4; dH.lineCapStyle = .round; dH.lineJoinStyle = .round; dH.stroke()
context.restoreGState()

// Upload arrow (warm peach)
let uCx = gc.x + gap
context.saveGState()
context.setShadow(offset: .zero, blur: 6, color: color(255, 160, 100, 0.4).cgColor)
color(255, 160, 100, 0.65).setStroke()
let uS = NSBezierPath()
uS.move(to: NSPoint(x: uCx, y: arrowY - sz / 2))
uS.line(to: NSPoint(x: uCx, y: arrowY + sz / 2))
uS.lineWidth = 4; uS.lineCapStyle = .round; uS.stroke()
let uH = NSBezierPath()
uH.move(to: NSPoint(x: uCx - 8, y: arrowY + sz / 2 - 10))
uH.line(to: NSPoint(x: uCx, y: arrowY + sz / 2))
uH.line(to: NSPoint(x: uCx + 8, y: arrowY + sz / 2 - 10))
uH.lineWidth = 4; uH.lineCapStyle = .round; uH.lineJoinStyle = .round; uH.stroke()
context.restoreGState()

// ─── Finish ──────────────────────────────────────────────
image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to encode icon image.\n", stderr)
    exit(1)
}

do {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
    )
    try pngData.write(to: outputURL, options: .atomic)
} catch {
    fputs("Failed to write icon image: \(error)\n", stderr)
    exit(1)
}
