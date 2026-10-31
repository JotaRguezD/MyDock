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

    /// Ventanas normales de una app con su título; sin el permiso de Accesibilidad, ninguna.
    static func windows(of pid: pid_t) -> [(element: AXUIElement, title: String)] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(AXUIElementCreateApplication(pid), kAXWindowsAttribute as CFString, &value) == .success,
              let list = value as? [AXUIElement] else { return [] }
        return list.compactMap { window in
            var subrole: CFTypeRef?, title: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subrole)
            guard (subrole as? String) == kAXStandardWindowSubrole else { return nil }
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)
            return (window, title as? String ?? "")
        }
    }

    /// Trae al frente esa ventana (aunque esté minimizada) y su app.
    static func raise(_ window: AXUIElement, of app: NSRunningApplication) {
        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        NSApp.activate(ignoringOtherApps: true)  // ver openPath: una app de fondo no puede poner otra delante
        app.activate()
    }

    /// Primer grupo del menú Archivo de la app (suele ser «Nueva ventana», «Nuevo evento»…): se lee sin que se vea nada.
    /// Las opciones del menú del Dock de Apple solo se pueden leer abriéndolo, y se ve aunque esté escondido.
    static func fileActions(of pid: pid_t) -> [(title: String, element: AXUIElement)] {
        func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
            var value: CFTypeRef?
            AXUIElementCopyAttributeValue(element, name as CFString, &value)
            return value
        }
        func children(_ element: AXUIElement) -> [AXUIElement] { attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? [] }
        // 0 = menú Apple, 1 = el de la app, 2 = Archivo
        guard let bar = attribute(AXUIElementCreateApplication(pid), kAXMenuBarAttribute),
              CFGetTypeID(bar) == AXUIElementGetTypeID() else { return [] }
        let menus = children(bar as! AXUIElement)
        guard menus.count > 2, let file = children(menus[2]).first else { return [] }
        let items = children(file).map { (title: attribute($0, kAXTitleAttribute) as? String ?? "", element: $0) }
        return items.prefix { !$0.title.isEmpty }.filter {
            attribute($0.element, kAXEnabledAttribute) as? Bool == true && children($0.element).isEmpty
        }
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
    case .top:
        guard w.minY <= area.minY + 2, w.maxY > d.maxY, w.maxX > d.minX, w.minX < d.maxX else { return nil }
        r.origin.y = d.maxY
        r.size.height = w.maxY - d.maxY
    }
    return r.width >= 100 && r.height >= 100 ? r : nil  // nunca dejarla diminuta
}
