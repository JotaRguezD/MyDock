// Dibuja el icono de MyDock y genera icon/AppIcon.icns (y icon/AppIcon.png para el README).
// Uso: swift icon/make-icon.swift   (desde la carpeta del proyecto)
import AppKit

let size: CGFloat = 1024
let dir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func gradient(_ ctx: CGContext, _ colors: [CGColor], from: CGPoint, to: CGPoint) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath { CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil) }

func draw(_ ctx: CGContext) {
    // Cuerpo con el margen y las esquinas de los iconos de macOS (824 px de 1024).
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: rgb(0x000000, 0.35))
    ctx.addPath(rounded(body, 185)); ctx.setFillColor(rgb(0x1E1B4B)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(rounded(body, 185)); ctx.clip()
    gradient(ctx, [rgb(0x6D5DF6), rgb(0x3B2FB8), rgb(0x1A1446)], from: CGPoint(x: 512, y: 924), to: CGPoint(x: 512, y: 100))
    // Brillo suave arriba, como de luz sobre el escritorio.
    let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                          colors: [rgb(0xFFFFFF, 0.28), rgb(0xFFFFFF, 0)] as CFArray, locations: nil)!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 860), startRadius: 0,
                           endCenter: CGPoint(x: 512, y: 860), endRadius: 520, options: [])

    // La barra del dock, de cristal, centrada en el icono.
    ctx.translateBy(x: 0, y: 172)
    let bar = CGRect(x: 160, y: 250, width: 704, height: 180)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: rgb(0x000000, 0.45))
    ctx.addPath(rounded(bar, 62)); ctx.setFillColor(rgb(0xFFFFFF, 0.16)); ctx.fillPath()
    ctx.restoreGState()
    ctx.addPath(rounded(bar.insetBy(dx: 2, dy: 2), 60)); ctx.setStrokeColor(rgb(0xFFFFFF, 0.38)); ctx.setLineWidth(4); ctx.strokePath()

    // Tres apps de colores, con el punto de «abierta» debajo de las dos primeras.
    let tiles: [(CGFloat, UInt32, UInt32)] = [(190, 0xFF7A59, 0xF43F5E), (322, 0x34D399, 0x0EA5E9), (454, 0xFDE047, 0xF59E0B)]
    for (x, top, bottom) in tiles {
        let r = CGRect(x: x, y: 292, width: 112, height: 112)
        ctx.saveGState()
        ctx.addPath(rounded(r, 28)); ctx.clip()
        gradient(ctx, [rgb(top), rgb(bottom)], from: CGPoint(x: r.midX, y: r.maxY), to: CGPoint(x: r.midX, y: r.minY))
        ctx.restoreGState()
    }
    ctx.setFillColor(rgb(0xFFFFFF, 0.9))
    for x: CGFloat in [246, 378] { ctx.fillEllipse(in: CGRect(x: x - 7, y: 266, width: 14, height: 14)) }

    // Separador y widget de reloj: lo que distingue a MyDock.
    ctx.addPath(rounded(CGRect(x: 592, y: 300, width: 6, height: 96), 3)); ctx.setFillColor(rgb(0xFFFFFF, 0.5)); ctx.fillPath()
    let widget = CGRect(x: 622, y: 292, width: 212, height: 112)
    ctx.addPath(rounded(widget, 30)); ctx.setFillColor(rgb(0xFFFFFF, 0.22)); ctx.fillPath()
    let face = CGRect(x: 640, y: 312, width: 72, height: 72)
    ctx.setStrokeColor(rgb(0xFFFFFF)); ctx.setLineWidth(8); ctx.strokeEllipse(in: face)
    ctx.setLineCap(.round); ctx.setLineWidth(8)
    ctx.move(to: CGPoint(x: face.midX, y: face.midY)); ctx.addLine(to: CGPoint(x: face.midX, y: face.midY + 22))
    ctx.move(to: CGPoint(x: face.midX, y: face.midY)); ctx.addLine(to: CGPoint(x: face.midX + 16, y: face.midY - 6))
    ctx.strokePath()
    ctx.setFillColor(rgb(0xFFFFFF, 0.95))
    ctx.addPath(rounded(CGRect(x: 730, y: 356, width: 84, height: 16), 8)); ctx.fillPath()
    ctx.setFillColor(rgb(0xFFFFFF, 0.55))
    ctx.addPath(rounded(CGRect(x: 730, y: 326, width: 58, height: 14), 7)); ctx.fillPath()
    ctx.restoreGState()
}

func render(_ px: Int) -> Data {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: CGFloat(px) / size, y: CGFloat(px) / size)
    ctx.interpolationQuality = .high
    draw(ctx)
    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

// Tamaños que pide macOS en un .icns.
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
try! render(512).write(to: dir.appendingPathComponent("AppIcon.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", dir.appendingPathComponent("AppIcon.icns").path]
try! iconutil.run()
iconutil.waitUntilExit()
precondition(iconutil.terminationStatus == 0, "iconutil falló")
print("Icono creado: icon/AppIcon.icns e icon/AppIcon.png")
