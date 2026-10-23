import AppKit
import ServiceManagement
import SwiftUI  // Array.move(fromOffsets:toOffset:)

enum ItemKind: String, Codable { case file, separator, spacer, group, widget }
enum WidgetKind: String, Codable, CaseIterable {
    case clock, weather, music, system
    case events, reminders, pomodoro, note
    case battery, controls, clipboard, diskNet
    case downloads, screenshots, search, colorPicker

    var title: String {
        switch self {
        case .clock: return t("Reloj y fecha")
        case .weather: return t("Tiempo")
        case .music: return t("Música")
        case .system: return t("CPU y memoria")
        case .events: return t("Próximos eventos")
        case .reminders: return t("Recordatorios")
        case .pomodoro: return t("Pomodoro")
        case .note: return t("Nota rápida")
        case .battery: return t("Batería")
        case .controls: return t("Volumen")
        case .clipboard: return t("Portapapeles")
        case .diskNet: return t("Disco y red")
        case .downloads: return t("Descargas")
        case .screenshots: return t("Capturas")
        case .search: return t("Buscar")
        case .colorPicker: return t("Selector de color")
        }
    }

    var symbol: String {
        switch self {
        case .clock: return "clock"
        case .weather: return "cloud.sun"
        case .music: return "music.note"
        case .system: return "cpu"
        case .events: return "calendar"
        case .reminders: return "checklist"
        case .pomodoro: return "timer"
        case .note: return "note.text"
        case .battery: return "battery.75"
        case .controls: return "speaker.wave.2"
        case .clipboard: return "doc.on.clipboard"
        case .diskNet: return "internaldrive"
        case .downloads: return "arrow.down.circle"
        case .screenshots: return "camera.viewfinder"
        case .search: return "magnifyingglass"
        case .colorPicker: return "eyedropper"
        }
    }
}

enum WidgetColor: String, Codable, CaseIterable {
    case none, blue, purple, pink, red, orange, yellow, green, gray

    var title: String {
        switch self {
        case .none: return t("Sin color")
        case .blue: return t("Azul")
        case .purple: return t("Morado")
        case .pink: return t("Rosa")
        case .red: return t("Rojo")
        case .orange: return t("Naranja")
        case .yellow: return t("Amarillo")
        case .green: return t("Verde")
        case .gray: return t("Gris")
        }
    }

    var color: Color? {
        switch self {
        case .none: return nil
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .gray: return .gray
        }
    }
}

/// Ajustes de cada widget. Todo opcional: nil = valor por defecto (los «hide…» se ven salvo que se oculten).
struct WidgetSettings: Codable, Equatable {
    var compact: Bool?
    var color: WidgetColor?
    var hour12: Bool?, seconds: Bool?, hideDate: Bool?               // reloj
    var cities: [String]?, selectedCity: String?, fahrenheit: Bool?  // tiempo (selectedCity nil = ubicación actual)
    var city: String?                                                // antiguo: se pasa a «cities» al arrancar
    var hideControls: Bool?                                          // música
    var hideCPU: Bool?, hideRAM: Bool?                               // CPU y memoria
    var daysAhead: Int?                                              // eventos
    var workMinutes: Int?, breakMinutes: Int?                        // pomodoro
    var note: String?                                                // nota
    var itemCount: Int?                                              // portapapeles, descargas, capturas
    var hideDisk: Bool?, hideNetwork: Bool?                          // disco y red
    var rgbFormat: Bool?                                             // selector de color
}
enum DockPosition: String, Codable { case left, bottom, right }

struct DockItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: ItemKind
    var path: String?      // .file: app, carpeta o documento
    var name: String?      // .group
    var apps: [String]?    // .group
    var widget: WidgetKind?
    var settings: WidgetSettings?
}

