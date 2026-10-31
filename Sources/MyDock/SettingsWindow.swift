import AppKit
import SwiftUI

/// Ventana de Ajustes: «General» y un apartado por cada widget del dock.
final class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?
    private let selection = SettingsSelection()

    func show(_ store: DockStore, select id: UUID? = nil) {
        DispatchQueue.main.async { [self] in  // fuera del menú contextual que lo abre
            selection.id = id ?? SettingsSelection.general
            if window == nil {
                let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store, selection: selection)))
                window.title = t("Ajustes de MyDock")
                window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
                window.setContentSize(NSSize(width: 640, height: 460))
                window.isReleasedWhenClosed = false
                self.window = window
            }
            // Centrada en la pantalla de la barra de menús (la del dock); center() usa la «activa», que puede ser otro monitor.
            if let window, !window.isVisible, let screen = NSScreen.screens.first {
                let size = window.frame.size, area = screen.visibleFrame
                window.setFrameOrigin(NSPoint(x: area.midX - size.width / 2, y: area.midY - size.height / 2))
            }
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
        }
    }
}

final class SettingsSelection: ObservableObject {
    static let general = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    @Published var id: UUID? = general
}

struct SettingsView: View {
    @ObservedObject var store: DockStore
    @ObservedObject var selection: SettingsSelection

    var body: some View {
        let widgets = store.config.items.filter { $0.kind == .widget }
        NavigationSplitView {
            List(selection: $selection.id) {
                Label(t("General"), systemImage: "gearshape").tag(SettingsSelection.general)
                Section(t("Widgets")) {
                    ForEach(widgets) { item in
                        Label(item.widget?.title ?? t("Widget"), systemImage: item.widget?.symbol ?? "square").tag(item.id)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                Menu {
                    ForEach(WidgetKind.allCases, id: \.self) { kind in
                        Button { selection.id = store.addWidget(kind) } label: { Label(kind.title, systemImage: kind.symbol) }
                            .disabled(store.hasWidget(kind))
                    }
                } label: { Label(t("Añadir widget"), systemImage: "plus") }
            }
        } detail: {
            if let id = selection.id, let item = widgets.first(where: { $0.id == id }) {
                WidgetSettingsForm(item: item, store: store) { selection.id = SettingsSelection.general }
            } else {
                GeneralSettingsForm(store: store)
            }
        }
    }
}

struct GeneralSettingsForm: View {
    @ObservedObject var store: DockStore
    @StateObject private var login = LoginItem()
    @State private var axTrusted = WindowFitter.trusted

    var body: some View {
        Form {
            Picker(t("Idioma"), selection: Binding(get: { AppLanguage.chosen }, set: { AppLanguage.choose($0) })) {
                Text(t("El del sistema")).tag(nil as String?)
                ForEach(AppLanguage.all, id: \.code) { Text($0.name).tag($0.code as String?) }
            }
            Picker(t("Posición"), selection: Binding(get: { store.position }, set: { store.config.position = $0 })) {
                Text(t("Arriba")).tag(DockPosition.top)
                Text(t("Izquierda")).tag(DockPosition.left)
                Text(t("Abajo")).tag(DockPosition.bottom)
                Text(t("Derecha")).tag(DockPosition.right)
            }
            Picker(t("Tamaño de los iconos"), selection: Binding(get: { store.config.iconSize ?? 48 }, set: { store.config.iconSize = $0 })) {
                Text(t("Pequeño")).tag(36.0)
                Text(t("Mediano")).tag(48.0)
                Text(t("Grande")).tag(64.0)
            }
            Toggle(t("Ocultar automáticamente"), isOn: Binding(get: { store.config.autoHide ?? false }, set: { store.config.autoHide = $0 }))
            Toggle(t("Mostrar papelera"), isOn: Binding(get: { store.config.showTrash != false }, set: { store.config.showTrash = $0 }))
            VStack(alignment: .leading, spacing: 4) {
                Toggle(t("Ajustar ventanas al dock"), isOn: Binding(get: { store.config.fitWindows ?? false }, set: { on in
                    store.config.fitWindows = on
                    if on && !WindowFitter.trusted { WindowFitter.requestPermission() }
                }))
                Text(t("Las ventanas maximizadas se paran en el dock y MyDock se esconde en pantalla completa. Necesita el permiso de Accesibilidad."))
                    .font(.caption).foregroundStyle(.secondary)
                if store.config.fitWindows == true && !axTrusted {
                    HStack {
                        Text(t("Falta el permiso de Accesibilidad.")).font(.caption).foregroundStyle(.orange)
                        Button(t("Dar permiso…")) { WindowFitter.openPrivacy() }.controlSize(.small)
                    }
                }
            }
            Picker(t("Dock a usar"), selection: Binding(get: { store.config.hideAppleDock ?? false }, set: { store.setHideAppleDock($0) })) {
                Text(t("Solo MyDock")).tag(true)
                Text(t("MyDock y el de Apple")).tag(false)
            }
            Toggle(t("Abrir al iniciar sesión"), isOn: Binding(get: { login.enabled }, set: { login.set($0) }))
        }
        .formStyle(.grouped)
        // El permiso se da en Ajustes del Sistema: se vuelve a mirar cada pocos segundos.
        .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in axTrusted = WindowFitter.trusted }
        .navigationTitle(t("General"))
    }
}

struct WidgetSettingsForm: View {
    let item: DockItem
    @ObservedObject var store: DockStore
    let removed: () -> Void

