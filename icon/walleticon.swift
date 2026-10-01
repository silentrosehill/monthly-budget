import Cocoa
import CoreImage

let S: CGFloat = 1024
let cs = CGColorSpace(name: CGColorSpace.displayP3)!
func ctx() -> CGContext {
    CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}
func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(colorSpace: cs, components: [r, g, b, a])! }
func rr(_ rect: CGRect, _ r: CGFloat) -> CGPath { NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r).cgPath }
func grad(_ cols: [CGColor], _ locs: [CGFloat]) -> CGGradient { CGGradient(colorsSpace: cs, colors: cols as CFArray, locations: locs)! }
func blob(_ g: CGContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ col: CGColor) {
    g.drawRadialGradient(grad([col, col.copy(alpha: 0)!], [0, 1]), startCenter: CGPoint(x: x, y: y), startRadius: 0,
                         endCenter: CGPoint(x: x, y: y), endRadius: r, options: [])
}
let ciCtx = CIContext(options: [.workingColorSpace: cs])

let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let iconPath = rr(iconRect, 186)

// ---------- background: liquid glass ----------
let bg = ctx()
bg.addPath(iconPath); bg.clip()
bg.drawLinearGradient(grad([c(0.05, 0.30, 0.30), c(0.07, 0.52, 0.46), c(0.60, 0.90, 0.78)], [0, 0.5, 1]),
                      start: CGPoint(x: 220, y: 100), end: CGPoint(x: 800, y: 940), options: [])
blob(bg, 800, 280, 360, c(0.22, 0.45, 0.95, 0.70))
blob(bg, 240, 800, 340, c(0.78, 1.00, 0.60, 0.55))
blob(bg, 270, 260, 280, c(0.00, 0.85, 0.75, 0.50))
blob(bg, 780, 840, 240, c(1.00, 0.86, 0.50, 0.45))
let bgImage = bg.makeImage()!
let blurImage: CGImage = {
    let ci = CIImage(cgImage: bgImage)
    let b = ci.clampedToExtent().applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 34])
        .applyingFilter("CIColorControls", parameters: ["inputSaturation": 1.4, "inputBrightness": 0.08]).cropped(to: ci.extent)
    return ciCtx.createCGImage(b, from: ci.extent)!
}()
// leather grain
let grain: CGImage = {
    let noise = CIFilter(name: "CIRandomGenerator")!.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: S, height: S))
        .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.2])
        .applyingFilter("CIColorControls", parameters: ["inputSaturation": 0, "inputContrast": 2.2])
        .cropped(to: CGRect(x: 0, y: 0, width: S, height: S))
    return ciCtx.createCGImage(noise, from: CGRect(x: 0, y: 0, width: S, height: S))!
}()

let g = ctx()
g.saveGState()
g.setShadow(offset: CGSize(width: 0, height: -14), blur: 34, color: c(0, 0, 0, 0.35))
g.addPath(iconPath); g.setFillColor(c(0, 0, 0, 1)); g.fillPath()
g.restoreGState()
g.draw(bgImage, in: CGRect(x: 0, y: 0, width: S, height: S))
g.saveGState()
g.addPath(iconPath); g.clip()

// ---------- wallet geometry ----------
let body = CGRect(x: 182, y: 236, width: 660, height: 420)
let bodyPath = rr(body, 74)

// banknote peeking out (behind)
g.saveGState()
g.translateBy(x: 560, y: 690); g.rotate(by: 0.09)
let note = CGRect(x: -250, y: -110, width: 500, height: 220)
g.setShadow(offset: CGSize(width: 0, height: -6), blur: 14, color: c(0, 0.1, 0.05, 0.35))
g.addPath(rr(note, 14)); g.setFillColor(c(0.62, 0.80, 0.62)); g.fillPath()
g.setShadow(offset: .zero, blur: 0, color: nil)
g.addPath(rr(note, 14)); g.clip()
g.drawLinearGradient(grad([c(0.78, 0.90, 0.74), c(0.55, 0.76, 0.58)], [0, 1]), start: CGPoint(x: 0, y: 110), end: CGPoint(x: 0, y: -110), options: [])
for k in stride(from: -260, through: 260, by: 9) {   // guilloche-like fine lines
    g.move(to: CGPoint(x: CGFloat(k), y: -110)); g.addLine(to: CGPoint(x: CGFloat(k) + 60, y: 110))
}
g.setStrokeColor(c(0.25, 0.48, 0.32, 0.18)); g.setLineWidth(1.5); g.strokePath()
g.addEllipse(in: CGRect(x: 70, y: -20, width: 120, height: 120)); g.setStrokeColor(c(0.2, 0.42, 0.28, 0.35)); g.setLineWidth(4); g.strokePath()
g.addPath(rr(note.insetBy(dx: 12, dy: 12), 8)); g.setStrokeColor(c(0.2, 0.42, 0.28, 0.35)); g.setLineWidth(3); g.strokePath()
g.restoreGState()

