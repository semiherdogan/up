import AppKit

// Usage: swift Scripts/make-icon.swift <output.iconset>

// All geometry is in units of a 1024 canvas, following the macOS icon grid.
let canvasSize: CGFloat = 1024
let plateRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let plateCornerRadius: CGFloat = 185
let arrowLineWidth: CGFloat = 96

func drawIcon() {
    let plate = NSBezierPath(roundedRect: plateRect, xRadius: plateCornerRadius, yRadius: plateCornerRadius)
    let top = NSColor(srgbRed: 1.00, green: 0.72, blue: 0.20, alpha: 1)
    let bottom = NSColor(srgbRed: 0.98, green: 0.42, blue: 0.10, alpha: 1)
    // -90 degrees runs the gradient from the top edge down.
    NSGradient(starting: top, ending: bottom)?.draw(in: plate, angle: -90)

    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 512, y: 330))
    arrow.line(to: NSPoint(x: 512, y: 690))
    arrow.move(to: NSPoint(x: 352, y: 530))
    arrow.line(to: NSPoint(x: 512, y: 690))
    arrow.line(to: NSPoint(x: 672, y: 530))
    arrow.lineWidth = arrowLineWidth
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    NSColor.white.setStroke()
    arrow.stroke()
}

func renderPNG(pixels: Int) -> Data? {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }
    // A point size different from the pixel size makes the context scale canvas units to pixels.
    bitmap.size = NSSize(width: canvasSize, height: canvasSize)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.iconset>\n".utf8))
    exit(1)
}
let iconset = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

// The point sizes and scales iconutil expects in an .iconset.
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 1 ? "" : "@\(scale)x"
        guard let png = renderPNG(pixels: points * scale) else {
            FileHandle.standardError.write(Data("could not render \(points)pt@\(scale)x\n".utf8))
            exit(1)
        }
        try png.write(to: iconset.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
    }
}