    var body: some View {
        let kind = item.widget ?? .clock
        Form {
            Section(t("Aspecto")) {
                Toggle(t("Versión compacta"), isOn: flag(\.compact))
                Picker(t("Color"), selection: value(\.color, .none)) {
                    ForEach(WidgetColor.allCases, id: \.self) { c in
                        Label { Text(c.title) } icon: { Image(systemName: "circle.fill").foregroundStyle(c.color ?? .secondary) }.tag(c)
                    }
                }
            }
            if kind == .weather {
                WeatherSettings(id: item.id, store: store)  // con varias secciones propias
            } else {
                Section(kind.title) { options(kind) }
            }
            Section {
                Button(t("Quitar widget"), role: .destructive) {
                    store.remove(item.id)
                    removed()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(kind.title)
    }

    @ViewBuilder
    private func options(_ kind: WidgetKind) -> some View {
        switch kind {
        case .clock:
            Toggle(t("Formato de 12 horas"), isOn: flag(\.hour12))
            Toggle(t("Mostrar segundos"), isOn: flag(\.seconds))
            Toggle(t("Mostrar la fecha"), isOn: shown(\.hideDate))
        case .weather:
            EmptyView()  // va fuera, en WeatherSettings
        case .music:
            Toggle(t("Mostrar botones de reproducción"), isOn: shown(\.hideControls))
        case .system:
            Toggle(t("Mostrar CPU"), isOn: shown(\.hideCPU))
            Toggle(t("Mostrar RAM"), isOn: shown(\.hideRAM))
        case .events:
            Picker(t("Buscar eventos en"), selection: value(\.daysAhead, 1)) {
                Text(t("Hoy")).tag(1)
                Text(t("Próximos 3 días")).tag(3)
                Text(t("Próxima semana")).tag(7)
            }
        case .pomodoro:
            Stepper(t("Concentración: %ld min", value(\.workMinutes, 25).wrappedValue), value: value(\.workMinutes, 25), in: 5...90, step: 5)
            Stepper(t("Descanso: %ld min", value(\.breakMinutes, 5).wrappedValue), value: value(\.breakMinutes, 5), in: 1...30)
        case .note:
            TextEditor(text: value(\.note, "")).frame(minHeight: 100).font(.body)
        case .clipboard, .downloads, .screenshots:
            Picker(t("Elementos en la lista"), selection: value(\.itemCount, 10)) {
                ForEach([5, 10, 20], id: \.self) { Text("\($0)").tag($0) }
            }
        case .diskNet:
            Toggle(t("Mostrar disco"), isOn: shown(\.hideDisk))
            Toggle(t("Mostrar red"), isOn: shown(\.hideNetwork))
        case .colorPicker:
            Picker(t("Formato al copiar"), selection: flag(\.rgbFormat)) {
                Text(t("Hexadecimal (#1A2B3C)")).tag(false)
                Text(t("RGB (rgb(26, 43, 60))")).tag(true)
            }
        case .reminders, .battery, .search, .controls:
            Text(t("Este widget no tiene más opciones.")).foregroundStyle(.secondary)
        }
    }

    private func value<T>(_ key: WritableKeyPath<WidgetSettings, T?>, _ fallback: T) -> Binding<T> {
        Binding(get: { store.settings(item.id)[keyPath: key] ?? fallback },
                set: { new in store.updateSettings(item.id) { $0[keyPath: key] = new } })
    }

    private func flag(_ key: WritableKeyPath<WidgetSettings, Bool?>) -> Binding<Bool> { value(key, false) }

    /// Los ajustes «hide…» se muestran al revés: un interruptor de «Mostrar».
    private func shown(_ key: WritableKeyPath<WidgetSettings, Bool?>) -> Binding<Bool> {
        Binding(get: { store.settings(item.id)[keyPath: key] != true },
                set: { show in store.updateSettings(item.id) { $0[keyPath: key] = !show } })
    }
}

/// Ajustes del tiempo: de dónde mostrarlo (ubicación o una ciudad) y la lista de ciudades guardadas.
struct WeatherSettings: View {
    let id: UUID
    @ObservedObject var store: DockStore
    @ObservedObject private var location = LocationProvider.shared
    @State private var newCity = ""
    @State private var searching = false
    @State private var error: String?

    var body: some View {
        let s = store.settings(id)
        let cities = s.cities ?? []
        Section(t("Tiempo")) {
            Picker(t("Mostrar el tiempo de"), selection: Binding(get: { s.selectedCity.flatMap { cities.contains($0) ? $0 : nil } },
                                                              set: { new in store.updateSettings(id) { $0.selectedCity = new } })) {
                Text(location.refused ? t("Ubicación actual (sin permiso)") : t("Ubicación actual")).tag(nil as String?)
                ForEach(cities, id: \.self) { Text($0).tag($0 as String?) }
            }
            if location.refused {
                HStack {
                    Text(cities.isEmpty ? t("Sin permiso de ubicación: añade una ciudad.") : t("Sin permiso de ubicación: se usa %@.", cities[0]))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(t("Dar permiso…")) { LocationProvider.openPrivacy() }
                }
            }
            Picker(t("Unidades"), selection: Binding(get: { s.fahrenheit == true }, set: { new in store.updateSettings(id) { $0.fahrenheit = new } })) {
                Text(t("Celsius (°C)")).tag(false)
                Text(t("Fahrenheit (°F)")).tag(true)
            }
        }
        Section(t("Ciudades guardadas")) {
            ForEach(cities, id: \.self) { city in
                HStack {
                    Text(city)
                    Spacer()
                    Button { remove(city) } label: { Image(systemName: "minus.circle.fill").foregroundStyle(.red) }
                        .buttonStyle(.plain)
                        .help(t("Quitar %@", city))
                }
            }
            HStack {
                TextField(t("Añadir ciudad"), text: $newCity).onSubmit(add)
                if searching { ProgressView().controlSize(.small) }
                Button(t("Añadir"), action: add).disabled(newCity.trimmingCharacters(in: .whitespaces).isEmpty || searching)
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
    }

    /// Solo se guarda si el servicio de mapas la encuentra, con su nombre oficial.
    private func add() {
        let text = newCity.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !searching else { return }
        searching = true
        error = nil
        Task {
            let found = await CityLookup.find(text)
            await MainActor.run {
                searching = false
                guard let found else { return error = t("No encuentro «%@». Prueba con otro nombre.", text) }
                store.updateSettings(id) { s in
                    if !(s.cities ?? []).contains(found.name) { s.cities = (s.cities ?? []) + [found.name] }
                }
                newCity = ""
            }
        }
    }

    private func remove(_ city: String) {
        store.updateSettings(id) { s in
            s.cities?.removeAll { $0 == city }
            if s.selectedCity == city { s.selectedCity = nil }
        }
    }
}