struct DockConfig: Codable, Equatable {
    var items: [DockItem]
    var city: String?  // antiguo: ciudad global del tiempo, se pasa a la lista del widget al arrancar
    var iconSize: Double?
    var autoHide: Bool?
    var fitWindows: Bool?  // ajustar ventanas maximizadas al dock (necesita Accesibilidad)
    var showTrash: Bool?   // nil = sí, como el Dock de Apple
    var position: DockPosition?
    var hideAppleDock: Bool?
    var appleDockBackup: AppleDockBackup?

    static var `default`: DockConfig {
        let fm = FileManager.default
        func files(_ paths: [String]) -> [DockItem] {
            paths.filter(fm.fileExists).map { DockItem(kind: .file, path: $0) }
        }
        let utilities = ["/System/Applications/Utilities/Terminal.app",
                         "/System/Applications/Utilities/Activity Monitor.app"].filter(fm.fileExists)
        return DockConfig(items:
            files(["/System/Library/CoreServices/Finder.app", "/Applications/Safari.app", "/System/Applications/Notes.app"])
            + [DockItem(kind: .group, name: t("Utilidades"), apps: utilities),
               DockItem(kind: .separator),
               DockItem(kind: .widget, widget: .clock),
               DockItem(kind: .widget, widget: .weather),
               DockItem(kind: .separator),
               DockItem(kind: .widget, widget: .music),
               DockItem(kind: .widget, widget: .system)],
            iconSize: 48)
    }
}

/// Reparte el dock en dos zonas fijas: apps (archivos y grupos) y widgets. Separadores y espacios van con
/// el elemento que tienen detrás (o con el último, si cierran la lista).
func zones(_ items: [DockItem]) -> (apps: [DockItem], widgets: [DockItem]) {
    var apps: [DockItem] = [], widgets: [DockItem] = [], pending: [DockItem] = []
    var lastWasWidget = false
    for item in items {
        switch item.kind {
        case .separator, .spacer: pending.append(item)
        case .widget: widgets += pending + [item]; pending = []; lastWasWidget = true
        case .file, .group: apps += pending + [item]; pending = []; lastWasWidget = false
        }
    }
    if lastWasWidget { widgets += pending } else { apps += pending }
    return (apps, widgets)
}

/// Pasa la ciudad antigua (la global y la del widget) a la lista de ciudades guardadas del widget del tiempo.
func migratedWeatherCities(_ config: DockConfig) -> DockConfig {
    var c = config
    for i in c.items.indices where c.items[i].widget == .weather {
        guard var s = c.items[i].settings ?? (c.city == nil ? nil : WidgetSettings()) else { continue }
        let legacy = [s.city, c.city].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if s.cities == nil, !legacy.isEmpty {
            s.cities = legacy.reduce(into: []) { list, name in if !list.contains(name) { list.append(name) } }
        }
        s.city = nil
        c.items[i].settings = s
    }
    c.city = nil
    return c
}

/// Qué ciudad mostrar (nil = la ubicación actual): la elegida si sigue guardada; si no, la ubicación,
/// salvo que no haya permiso, en cuyo caso la primera ciudad guardada.
func weatherCity(selected: String?, cities: [String], locationAllowed: Bool) -> String? {
    if let selected, cities.contains(selected) { return selected }
    return locationAllowed ? nil : cities.first
}

/// Deja solo el primero de cada tipo de widget.
func withoutDuplicateWidgets(_ items: [DockItem]) -> [DockItem] {
    var seen = Set<WidgetKind>()
    return items.filter { item in item.widget.map { seen.insert($0).inserted } ?? true }
}

/// Mueve `id` a la posición de `target` (lo que hace el Dock al arrastrar).
func moved(_ items: [DockItem], _ id: UUID, before target: UUID) -> [DockItem] {
    guard id != target,
          let from = items.firstIndex(where: { $0.id == id }),
          let to = items.firstIndex(where: { $0.id == target }) else { return items }
    var result = items
    result.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
    return result
}

final class DockStore: ObservableObject {
    @Published var config: DockConfig { didSet { if config != oldValue { save() } } }

    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/MyDock/config.json")

    /// Marco de cada elemento en la ventana (lo rellena DockView); no se guarda.
    var frames: [UUID: CGRect] = [:]

