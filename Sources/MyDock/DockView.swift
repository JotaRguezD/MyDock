import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DockView: View {
    @ObservedObject var store: DockStore
    @ObservedObject var running: RunningApps
    @StateObject private var login = LoginItem()

    var body: some View {
        let size = store.iconSize
        let layout = store.vertical ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        let z = zones(store.config.items)
        let open = running.unpinned(store.config.items)
        // Separador automático entre bloques, salvo que ya haya uno tuyo en ese borde.
        let appsEnd = open.isEmpty ? z.apps.last?.kind : .file
        let widgetsNeedSeparator = appsEnd != nil && appsEnd != .separator && z.widgets.first.map { $0.kind != .separator } == true
        layout {
            ForEach(z.apps) { dockItem($0, size: size) }
            if !open.isEmpty {
                if let last = z.apps.last, last.kind != .separator { separatorLine(size) }
                ForEach(open, id: \.processIdentifier) { app in
                    let path = app.bundleURL!.path
                    AppIconView(path: path, size: size, running: true, edge: store.position)
                        .rightClickMenu(edge: store.position) {
                            appMenu(path, running: running, options: [.item(t("Mantener en el dock")) { store.addFile(path) }])
                        }
                }
            }
            if widgetsNeedSeparator { separatorLine(size) }
            ForEach(z.widgets) { dockItem($0, size: size) }
            // La Papelera, siempre al final, como en el Dock de Apple.
            if store.config.showTrash != false {
                if !store.config.items.isEmpty || !open.isEmpty { separatorLine(size) }
                TrashView(size: size, edge: store.position)
            }
        }
        .onPreferenceChange(ItemFrames.self) { store.frames = $0 }
        // En idiomas de derecha a izquierda (árabe) macOS invertiría la fila: el orden del dock se fija
        // para que la Papelera quede siempre al final, a la derecha. Los textos siguen en su sentido.
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, store.vertical ? 8 : 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(minWidth: store.vertical ? size + 12 : 120, minHeight: store.vertical ? 120 : size + 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        // Encima de todo, pero cede el clic a los iconos y widgets, que tienen el suyo (ver Area.hitTest).
        .overlay(RightClickArea(edge: store.position, atMouse: true, make: backgroundMenu))
        .padding(12)  // margen para la sombra y el zoom al pasar el ratón
    }

    private func dockItem(_ item: DockItem, size: CGFloat) -> some View {
        itemView(item, size: size)
            .background(GeometryReader { g in
                Color.clear.preference(key: ItemFrames.self, value: [item.id: g.frame(in: .global)])
            })
            // Los drops los recibe DockHostingView (AppKit); el onDrop de SwiftUI no llega en este panel.
            .onDrag {
                let provider = NSItemProvider()
                provider.registerObject(item.id.uuidString as NSString, visibility: .ownProcess)
                return provider
            }
    }

    @ViewBuilder
    private func itemView(_ item: DockItem, size: CGFloat) -> some View {
        switch item.kind {
        case .file:
            let path = item.path ?? ""
            AppIconView(path: path, size: size, running: running.isRunning(path), edge: store.position)
                .rightClickMenu(edge: store.position) {
                    let groups = store.groups.map { g in MenuEntry.item(g.name ?? t("Grupo")) { store.moveIntoGroup(item.id, g.id) } }
                    return appMenu(path, running: running, options: [
                        .item(t("Mostrar en Finder")) { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)]) },
                    ] + (groups.isEmpty ? [] : [.submenu(t("Mover a grupo"), groups)]) + [
                        .divider,
                        .item(t("Quitar del dock")) { store.remove(item.id) },
                    ])
                }
        case .separator:
            separatorLine(size)
                .contentShape(Rectangle())
                .rightClickMenu(edge: store.position) { nsMenu([.item(t("Quitar separador")) { store.remove(item.id) }]) }
                .accessibilityHidden(true)
        case .spacer:
            Color.clear.frame(width: store.vertical ? size : size / 2, height: store.vertical ? size / 2 : size)
                .contentShape(Rectangle())
                .rightClickMenu(edge: store.position) { nsMenu([.item(t("Quitar espacio")) { store.remove(item.id) }]) }
                .accessibilityHidden(true)
        case .group:
            GroupItemView(item: item, store: store, running: running, size: size)
                .rightClickMenu(edge: store.position) {
                    nsMenu([.item(t("Renombrar…")) { ask(t("Nombre del grupo"), item.name ?? "") { store.rename(item.id, $0) } },
                            .divider, .item(t("Quitar grupo")) { store.remove(item.id) }])
                }
        case .widget:
            WidgetView(item: item, store: store, size: size)
                .rightClickMenu(edge: store.position) {
                    let compact = item.settings?.compact == true
                    var entries: [MenuEntry] = []
                    if item.widget == .weather {
                        let s = item.settings ?? WidgetSettings()
                        let cities = (s.cities ?? []).map { city in
                            MenuEntry.checked(city, s.selectedCity == city) { store.updateSettings(item.id) { $0.selectedCity = city } }
                        }
                        entries.append(.submenu(t("Ciudad"), [.checked(t("Ubicación actual"), s.selectedCity == nil) {
                            store.updateSettings(item.id) { $0.selectedCity = nil }
                        }] + cities + [.divider, .item(t("Gestionar ciudades…")) { SettingsWindow.shared.show(store, select: item.id) }]))
                    }
                    entries += [
                        .item(t("Ajustes del widget…")) { SettingsWindow.shared.show(store, select: item.id) },
                        .item(compact ? t("Versión amplia") : t("Versión compacta")) { store.updateSettings(item.id) { $0.compact = !compact } },
                        .divider,
                        .item(t("Quitar widget")) { store.remove(item.id) },
                    ]
                    return nsMenu(entries)
                }
        }
    }

    private func separatorLine(_ size: CGFloat) -> some View {
        Capsule().fill(.primary.opacity(0.3))
            .frame(width: store.vertical ? size * 0.8 : 1.5, height: store.vertical ? 1.5 : size * 0.8)
            .padding(store.vertical ? .vertical : .horizontal, 4)
            .frame(width: store.vertical ? size : nil, height: store.vertical ? nil : size)
            .accessibilityHidden(true)
    }

    private func backgroundMenu() -> NSMenu {
        let autoHide = store.config.autoHide ?? false, appleHidden = store.config.hideAppleDock ?? false
        let positions: [(String, DockPosition)] = [(t("Arriba"), .top), (t("Izquierda"), .left), (t("Abajo"), .bottom), (t("Derecha"), .right)]
        return nsMenu([
            .item(t("Añadir separador")) { store.append(DockItem(kind: .separator)) },
            .item(t("Añadir espacio")) { store.append(DockItem(kind: .spacer)) },
            .item(t("Nuevo grupo…")) { ask(t("Nombre del grupo"), "") { store.append(DockItem(kind: .group, name: $0, apps: [])) } },
            .submenu(t("Añadir widget"), WidgetKind.allCases.map { kind in
                .symbol(kind.title, kind.symbol, store.hasWidget(kind) ? nil : { store.addWidget(kind) })
            }),
            .submenu(t("Posición"), positions.map { title, position in
                .checked(title, store.position == position) { store.config.position = position }
            }),
            .submenu(t("Tamaño"), [
                .item(t("Pequeño")) { store.config.iconSize = 36 },
                .item(t("Mediano")) { store.config.iconSize = 48 },
                .item(t("Grande")) { store.config.iconSize = 64 },
            ]),
            .checked(t("Ocultar automáticamente"), autoHide) { store.config.autoHide = !autoHide },
            .checked(t("Abrir al iniciar sesión"), login.enabled) {
                let on = !login.enabled
                DispatchQueue.main.async { login.set(on) }  // fuera del menú: puede mostrar una alerta
            },
            .submenu(t("Dock a usar"), [
                .checked(t("Solo MyDock"), appleHidden) { store.setHideAppleDock(true) },
                .checked(t("MyDock y el de Apple"), !appleHidden) { store.setHideAppleDock(false) },
                .divider,
                .item(t("Solo el de Apple (cierra MyDock)")) {
                    store.setHideAppleDock(false)
                    DispatchQueue.main.async {
                        if login.enabled { login.set(false) }  // si no, MyDock volvería al iniciar sesión
                        NSApp.terminate(nil)
                    }
                },
            ]),
            .divider,
            .item(t("Ajustes…")) { SettingsWindow.shared.show(store) },
            .divider,
            .item(t("Salir de MyDock")) { NSApp.terminate(nil) },
        ])
    }
}

