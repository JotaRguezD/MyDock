import AppKit
import Combine
import SwiftUI

/// Panel flotante sin borde que no roba el foco a la app activa.
final class DockPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = DockStore()
    let running = RunningApps()
    var panel: DockPanel!
    private var positionChange: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = DockPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                          backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.contentView = DockHostingView(rootView: DockView(store: store, running: running))

        let nc = NotificationCenter.default
        nc.addObserver(forName: NSWindow.didResizeNotification, object: panel, queue: .main) { [weak self] _ in self?.place() }
        nc.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in self?.place() }

        termination.resume()
        store.applyAppleDock()
        panel.setContentSize(panel.contentView!.intrinsicContentSize)
        place()
        panel.orderFrontRegardless()

        // Cambiar de lado sin cambiar de tamaño (izquierda ↔ derecha) no dispara didResize.
        positionChange = store.$config.map(\.position).removeDuplicates().sink { [weak self] _ in
            DispatchQueue.main.async { self?.place() }  // $config avisa antes de guardar el valor nuevo
        }

        // Sin permisos extra: se mira dónde está el ratón 10 veces por segundo.
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.checkAutoHide() }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.keepPlaced()
            self?.fitWindows()
        }
    }

    /// macOS no avisa cuando cambia la zona libre de la pantalla (p. ej. al ocultarse o aparecer el Dock de Apple):
    /// si el dock no está donde le toca, se recoloca.
    func keepPlaced() {
        guard let screen = NSScreen.screens.first else { return }
        let target = dockFrame(panel.frame.size, screen: screen.frame, visible: usableArea(screen), store.position, hidden: hidden)
        if abs(target.minX - panel.frame.minX) > 1 || abs(target.minY - panel.frame.minY) > 1 { place(animated: true) }
    }

    /// La app de delante está a pantalla completa de verdad: MyDock se esconde, como el Dock de Apple.
    private var frontIsFullScreen = false
    /// Ventanas que no aceptan el tamaño (p. ej. por su tamaño mínimo): no se insiste con ellas.
    private var stubborn = Set<CFHashCode>()

    /// Para la ventana activa en el dock si llega a su borde («Ajustar ventanas al dock», con Accesibilidad).
    func fitWindows() {
        guard store.config.fitWindows == true, WindowFitter.trusted, let screen = NSScreen.screens.first,
              let window = WindowFitter.focusedWindow() else { frontIsFullScreen = false; return }
        frontIsFullScreen = WindowFitter.isFullScreen(window)
        // Con el dock oculto (o escondiéndose solo) la ventana puede ocupar toda la pantalla.
        guard !frontIsFullScreen, !hidden, store.config.autoHide != true, !stubborn.contains(CFHash(window)),
              let current = WindowFitter.frame(window) else { return }
        let top = screen.frame.maxY
        func ax(_ r: NSRect) -> CGRect { CGRect(x: r.minX, y: top - r.maxY, width: r.width, height: r.height) }
        let bar = ax(panel.frame.insetBy(dx: 12, dy: 12))  // sin el margen transparente de la sombra
        let area = ax(screen.visibleFrame)
        guard let target = fittedFrame(current, dock: bar, area: area, store.position) else { return }
        WindowFitter.setFrame(window, target)
        if let after = WindowFitter.frame(window), fittedFrame(after, dock: bar, area: area, store.position) != nil {
            stubborn.insert(CFHash(window))
        }
    }

    // Al salir (o cerrar sesión) vuelve el Dock de Apple: nunca te quedas sin dock.
    func applicationWillTerminate(_ notification: Notification) { store.restoreAppleDock() }

    /// La señal de cierre normal (kill, pkill) también cierra MyDock ordenadamente, para que devuelva el Dock de Apple.
    private lazy var termination: DispatchSourceSignal = {
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler { NSApp.terminate(nil) }
        return source
    }()

    private var hidden = false
    private var outsideSince: Date?

    func checkAutoHide() {
        guard let screen = NSScreen.screens.first else { return }
        let mouse = NSEvent.mouseLocation
        let atEdge = isAtEdge(mouse, of: screen.frame, store.position)
        let overDock = panel.frame.insetBy(dx: -8, dy: -8).contains(mouse)
        // Solo lo que sale del dock (popovers de grupos y widgets) o una alerta lo mantienen a la vista;
        // la ventana de Ajustes no, para poder ver el efecto de lo que se cambia.
        let busy = NSApp.modalWindow != nil || NSApp.windows.contains {
            $0.isVisible && String(describing: type(of: $0)).contains("Popover")
        }
        if !overDock && !atEdge && !busy {
            if outsideSince == nil { outsideSince = Date() }
        } else {
            outsideSince = nil
        }
        let hide = shouldHide(enabled: (store.config.autoHide ?? false) || frontIsFullScreen, atEdge: atEdge, overDock: overDock, busy: busy,
                              hidden: hidden, outsideFor: outsideSince.map { Date().timeIntervalSince($0) } ?? 0)
        if hide != hidden {
            hidden = hide
            place(animated: true)
        }
    }

    /// Zona libre de la pantalla. Con «Solo MyDock» el Dock de Apple está oculto: se usa toda la pantalla
    /// menos la barra de menús, aunque macOS siga reservando su hueco (a veces no lo libera tras reiniciarlo).
    func usableArea(_ screen: NSScreen) -> NSRect {
        guard store.config.hideAppleDock == true else { return screen.visibleFrame }
        var area = screen.frame
        area.size.height = screen.visibleFrame.maxY - screen.frame.minY
        return area
    }

    func place(animated: Bool = false) {
        // screens.first es la pantalla con la barra de menús; NSScreen.main cambia según la ventana activa.
        guard let screen = NSScreen.screens.first else { return }
        let frame = dockFrame(panel.frame.size, screen: screen.frame, visible: usableArea(screen),
                              store.position, hidden: hidden)
        // Oculto también se hace transparente: fuera de un borde puede haber otro monitor.
        panel.ignoresMouseEvents = hidden
        if animated {
            NSAnimationContext.runAnimationGroup {
                $0.duration = 0.2
                panel.animator().setFrame(frame, display: true)
                panel.animator().alphaValue = hidden ? 0 : 1
            }
        } else {
            panel.setFrame(frame, display: true)
            panel.alphaValue = hidden ? 0 : 1
        }
    }
}