    init() {
        config = Self.load()
        // Arreglos de versiones anteriores: widgets repetidos y ciudad del tiempo antigua
        // (en init no salta didSet: se guarda a mano).
        var fixed = migratedWeatherCities(config)
        fixed.items = withoutDuplicateWidgets(fixed.items)
        if fixed != config {
            config = fixed
            save()
        }
    }

    static func load() -> DockConfig {
        guard let data = try? Data(contentsOf: url) else { return .default }
        if let config = try? JSONDecoder().decode(DockConfig.self, from: data) { return config }
        // Config ilegible: se aparta para no machacarla al guardar.
        let backup = url.deletingPathExtension().appendingPathExtension("broken-\(Int(Date().timeIntervalSince1970)).json")
        try? FileManager.default.moveItem(at: url, to: backup)
        NSLog("MyDock: config.json no válido, copia en \(backup.path)")
        return .default
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: Self.url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(config).write(to: Self.url, options: .atomic)
        } catch {
            NSLog("MyDock: no se pudo guardar la configuración: \(error)")
        }
    }


    var iconSize: CGFloat { CGFloat(config.iconSize ?? 48) }
    var position: DockPosition { config.position ?? .bottom }
    var vertical: Bool { position != .bottom }
    /// Hacia dónde se abren los popovers: siempre hacia el interior de la pantalla.
    var popoverEdge: Edge { [.left: .trailing, .right: .leading][position] ?? .top }

    func settings(_ id: UUID) -> WidgetSettings { config.items.first { $0.id == id }?.settings ?? WidgetSettings() }

    func updateSettings(_ id: UUID, _ change: (inout WidgetSettings) -> Void) {
        guard let i = index(id) else { return }
        var settings = config.items[i].settings ?? WidgetSettings()
        change(&settings)
        config.items[i].settings = settings
    }
    var groups: [DockItem] { config.items.filter { $0.kind == .group } }

    private func index(_ id: UUID) -> Int? { config.items.firstIndex { $0.id == id } }

    func append(_ item: DockItem) { config.items.append(item) }

    func hasWidget(_ kind: WidgetKind) -> Bool { config.items.contains { $0.widget == kind } }

    /// Cada widget solo una vez: si ya está, no se añade y se devuelve el que había.
    @discardableResult
    func addWidget(_ kind: WidgetKind) -> UUID {
        if let existing = config.items.first(where: { $0.widget == kind }) { return existing.id }
        let item = DockItem(kind: .widget, widget: kind)
        config.items.append(item)
        return item.id
    }
    func remove(_ id: UUID) { config.items.removeAll { $0.id == id } }
    /// Mueve `id` delante de `target`, o al final si es nil.
    func move(_ id: UUID, before target: UUID?) {
        if let target {
            config.items = moved(config.items, id, before: target)
        } else if let i = index(id) {
            config.items.append(config.items.remove(at: i))
        }
    }

    func addFile(_ path: String, before target: UUID? = nil) {
        guard !config.items.contains(where: { $0.path == path }) else { return }
        let item = DockItem(kind: .file, path: path)
        if let target, let i = index(target) { config.items.insert(item, at: i) } else { config.items.append(item) }
    }

    func addToGroup(_ group: UUID, _ path: String) {
        guard let i = index(group), !(config.items[i].apps ?? []).contains(path) else { return }
        config.items[i].apps = (config.items[i].apps ?? []) + [path]
    }

    func removeFromGroup(_ group: UUID, _ path: String) {
        guard let i = index(group) else { return }
        config.items[i].apps?.removeAll { $0 == path }
    }

    /// Mueve una app del dock dentro de un grupo.
    func moveIntoGroup(_ item: UUID, _ group: UUID) {
        guard let path = config.items.first(where: { $0.id == item })?.path else { return }
        addToGroup(group, path)
        remove(item)
    }

    /// Saca una app de un grupo y la pone en el dock, justo detrás del grupo.
    func takeOut(_ group: UUID, _ path: String) {
        removeFromGroup(group, path)
        guard let i = index(group) else { return }
        config.items.insert(DockItem(kind: .file, path: path), at: i + 1)
    }

    func rename(_ group: UUID, _ name: String) {
        guard let i = index(group) else { return }
        config.items[i].name = name
    }
}