/// Opción de un menú de AppKit; sin acción sale en gris.
enum MenuEntry {
    case item(String, (() -> Void)?)
    case checked(String, Bool, () -> Void)
    case symbol(String, String, (() -> Void)?)  // con icono de SF Symbols
    case submenu(String, [MenuEntry])
    case divider
}

func nsMenu(_ entries: [MenuEntry]) -> NSMenu {
    let menu = NSMenu()
    for entry in entries {
        switch entry {
        case let .item(title, run): menu.addItem(ClosureMenuItem(title, run))
        case let .symbol(title, symbol, run):
            let item = ClosureMenuItem(title, run)
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            menu.addItem(item)
        case let .checked(title, on, run):
            let item = ClosureMenuItem(title, run)
            item.state = on ? .on : .off
            menu.addItem(item)
        case let .submenu(title, children):
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.submenu = nsMenu(children)
            menu.addItem(item)
        case .divider: menu.addItem(.separator())
        }
    }
    return menu
}

final class ClosureMenuItem: NSMenuItem {
    private let run: (() -> Void)?
    init(_ title: String, _ run: (() -> Void)?) {
        self.run = run
        super.init(title: title, action: run == nil ? nil : #selector(fire), keyEquivalent: "")
        target = self
    }
    required init(coder: NSCoder) { fatalError("init(coder:) no se usa") }
    @objc private func fire() { run?() }
}

/// Menú de una app. Abierta: sus ventanas, lo primero de su menú Archivo, nuestras opciones en «Opciones», Ocultar
/// y Salir (sin el permiso de Accesibilidad, sin ventanas ni Archivo). Cerrada: solo nuestras opciones.
/// Nunca se toca el Dock de Apple: cada dock enseña su propio menú.
func appMenu(_ path: String, running: RunningApps, options: [MenuEntry]) -> NSMenu {
    guard let app = running.app(path) else {
        return nsMenu(options + (path.hasSuffix(".app") ? [.divider, .item(t("Salir"), nil)] : []))
    }
    let windows = WindowFitter.windows(of: app.processIdentifier).map { w in
        MenuEntry.item(w.title.isEmpty ? displayName(path) : w.title) { WindowFitter.raise(w.element, of: app) }
    }
    let actions = WindowFitter.fileActions(of: app.processIdentifier).map { a in
        MenuEntry.item(a.title) { app.activate(); AXUIElementPerformAction(a.element, kAXPressAction as CFString) }
    }
    var entries = windows + (windows.isEmpty ? [] : [.divider])
    entries += actions + (actions.isEmpty ? [] : [.divider])
    entries += [.submenu(t("Opciones"), options), .divider,
                .item(app.isHidden ? t("Mostrar") : t("Ocultar")) { _ = app.isHidden ? app.unhide() : app.hide() }]
    if let quittable = running.quittable(path) {  // Finder no: macOS lo mantiene siempre abierto
        entries += [.item(t("Salir")) { quittable.terminate() }, .item(t("Forzar salida")) { quittable.forceTerminate() }]
    }
    return nsMenu(entries)
}

extension View {
    /// Clic derecho con un menú de AppKit montado en ese momento: el de una app depende de cómo esté ahora.
    /// Con `edge`, el menú sale junto al dock (como el del Dock de Apple) y no tapa los iconos; sin él, en el ratón.
    func rightClickMenu(edge: DockPosition? = nil, _ make: @escaping () -> NSMenu) -> some View {
        overlay(RightClickArea(edge: edge, atMouse: false, make: make))
            .accessibilityAction(.showMenu) { make().popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil) }
    }
}