/// Pegado al lado elegido y centrado en él, sin pisar el Dock de Apple (visibleFrame ya lo excluye);
/// oculto, justo fuera de la pantalla por ese lado.
func dockFrame(_ size: NSSize, screen: NSRect, visible: NSRect, _ position: DockPosition, hidden: Bool) -> NSRect {
    var origin: NSPoint
    switch position {
    case .bottom: origin = NSPoint(x: screen.midX - size.width / 2, y: hidden ? screen.minY - size.height : visible.minY)
    case .left: origin = NSPoint(x: hidden ? screen.minX - size.width : visible.minX, y: visible.midY - size.height / 2)
    case .right: origin = NSPoint(x: hidden ? screen.maxX : visible.maxX - size.width, y: visible.midY - size.height / 2)
    }
    return NSRect(origin: origin, size: size)
}

/// El ratón toca el borde de la pantalla del lado del dock (para que vuelva a salir).
func isAtEdge(_ mouse: NSPoint, of screen: NSRect, _ position: DockPosition) -> Bool {
    let inX = mouse.x >= screen.minX && mouse.x <= screen.maxX
    let inY = mouse.y >= screen.minY && mouse.y <= screen.maxY
    switch position {
    case .bottom: return inX && mouse.y <= screen.minY + 2
    case .left: return inY && mouse.x <= screen.minX + 2
    case .right: return inY && mouse.x >= screen.maxX - 3  // el ratón llega como mucho a maxX - 1
    }
}

if CommandLine.arguments.contains("--selftest") {
    selfTest()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