/// Apps abiertas, por bundle id, para el punto bajo el icono.
final class RunningApps: ObservableObject {
    @Published private(set) var ids: Set<String> = []
    /// Apps con icono propio (las de ⌘-Tab), en orden de apertura.
    @Published private(set) var regular: [NSRunningApplication] = []

    init() {
        refresh()
        let nc = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        }
    }

    func refresh() {
        let apps = NSWorkspace.shared.runningApplications
        ids = Set(apps.compactMap(\.bundleIdentifier))
        regular = apps.filter { $0.activationPolicy == .regular && $0.bundleURL != nil && $0.bundleIdentifier != nil }
    }

    /// Abiertas pero no ancladas en el dock (ni dentro de un grupo); se compara por bundle id porque
    /// la ruta real puede no coincidir (Safari corre desde /System/Cryptexes).
    func unpinned(_ items: [DockItem]) -> [NSRunningApplication] {
        let paths = items.flatMap { [$0.path].compactMap { $0 } + ($0.apps ?? []) }
        let pinned = Set(paths.compactMap { Bundle(path: $0)?.bundleIdentifier })
        return regular.filter { !pinned.contains($0.bundleIdentifier!) }
    }

    /// La app abierta de esa ruta, para poder salir de ella. Se busca entre todas las abiertas (también las que
    /// viven en la barra de menús), nunca Finder: macOS lo mantiene siempre abierto.
    func quittable(_ path: String) -> NSRunningApplication? {
        guard let id = Bundle(path: path)?.bundleIdentifier, id != "com.apple.finder", ids.contains(id) else { return nil }
        return NSRunningApplication.runningApplications(withBundleIdentifier: id).first
    }

    func isRunning(_ path: String) -> Bool {
        guard let id = Bundle(path: path)?.bundleIdentifier else { return false }
        return ids.contains(id)
    }
}

/// Abre una app, carpeta o documento y lo trae al frente. macOS no deja que una app de fondo (MyDock) ponga
/// delante a otra que ya está abierta (p. ej. Finder): MyDock se activa primero con el clic y así cede el paso.
/// Sin esto, la ventana se abre detrás y parece que hace falta un segundo clic.
func openPath(_ path: String) {
    NSApp.activate(ignoringOtherApps: true)
    let url = URL(fileURLWithPath: path)
    let config = NSWorkspace.OpenConfiguration()
    config.activates = true
    if url.pathExtension == "app" {
        NSWorkspace.shared.openApplication(at: url, configuration: config)
    } else if let app = NSWorkspace.shared.urlForApplication(toOpen: url) {
        NSWorkspace.shared.open([url], withApplicationAt: app, configuration: config)
    } else {
        NSWorkspace.shared.open(url)
    }
}

func displayName(_ path: String) -> String { FileManager.default.displayName(atPath: path) }

/// Autoocultar: aparece al tocar el borde inferior, se esconde tras 0,6 s con el ratón fuera.
func shouldHide(enabled: Bool, atEdge: Bool, overDock: Bool, busy: Bool, hidden: Bool, outsideFor: TimeInterval) -> Bool {
    guard enabled, !busy, !atEdge else { return false }
    if hidden { return true }
    return !overDock && outsideFor > 0.6
}

/// Abrir al iniciar sesión (Ajustes del Sistema → General → Ítems de inicio).
final class LoginItem: ObservableObject {
    @Published private(set) var enabled = SMAppService.mainApp.status == .enabled

    func set(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            let alert = NSAlert()
            alert.messageText = t("No se pudo cambiar el inicio automático")
            alert.informativeText = error.localizedDescription
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
        if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
        enabled = SMAppService.mainApp.status == .enabled
    }
}