// glass card peeking out (behind, in front of the note)
g.saveGState()
g.translateBy(x: 440, y: 700); g.rotate(by: -0.10)
let card = CGRect(x: -230, y: -130, width: 460, height: 260)
let cardPath = rr(card, 34)
g.setShadow(offset: CGSize(width: 0, height: -8), blur: 20, color: c(0, 0.12, 0.1, 0.35))
g.addPath(cardPath); g.setFillColor(c(1, 1, 1, 0.2)); g.fillPath()
g.setShadow(offset: .zero, blur: 0, color: nil)
g.saveGState()
g.addPath(cardPath); g.clip()
g.rotate(by: 0.10); g.translateBy(x: -440, y: -700)
g.draw(blurImage, in: CGRect(x: -40, y: -40, width: S + 80, height: S + 80))
g.restoreGState()
g.saveGState()
g.addPath(cardPath); g.clip()
g.drawLinearGradient(grad([c(1, 1, 1, 0.55), c(1, 1, 1, 0.12), c(1, 1, 1, 0.30)], [0, 0.55, 1]), start: CGPoint(x: -230, y: 130), end: CGPoint(x: 230, y: -130), options: [])
g.addPath(rr(CGRect(x: -170, y: 20, width: 80, height: 60), 12)); g.setFillColor(c(1, 0.9, 0.6, 0.55)); g.fillPath()   // chip
g.addPath(rr(CGRect(x: -170, y: 20, width: 80, height: 60), 12)); g.setStrokeColor(c(1, 1, 1, 0.7)); g.setLineWidth(2); g.strokePath()
g.restoreGState()
g.addPath(rr(card.insetBy(dx: 3, dy: 3), 31)); g.setStrokeColor(c(1, 1, 1, 0.85)); g.setLineWidth(5); g.strokePath()
g.restoreGState()

// ---------- leather body ----------
g.saveGState()
g.setShadow(offset: CGSize(width: 0, height: -22), blur: 40, color: c(0, 0.08, 0.05, 0.55))
g.addPath(bodyPath); g.setFillColor(c(0.36, 0.19, 0.08)); g.fillPath()
g.restoreGState()
g.saveGState()
g.addPath(bodyPath); g.clip()
g.drawLinearGradient(grad([c(0.70, 0.42, 0.22), c(0.54, 0.30, 0.14), c(0.36, 0.19, 0.08)], [0, 0.55, 1]),
                     start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])
g.setBlendMode(.overlay); g.setAlpha(0.32); g.draw(grain, in: CGRect(x: 0, y: 0, width: S, height: S)); g.setAlpha(1); g.setBlendMode(.normal)
// pocket opening at top: darker lip + highlight
g.addRect(CGRect(x: body.minX, y: body.maxY - 26, width: body.width, height: 26))
g.setFillColor(c(0.15, 0.06, 0.01, 0.5)); g.fillPath()
g.drawLinearGradient(grad([c(1, 1, 1, 0.18), c(1, 1, 1, 0)], [0, 1]), start: CGPoint(x: 0, y: body.maxY - 26), end: CGPoint(x: 0, y: body.maxY - 110), options: [])
blob(g, body.minX + 170, body.maxY - 120, 260, c(1, 1, 1, 0.10))
g.restoreGState()
// stitching
func stitch(_ path: CGPath) {
    g.saveGState()
    g.addPath(path); g.setLineDash(phase: 0, lengths: [20, 13]); g.setLineCap(.round); g.setLineWidth(6)
    g.setStrokeColor(c(0.12, 0.05, 0.0, 0.6)); g.translateBy(x: 0, y: -2.5); g.strokePath()
    g.restoreGState()
    g.saveGState()
    g.addPath(path); g.setLineDash(phase: 0, lengths: [20, 13]); g.setLineCap(.round); g.setLineWidth(5)
    g.setStrokeColor(c(0.98, 0.90, 0.72, 0.95)); g.strokePath()
    g.restoreGState()
}
stitch(rr(body.insetBy(dx: 24, dy: 24), 52))
// edge highlight
g.addPath(rr(body.insetBy(dx: 2, dy: 2), 72)); g.setStrokeColor(c(1, 1, 1, 0.16)); g.setLineWidth(4); g.strokePath()

