import AppKit
import ApplicationServices

/// Hace que las ventanas maximizadas se paren en MyDock, como hace macOS con el Dock de Apple.
/// macOS no deja a otras apps reservar ese espacio, así que se ajustan con Accesibilidad (permiso aparte).
/// Las coordenadas de Accesibilidad tienen el origen arriba a la izquierda de la pantalla principal.
enum WindowFitter {
    static var trusted: Bool { AXIsProcessTrusted() }

    /// Muestra el aviso de macOS para dar el permiso de Accesibilidad.
    static func requestPermission() {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
    }

    static func openPrivacy() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    /// La ventana activa de la app que está delante (nunca MyDock).
    static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication, app.processIdentifier != getpid() else { return nil }
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(AXUIElementCreateApplication(app.processIdentifier),
                                            kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    static func isFullScreen(_ window: AXUIElement) -> Bool {
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &value)
        return (value as? Bool) == true
    }

    static func frame(_ window: AXUIElement) -> CGRect? {
        var position: CFTypeRef?, size: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &position) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size) == .success,
              let position, let size else { return nil }
        var origin = CGPoint.zero, extent = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &origin), AXValueGetValue(size as! AXValue, .cgSize, &extent) else { return nil }
        return CGRect(origin: origin, size: extent)
    }

    static func setFrame(_ window: AXUIElement, _ frame: CGRect) {
        var origin = frame.origin, extent = frame.size
        if let position = AXValueCreate(.cgPoint, &origin) { AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position) }
        if let size = AXValueCreate(.cgSize, &extent) { AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, size) }
    }
}

/// Nuevo marco para una ventana que llega al borde del dock y se mete debajo de la barra; nil si no hay que tocarla.
/// Todo en coordenadas de Accesibilidad (y hacia abajo): `area` es la zona útil de la pantalla y `dock`, la barra visible.
func fittedFrame(_ w: CGRect, dock d: CGRect, area: CGRect, _ position: DockPosition) -> CGRect? {
    var r = w
    switch position {
    case .bottom:
        guard w.maxY >= area.maxY - 2, w.minY < d.minY, w.maxX > d.minX, w.minX < d.maxX else { return nil }
        r.size.height = d.minY - w.minY
    case .left:
        guard w.minX <= area.minX + 2, w.maxX > d.maxX, w.maxY > d.minY, w.minY < d.maxY else { return nil }
        r.origin.x = d.maxX
        r.size.width = w.maxX - d.maxX
    case .right:
        guard w.maxX >= area.maxX - 2, w.minX < d.minX, w.maxY > d.minY, w.minY < d.maxY else { return nil }
        r.size.width = d.minX - w.minX
    }
    return r.width >= 100 && r.height >= 100 ? r : nil  // nunca dejarla diminuta
}