struct RightClickArea: NSViewRepresentable {
    let edge: DockPosition?
    var atMouse: Bool  // la flecha apunta al ratón (el fondo del dock) y no al centro de la vista
    let make: () -> NSMenu

    func makeNSView(context: Context) -> Area { Area() }
    func updateNSView(_ view: Area, context: Context) { view.edge = edge; view.atMouse = atMouse; view.make = make }

    final class Area: NSView {
        var edge: DockPosition?
        var atMouse = false
        var make: (() -> NSMenu)?

        // Solo se queda el clic derecho (o con Control); lo demás sigue llegando a SwiftUI: abrir, arrastrar, pasar el ratón.
        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent else { return nil }
            let right = event.type == .rightMouseDown || (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
            guard right, let hit = super.hitTest(point) else { return nil }
            // El del fondo del dock: si debajo hay un icono o widget con su propio menú, se lo deja a él.
            if atMouse, let root = window?.contentView, Self.areas(in: root).contains(where: {
                $0 !== self && $0.convert($0.bounds, to: nil).contains(event.locationInWindow)
            }) { return nil }
            return hit
        }

        private static func areas(in view: NSView) -> [Area] {
            view.subviews.flatMap { ($0 as? Area).map { [$0] } ?? areas(in: $0) }
        }