// ---------- strap with glass snap ----------
let strap = CGRect(x: 560, y: 360, width: 330, height: 170)
let strapPath = rr(strap, 85)
g.saveGState()
g.setShadow(offset: CGSize(width: -4, height: -14), blur: 22, color: c(0, 0.05, 0.03, 0.6))
g.addPath(strapPath); g.setFillColor(c(0.32, 0.17, 0.07)); g.fillPath()
g.restoreGState()
g.saveGState()
g.addPath(strapPath); g.clip()
g.drawLinearGradient(grad([c(0.66, 0.39, 0.20), c(0.48, 0.26, 0.11), c(0.32, 0.17, 0.07)], [0, 0.6, 1]),
                     start: CGPoint(x: 0, y: strap.maxY), end: CGPoint(x: 0, y: strap.minY), options: [])
g.setBlendMode(.overlay); g.setAlpha(0.32); g.draw(grain, in: CGRect(x: 0, y: 0, width: S, height: S)); g.setAlpha(1); g.setBlendMode(.normal)
g.restoreGState()
stitch(rr(strap.insetBy(dx: 20, dy: 20), 65))

// snap: glossy liquid glass bead
let snapC = CGPoint(x: strap.maxX - 88, y: strap.midY)
let snapR: CGFloat = 60
let snap = CGRect(x: snapC.x - snapR, y: snapC.y - snapR, width: snapR * 2, height: snapR * 2)
g.saveGState()
g.setShadow(offset: CGSize(width: 0, height: -8), blur: 14, color: c(0, 0.05, 0.03, 0.6))
g.addEllipse(in: snap); g.setFillColor(c(0.5, 0.8, 0.7, 0.9)); g.fillPath()
g.restoreGState()
g.saveGState()
g.addEllipse(in: snap); g.clip()
g.draw(blurImage, in: CGRect(x: -80, y: -80, width: S + 160, height: S + 160))
g.drawRadialGradient(grad([c(1, 1, 1, 0.85), c(0.75, 0.97, 0.88, 0.35), c(0.1, 0.4, 0.3, 0.45)], [0, 0.45, 1]),
                     startCenter: CGPoint(x: snapC.x - 18, y: snapC.y + 20), startRadius: 0, endCenter: snapC, endRadius: snapR, options: [])
// caustic crescent bottom-right
let cres = CGMutablePath(); cres.addEllipse(in: snap.insetBy(dx: 4, dy: 4)); cres.addEllipse(in: snap.insetBy(dx: 14, dy: 14).offsetBy(dx: -8, dy: 8))
g.addPath(cres); g.setFillColor(c(0.85, 1, 0.95, 0.5)); g.fillPath(using: .evenOdd)
g.restoreGState()
g.addEllipse(in: snap.insetBy(dx: 2, dy: 2)); g.setStrokeColor(c(1, 1, 1, 0.9)); g.setLineWidth(4); g.strokePath()
// € engraved on the snap
let attr = NSAttributedString(string: "€", attributes: [.font: NSFont.systemFont(ofSize: 66, weight: .heavy), .foregroundColor: NSColor.white])
let line = CTLineCreateWithAttributedString(attr)
let b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
g.saveGState()
g.setShadow(offset: CGSize(width: 0, height: -2), blur: 4, color: c(0, 0.25, 0.2, 0.7))
g.textPosition = CGPoint(x: snapC.x - b.midX, y: snapC.y - b.midY)
g.setFillColor(c(1, 1, 1, 0.95))
CTLineDraw(line, g)
g.restoreGState()
// specular dot
g.saveGState()
g.translateBy(x: snapC.x - 18, y: snapC.y + 30); g.rotate(by: 0.5); g.scaleBy(x: 1.0, y: 0.45)
blob(g, 0, 0, 34, c(1, 1, 1, 0.9))
g.restoreGState()

g.restoreGState()   // end icon clip

// ---------- icon-level glass sheen + rim ----------
g.saveGState()
g.addPath(iconPath); g.clip()
g.drawLinearGradient(grad([c(1, 1, 1, 0.20), c(1, 1, 1, 0)], [0, 1]), start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 700), options: [])
g.restoreGState()
g.saveGState()
g.addPath(rr(iconRect.insetBy(dx: 2, dy: 2), 184)); g.setLineWidth(4); g.replacePathWithStrokedPath(); g.clip()
g.drawLinearGradient(grad([c(1, 1, 1, 0.75), c(1, 1, 1, 0.08), c(1, 1, 1, 0.35)], [0, 0.5, 1]), start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100), options: [])
g.restoreGState()

let rep = NSBitmapImageRep(cgImage: g.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
