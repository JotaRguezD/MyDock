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
                        .contextMenu {
                            Button(t("Mantener en el dock")) { store.addFile(path) }
                            quitButton(path)
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
        .contextMenu { backgroundMenu }
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
                .contextMenu {
                    Button(t("Mostrar en Finder")) { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)]) }
                    if !store.groups.isEmpty {
                        Menu(t("Mover a grupo")) {
                            ForEach(store.groups) { g in
                                Button(g.name ?? t("Grupo")) { store.moveIntoGroup(item.id, g.id) }
                            }
                        }
                    }
                    Divider()
                    Button(t("Quitar del dock")) { store.remove(item.id) }
                    quitButton(path)
                }
        case .separator:
            separatorLine(size)
                .contentShape(Rectangle())
                .contextMenu { Button(t("Quitar separador")) { store.remove(item.id) } }
                .accessibilityHidden(true)
        case .spacer:
            Color.clear.frame(width: store.vertical ? size : size / 2, height: store.vertical ? size / 2 : size)
                .contentShape(Rectangle())
                .contextMenu { Button(t("Quitar espacio")) { store.remove(item.id) } }
                .accessibilityHidden(true)
        case .group:
            GroupItemView(item: item, store: store, running: running, size: size)
                .contextMenu {
                    Button(t("Renombrar…")) {
                        ask(t("Nombre del grupo"), item.name ?? "") { store.rename(item.id, $0) }
                    }
                    Divider()
                    Button(t("Quitar grupo")) { store.remove(item.id) }
                }
        case .widget:
            WidgetView(item: item, store: store, size: size)
                .contextMenu {
                    let compact = item.settings?.compact == true
                    if item.widget == .weather {
                        let s = item.settings ?? WidgetSettings()
                        Menu(t("Ciudad")) {
                            Button { store.updateSettings(item.id) { $0.selectedCity = nil } } label: {
                                checked(t("Ubicación actual"), s.selectedCity == nil)
                            }
                            ForEach(s.cities ?? [], id: \.self) { city in
                                Button { store.updateSettings(item.id) { $0.selectedCity = city } } label: { checked(city, s.selectedCity == city) }
                            }
                            Divider()
                            Button(t("Gestionar ciudades…")) { SettingsWindow.shared.show(store, select: item.id) }
                        }
                    }
                    Button(t("Ajustes del widget…")) { SettingsWindow.shared.show(store, select: item.id) }
                    Button(compact ? t("Versión amplia") : t("Versión compacta")) { store.updateSettings(item.id) { $0.compact = !compact } }
                    Divider()
                    Button(t("Quitar widget")) { store.remove(item.id) }
                }
        }
    }

    private func quitButton(_ path: String) -> some View { MyDock.quitButton(path, running: running) }

    private func separatorLine(_ size: CGFloat) -> some View {
        Capsule().fill(.primary.opacity(0.3))
            .frame(width: store.vertical ? size * 0.8 : 1.5, height: store.vertical ? 1.5 : size * 0.8)
            .padding(store.vertical ? .vertical : .horizontal, 4)
            .frame(width: store.vertical ? size : nil, height: store.vertical ? nil : size)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var backgroundMenu: some View {
        Button(t("Añadir separador")) { store.append(DockItem(kind: .separator)) }
        Button(t("Añadir espacio")) { store.append(DockItem(kind: .spacer)) }
        Button(t("Nuevo grupo…")) {
            ask(t("Nombre del grupo"), "") { store.append(DockItem(kind: .group, name: $0, apps: [])) }
        }
        Menu(t("Añadir widget")) {
            ForEach(WidgetKind.allCases, id: \.self) { kind in
                Button { store.addWidget(kind) } label: { Label(kind.title, systemImage: kind.symbol) }
                    .disabled(store.hasWidget(kind))
            }
        }
        Menu(t("Posición")) {
            Button { store.config.position = .left } label: { checked(t("Izquierda"), store.position == .left) }
            Button { store.config.position = .bottom } label: { checked(t("Abajo"), store.position == .bottom) }
            Button { store.config.position = .right } label: { checked(t("Derecha"), store.position == .right) }
        }
        Menu(t("Tamaño")) {
            Button(t("Pequeño")) { store.config.iconSize = 36 }
            Button(t("Mediano")) { store.config.iconSize = 48 }
            Button(t("Grande")) { store.config.iconSize = 64 }
        }
        // Botones con marca en vez de Toggle: el Toggle del menú contextual no llega a guardar el cambio.
        let autoHide = store.config.autoHide ?? false
        Button { store.config.autoHide = !autoHide } label: { checked(t("Ocultar automáticamente"), autoHide) }
        Button {
            let on = !login.enabled
            DispatchQueue.main.async { login.set(on) }  // fuera del menú: puede mostrar una alerta
        } label: { checked(t("Abrir al iniciar sesión"), login.enabled) }
        let appleHidden = store.config.hideAppleDock ?? false
        Menu(t("Dock a usar")) {
            Button { store.setHideAppleDock(true) } label: { checked(t("Solo MyDock"), appleHidden) }
            Button { store.setHideAppleDock(false) } label: { checked(t("MyDock y el de Apple"), !appleHidden) }
            Divider()
            Button(t("Solo el de Apple (cierra MyDock)")) {
                store.setHideAppleDock(false)
                DispatchQueue.main.async {
                    if login.enabled { login.set(false) }  // si no, MyDock volvería al iniciar sesión
                    NSApp.terminate(nil)
                }
            }
        }
        Divider()
        Button(t("Ajustes…")) { SettingsWindow.shared.show(store) }
        Divider()
        Button(t("Salir de MyDock")) { NSApp.terminate(nil) }
    }
}

/// «Salir», siempre la última opción del menú de una app (en gris si no está abierta). Carpetas y documentos no lo llevan.
@ViewBuilder
func quitButton(_ path: String, running: RunningApps) -> some View {
    if path.hasSuffix(".app") {
        let app = running.quittable(path)
        Divider()
        Button(t("Salir")) { app?.terminate() }.disabled(app == nil)
    }
}

@ViewBuilder
private func checked(_ title: String, _ on: Bool) -> some View {
    if on { Label(title, systemImage: "checkmark") } else { Text(title) }
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
                     .right: CGSize(width: -jump, height: 0)][edge]!
        VStack(spacing: 2) {
            Image(nsImage: image ?? NSWorkspace.shared.icon(forFile: path))
                .resizable()
                .frame(width: size, height: size)
                .scaleEffect(hover ? 1.12 : 1, anchor: [.left: .leading, .right: .trailing][edge] ?? .bottom)  // crece desde el borde del dock
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
                            .contextMenu {
                                Button(t("Sacar al dock")) { store.takeOut(item.id, path) }
                                Button(t("Quitar del grupo")) { store.removeFromGroup(item.id, path) }
                                quitButton(path, running: running)
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