        override func rightMouseDown(with event: NSEvent) {
            guard let menu = make?(), let window else { return }
            if let edge {
                let icon = atMouse ? NSRect(origin: NSEvent.mouseLocation, size: .zero) : window.convertToScreen(convert(bounds, to: nil))
                let dock = window.frame.insetBy(dx: 12, dy: 12)
                let origin = menuOrigin(menu.size, edge, icon: icon, dock: dock)
                let arrow = MenuArrow(edge, icon: icon, menu: NSRect(x: origin.x, y: origin.y - menu.size.height,
                                                                     width: menu.size.width, height: menu.size.height))
                arrow.orderFront(nil)
                menu.popUp(positioning: nil, at: origin, in: nil)
                arrow.orderOut(nil)
            } else {
                NSMenu.popUpContextMenu(menu, with: event, for: self)
            }
            // El clic que cierra el menú se lo queda el menú (macOS no lo reparte): si se hizo sobre el dock
            // y el botón sigue pulsado, se repite ahí, para abrir otra app o su menú sin un segundo clic.
            let mouse = NSEvent.mouseLocation, buttons = NSEvent.pressedMouseButtons
            guard window.frame.contains(mouse), buttons & 0b11 != 0 else { return }
            let right = buttons & 0b10 != 0
            if let again = NSEvent.mouseEvent(with: right ? .rightMouseDown : .leftMouseDown,
                                              location: window.convertPoint(fromScreen: mouse), modifierFlags: [],
                                              timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                                              context: nil, eventNumber: 0, clickCount: 1, pressure: 1) {
                DispatchQueue.main.async { NSApp.sendEvent(again) }  // tras salir de este clic, no anidado en él
            }
        }

        override func mouseDown(with event: NSEvent) { rightMouseDown(with: event) }  // Control-clic
    }
}

/// Flecha del menú hacia el icono, como en el Dock de Apple (un NSMenu no la tiene): una ventanita con la misma
/// textura que el menú, pegada a su borde, mientras está abierto.
final class MenuArrow: NSPanel {
    static let size: CGFloat = 9

