// cachering: draws cachewatch's menu-bar ring and prints it as a base64 PNG for SwiftBar.
// usage: cachering <fraction 0-1> <centre text> [orange]
// built by install.sh: swiftc -O src/cachering.swift -o ~/.local/bin/cachering
import AppKit

let args = CommandLine.arguments
let frac = min(max(Double(args[1]) ?? 0, 0), 1)
let text = args[2]
let ink: NSColor = args.count > 3 ? .systemOrange : .black  // black = template image, macOS tints it

let pt = 18.0
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 36, pixelsHigh: 36, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: pt, height: pt)  // 144 dpi, so it stays sharp on Retina
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let centre = NSPoint(x: pt / 2, y: pt / 2), radius = pt / 2 - 1.5
let track = NSBezierPath()
track.appendArc(withCenter: centre, radius: radius, startAngle: 0, endAngle: 360)
track.lineWidth = 2
ink.withAlphaComponent(0.3).setStroke()
track.stroke()

if frac > 0 {  // fills clockwise from 12 o'clock
  let arc = NSBezierPath()
  arc.appendArc(withCenter: centre, radius: radius, startAngle: 90, endAngle: 90 - 360 * frac, clockwise: true)
  arc.lineWidth = 2
  arc.lineCapStyle = .round
  ink.setStroke()
  arc.stroke()
}

let font = NSFont.monospacedDigitSystemFont(ofSize: text.count > 2 ? 7 : 9, weight: .bold)
let label = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: ink])
let size = label.size()
label.draw(at: NSPoint(x: centre.x - size.width / 2, y: centre.y - size.height / 2))

print(rep.representation(using: .png, properties: [:])!.base64EncodedString())