    init(_ edge: DockPosition, icon: NSRect, menu: NSRect) {
        let s = Self.size, w = s * 2
        let frame: NSRect
        switch edge {
        case .bottom: frame = NSRect(x: icon.midX - s, y: menu.minY - s, width: w, height: s)
        case .top: frame = NSRect(x: icon.midX - s, y: menu.maxY, width: w, height: s)
        case .left: frame = NSRect(x: menu.minX - s, y: icon.midY - s, width: s, height: w)
        case .right: frame = NSRect(x: menu.maxX, y: icon.midY - s, width: s, height: w)
        }
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .popUpMenu
        ignoresMouseEvents = true
        let triangle = NSImage(size: frame.size, flipped: false) { r in
            let path = NSBezierPath()
            switch edge {  // la punta, hacia el icono
            case .bottom: path.move(to: NSPoint(x: r.minX, y: r.maxY)); path.line(to: NSPoint(x: r.midX, y: r.minY)); path.line(to: NSPoint(x: r.maxX, y: r.maxY))
            case .top: path.move(to: NSPoint(x: r.minX, y: r.minY)); path.line(to: NSPoint(x: r.midX, y: r.maxY)); path.line(to: NSPoint(x: r.maxX, y: r.minY))
            case .left: path.move(to: NSPoint(x: r.maxX, y: r.minY)); path.line(to: NSPoint(x: r.minX, y: r.midY)); path.line(to: NSPoint(x: r.maxX, y: r.maxY))
            case .right: path.move(to: NSPoint(x: r.minX, y: r.minY)); path.line(to: NSPoint(x: r.maxX, y: r.midY)); path.line(to: NSPoint(x: r.minX, y: r.maxY))
            }
            path.close()
            NSColor.black.setFill()
            path.fill()
            return true
        }
        let material = NSVisualEffectView()
        material.material = .menu
        material.state = .active
        material.maskImage = triangle
        contentView = material
    }
}

/// Esquina superior izquierda del menú (en pantalla) para que salga fuera del dock, centrado en el icono,
/// con sitio para la flecha.
func menuOrigin(_ menu: NSSize, _ edge: DockPosition, icon: NSRect, dock: NSRect) -> NSPoint {
    let gap = MenuArrow.size + 2
    switch edge {
    case .bottom: return NSPoint(x: icon.midX - menu.width / 2, y: dock.maxY + gap + menu.height)
    case .top: return NSPoint(x: icon.midX - menu.width / 2, y: dock.minY - gap)
    case .left: return NSPoint(x: dock.maxX + gap, y: icon.midY + menu.height / 2)
    case .right: return NSPoint(x: dock.minX - gap - menu.width, y: icon.midY + menu.height / 2)
    }
}

struct AppIconView: View {
    let path: String
    let size: CGFloat
    let running: Bool
    var edge: DockPosition = .bottom
    /// Tras el clic, cuando ya se ha visto el salto (p. ej. cerrar el popover del grupo).
    var onOpen: (() -> Void)? = nil
    /// Para iconos que no son un archivo (la Papelera): imagen, nombre, estado y qué hace el clic.
    var image: NSImage? = nil
    var label: String? = nil
    var value: String? = nil
    var action: (() -> Void)? = nil
    @State private var hover = false
    @State private var launching = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Rebota hacia el interior de la pantalla, como el Dock de Apple al abrir una app.
        let jump = launching && !reduceMotion ? size * 0.3 : 0
        let shift = [.bottom: CGSize(width: 0, height: -jump), .left: CGSize(width: jump, height: 0),
                     .right: CGSize(width: -jump, height: 0), .top: CGSize(width: 0, height: jump)][edge]!
        VStack(spacing: 2) {
            Image(nsImage: image ?? NSWorkspace.shared.icon(forFile: path))
                .resizable()
                .frame(width: size, height: size)
                .scaleEffect(hover ? 1.12 : 1, anchor: [.left: .leading, .right: .trailing, .top: .top][edge] ?? .bottom)  // crece desde el borde del dock
                .animation(.easeOut(duration: 0.12), value: hover)
                .offset(shift)
                .opacity(launching && reduceMotion ? 0.5 : 1)  // con «Reducir movimiento», solo se atenúa
                .animation(launching ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true) : .easeOut(duration: 0.2),
                           value: launching)
            Circle().fill(.primary.opacity(running ? 0.75 : 0)).frame(width: 4, height: 4)
        }
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .onTapGesture(perform: open)
        .onChange(of: running) { _, now in if now { launching = false } }  // ya ha arrancado: deja de rebotar
        .help(label ?? displayName(path))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? displayName(path))
        .accessibilityValue(value ?? (running ? t("Abierta") : ""))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open() }
    }

    private func open() {
        guard !launching else { return }
        if let action { action() } else { openPath(path) }
        launching = true
        // Ya abierta (o no es una app): un solo salto. Si no, rebota hasta que arranque, 4 s como mucho.
        let alreadyOpen = running || !path.hasSuffix(".app")
        DispatchQueue.main.asyncAfter(deadline: .now() + (alreadyOpen ? 0.3 : 4)) { launching = false }
        if let onOpen { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: onOpen) }
    }
}

struct GroupItemView: View {
    let item: DockItem
    @ObservedObject var store: DockStore
    @ObservedObject var running: RunningApps
    let size: CGFloat
    @State private var open = false

    var body: some View {
        let apps = item.apps ?? []
        let mini = size * 0.36
        VStack(spacing: 2) {
            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                ForEach(0..<2, id: \.self) { row in
                    GridRow {
                        ForEach(0..<2, id: \.self) { col in
                            let i = row * 2 + col
                            if i < apps.count {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: apps[i])).resizable().frame(width: mini, height: mini)
                            } else {
                                Color.clear.frame(width: mini, height: mini)
                            }
                        }
                    }
                }
            }
            .frame(width: size, height: size)
            .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: size * 0.22))
            Circle().fill(.clear).frame(width: 4, height: 4)
        }
        .contentShape(Rectangle())
        .help(item.name ?? t("Grupo"))
        .onTapGesture { open.toggle() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.name ?? t("Grupo"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open.toggle() }
        .popover(isPresented: $open, arrowEdge: store.popoverEdge) {
            VStack(alignment: .leading, spacing: 10) {
                Text(item.name ?? t("Grupo")).font(.headline)
                if apps.isEmpty {
                    Text(t("Arrastra apps encima del grupo\no usa «Mover a grupo» en una app."))
                        .font(.callout).foregroundStyle(.secondary)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(72)), count: min(4, apps.count)), spacing: 12) {
                        ForEach(apps, id: \.self) { path in
                            VStack(spacing: 4) {
                                AppIconView(path: path, size: 48, running: running.isRunning(path)) { open = false }
                                Text(displayName(path)).font(.caption).lineLimit(1)
                            }
                            .onTapGesture { open = false; openPath(path) }
                            .rightClickMenu {
                                appMenu(path, running: running, options: [
                                    .item(t("Sacar al dock")) { store.takeOut(item.id, path) },
                                    .item(t("Quitar del grupo")) { store.removeFromGroup(item.id, path) },
                                ])
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }
}

/// Pide un texto con una alerta. Se lanza fuera del menú contextual para que este se cierre antes.
func ask(_ title: String, _ value: String, _ done: @escaping (String) -> Void) {
    DispatchQueue.main.async {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.addButton(withTitle: t("Aceptar"))
        alert.addButton(withTitle: t("Cancelar"))
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.stringValue = value
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty { done(text) }
    }
}

/// Posición de cada elemento en la ventana, para saber dónde cae un drop.
struct ItemFrames: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Recibe los arrastres en AppKit: archivos de Finder y los iconos del propio dock al reordenar.
final class DockHostingView: NSHostingView<DockView> {
    required init(rootView: DockView) {
        super.init(rootView: rootView)
        registerForDraggedTypes([])
    }

    @MainActor required dynamic init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    // Sin esto, cuando MyDock está activa (p. ej. tras el aviso de vaciar la Papelera) macOS gasta el primer
    // clic en seleccionar el panel y hay que hacer otro: el dock debe responder siempre al primer clic.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // SwiftUI vuelve a registrar (o borrar) sus tipos; se añaden siempre los nuestros.
    override func registerForDraggedTypes(_ newTypes: [NSPasteboard.PasteboardType]) {
        super.registerForDraggedTypes(newTypes + [.fileURL, .string])
    }

    override func unregisterDraggedTypes() {
        super.unregisterDraggedTypes()
        super.registerForDraggedTypes([.fileURL, .string])
    }

    // La ventana crece o encoge con el contenido (p. ej. al cambiar la ciudad del tiempo).
    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            // Tamaño ideal, no el mínimo (fittingSize encoge los textos hasta «…»).
            let size = self.intrinsicContentSize
            if window.frame.size != size { window.setContentSize(size) }
        }
    }

    private var store: DockStore { rootView.store }

    private func fileURLs(_ info: NSDraggingInfo) -> [URL] {
        info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }

    private func draggedItem(_ info: NSDraggingInfo) -> UUID? {
        info.draggingPasteboard.string(forType: .string).flatMap(UUID.init(uuidString:))
    }

    override func draggingEntered(_ info: NSDraggingInfo) -> NSDragOperation { draggingUpdated(info) }

    override func draggingUpdated(_ info: NSDraggingInfo) -> NSDragOperation {
        if !fileURLs(info).isEmpty { return .copy }
        return draggedItem(info) != nil ? .move : []
    }

    override func performDragOperation(_ info: NSDraggingInfo) -> Bool {
        // Los marcos de SwiftUI tienen el origen arriba a la izquierda.
        let p = convert(info.draggingLocation, from: nil)
        let along = store.vertical ? (isFlipped ? p.y : bounds.height - p.y) : p.x
        // Encima de la Papelera: los archivos van a la Papelera y los iconos del dock se quitan del dock.
        let point = CGPoint(x: p.x, y: isFlipped ? p.y : bounds.height - p.y)
        if store.config.showTrash != false, store.frames[TrashModel.id]?.contains(point) == true {
            let files = fileURLs(info)
            if !files.isEmpty { TrashModel.shared.moveToTrash(files); return true }
            guard let id = draggedItem(info) else { return false }
            store.remove(id)
            return true
        }
        let z = zones(store.config.items)  // el orden en pantalla, no el de la config
        let target = dropTarget(z.apps + z.widgets, store.frames, at: along, vertical: store.vertical)
        let urls = fileURLs(info)
        if !urls.isEmpty {
            for url in urls {
                if let group = target.group { store.addToGroup(group, url.path) } else { store.addFile(url.path, before: target.before) }
            }
            return true
        }
        guard let id = draggedItem(info) else { return false }
        if let group = target.group, group != id { store.moveIntoGroup(id, group) } else { store.move(id, before: target.before) }
        return true
    }
}

/// Dónde cae un drop a lo largo del dock (x en horizontal, y hacia abajo en vertical):
/// dentro de un grupo (su zona central) o delante de un elemento (nil = al final).
func dropTarget(_ items: [DockItem], _ frames: [UUID: CGRect], at pos: CGFloat, vertical: Bool) -> (group: UUID?, before: UUID?) {
    for item in items {
        guard let f = frames[item.id] else { continue }
        let (lo, hi) = vertical ? (f.minY, f.maxY) : (f.minX, f.maxX)
        let quarter = (hi - lo) * 0.25
        if item.kind == .group, pos > lo + quarter, pos < hi - quarter { return (item.id, nil) }
        if pos < (lo + hi) / 2 { return (nil, item.id) }
    }
    return (nil, nil)
}
