import AppKit
import Darwin
import Foundation

/// `MyDock --selftest`: comprobaciones rápidas de la lógica sin interfaz.
func selfTest() {
    // Reordenar: igual que arrastrar en el dock.
    let a = DockItem(kind: .separator), b = DockItem(kind: .spacer), c = DockItem(kind: .widget, widget: .clock)
    precondition(moved([a, b, c], a.id, before: c.id).map(\.id) == [b.id, c.id, a.id])
    precondition(moved([a, b, c], c.id, before: a.id).map(\.id) == [c.id, a.id, b.id])
    precondition(moved([a, b, c], a.id, before: a.id).map(\.id) == [a.id, b.id, c.id])

    // Zonas: la config del usuario (Brave anclado al final, tras los widgets) acaba con Brave entre las apps.
    let finder = DockItem(kind: .file, path: "/F.app"), grp = DockItem(kind: .group, name: "G", apps: [])
    let sep1 = DockItem(kind: .separator), clock = DockItem(kind: .widget, widget: .clock)
    let sep2 = DockItem(kind: .separator), music = DockItem(kind: .widget, widget: .music)
    let brave = DockItem(kind: .file, path: "/B.app")
    let z = zones([finder, grp, sep1, clock, sep2, music, brave])
    precondition(z.apps.map(\.id) == [finder.id, grp.id, brave.id])
    precondition(z.widgets.map(\.id) == [sep1.id, clock.id, sep2.id, music.id])
    let trailing = DockItem(kind: .separator)
    precondition(zones([clock, trailing]).widgets.map(\.id) == [clock.id, trailing.id])
    precondition(zones([finder, trailing]).apps.map(\.id) == [finder.id, trailing.id])

    // Dónde cae un drop: a, grupo g (x 50–100), b.
    let g = DockItem(kind: .group, name: "G", apps: [])
    let frames: [UUID: CGRect] = [a.id: CGRect(x: 0, y: 0, width: 50, height: 50),
                                  g.id: CGRect(x: 50, y: 0, width: 50, height: 50),
                                  b.id: CGRect(x: 100, y: 0, width: 50, height: 50)]
    let row = [a, g, b]
    precondition(dropTarget(row, frames, at: 10, vertical: false).before == a.id)
    precondition(dropTarget(row, frames, at: 40, vertical: false).before == g.id)
    precondition(dropTarget(row, frames, at: 75, vertical: false).group == g.id)
    precondition(dropTarget(row, frames, at: 90, vertical: false).before == b.id)
    let end = dropTarget(row, frames, at: 140, vertical: false)
    precondition(end.group == nil && end.before == nil)
    // En vertical cuenta la y: la misma fila puesta en columna.
    let column = frames.mapValues { CGRect(x: $0.minY, y: $0.minX, width: $0.height, height: $0.width) }
    precondition(dropTarget(row, column, at: 75, vertical: true).group == g.id)
    precondition(dropTarget(row, column, at: 90, vertical: true).before == b.id)

    // Posición en cada lado (pantalla 1000×800, Dock de Apple de 60 a la izquierda).
    let screen = NSRect(x: 0, y: 0, width: 1000, height: 800), visible = NSRect(x: 60, y: 0, width: 940, height: 775)
    let dock = NSSize(width: 100, height: 300)
    precondition(dockFrame(dock, screen: screen, visible: visible, .bottom, hidden: false).origin == NSPoint(x: 450, y: 0))
    precondition(dockFrame(dock, screen: screen, visible: visible, .bottom, hidden: true).maxY == 0)
    precondition(dockFrame(dock, screen: screen, visible: visible, .left, hidden: false).minX == 60)
    precondition(dockFrame(dock, screen: screen, visible: visible, .left, hidden: true).maxX == 0)
    precondition(dockFrame(dock, screen: screen, visible: visible, .right, hidden: false).maxX == 1000)
    precondition(dockFrame(dock, screen: screen, visible: visible, .right, hidden: true).minX == 1000)
    precondition(dockFrame(dock, screen: screen, visible: visible, .top, hidden: false).maxY == 775)  // bajo la barra de menús
    precondition(dockFrame(dock, screen: screen, visible: visible, .top, hidden: true).minY == 800)
    precondition(isAtEdge(NSPoint(x: 500, y: 799), of: screen, .top))
    // Menú del clic derecho: fuera del dock y centrado en el icono.
    let icon = NSRect(x: 100, y: 10, width: 48, height: 48), menuSize = NSSize(width: 200, height: 150)
    precondition(menuOrigin(menuSize, .bottom, icon: icon, dock: NSRect(x: 0, y: 0, width: 600, height: 70)) == NSPoint(x: 24, y: 231))
    precondition(menuOrigin(menuSize, .left, icon: icon, dock: NSRect(x: 0, y: 0, width: 70, height: 600)).x == 81)
    precondition(isAtEdge(NSPoint(x: 999, y: 400), of: screen, .right))
    precondition(!isAtEdge(NSPoint(x: 999, y: 400), of: screen, .left))
    precondition(isAtEdge(NSPoint(x: 0, y: 400), of: screen, .left))
    precondition(isAtEdge(NSPoint(x: 500, y: 1), of: screen, .bottom))
    precondition(!isAtEdge(NSPoint(x: 1500, y: 1), of: screen, .bottom))  // en otro monitor

    // Ajustar ventanas al dock (coordenadas con y hacia abajo): pantalla 1000×800 con menú de 25, dock abajo 700–780.
    let fitArea = CGRect(x: 0, y: 25, width: 1000, height: 775), bar = CGRect(x: 300, y: 700, width: 400, height: 80)
    let maximized = CGRect(x: 0, y: 25, width: 1000, height: 775)
    precondition(fittedFrame(maximized, dock: bar, area: fitArea, .bottom) == CGRect(x: 0, y: 25, width: 1000, height: 675))
    precondition(fittedFrame(CGRect(x: 0, y: 25, width: 1000, height: 675), dock: bar, area: fitArea, .bottom) == nil)  // ya ajustada
    precondition(fittedFrame(CGRect(x: 100, y: 100, width: 400, height: 300), dock: bar, area: fitArea, .bottom) == nil) // no llega al borde
    precondition(fittedFrame(CGRect(x: 0, y: 400, width: 250, height: 400), dock: bar, area: fitArea, .bottom) == nil)   // no pasa por debajo del dock
    let sideBar = CGRect(x: 0, y: 200, width: 90, height: 400)
    precondition(fittedFrame(maximized, dock: CGRect(x: 300, y: 25, width: 400, height: 80), area: fitArea, .top)
                 == CGRect(x: 0, y: 105, width: 1000, height: 695))
    precondition(fittedFrame(maximized, dock: sideBar, area: fitArea, .left) == CGRect(x: 90, y: 25, width: 910, height: 775))
    precondition(fittedFrame(CGRect(x: 0, y: 25, width: 1000, height: 120), dock: bar, area: fitArea, .bottom) == nil) // quedaría diminuta

    // Autoocultar.
    precondition(!shouldHide(enabled: false, atEdge: false, overDock: false, busy: false, hidden: false, outsideFor: 9))
    precondition(!shouldHide(enabled: true, atEdge: false, overDock: false, busy: false, hidden: false, outsideFor: 0.3))
    precondition(shouldHide(enabled: true, atEdge: false, overDock: false, busy: false, hidden: false, outsideFor: 1))
    precondition(!shouldHide(enabled: true, atEdge: false, overDock: true, busy: false, hidden: false, outsideFor: 1))
    precondition(!shouldHide(enabled: true, atEdge: true, overDock: false, busy: false, hidden: true, outsideFor: 1))
    precondition(!shouldHide(enabled: true, atEdge: false, overDock: false, busy: true, hidden: true, outsideFor: 1))
    precondition(shouldHide(enabled: true, atEdge: false, overDock: false, busy: false, hidden: true, outsideFor: 0))

    // Sin widgets repetidos: se queda el primero; apps y separadores no se tocan.
    let vol1 = DockItem(kind: .widget, widget: .controls), vol2 = DockItem(kind: .widget, widget: .controls)
    let sepA = DockItem(kind: .separator), sepB = DockItem(kind: .separator)
    precondition(withoutDuplicateWidgets([vol1, sepA, vol2, sepB]).map(\.id) == [vol1.id, sepA.id, sepB.id])

    // Tiempo: qué ciudad se muestra.
    precondition(weatherCity(selected: nil, cities: ["Bcn"], locationAllowed: true) == nil)           // ubicación
    precondition(weatherCity(selected: nil, cities: ["Bcn"], locationAllowed: false) == "Bcn")        // sin permiso → la primera
    precondition(weatherCity(selected: "Mad", cities: ["Bcn", "Mad"], locationAllowed: true) == "Mad")
    precondition(weatherCity(selected: "Borrada", cities: ["Bcn"], locationAllowed: true) == nil)     // elegida ya no está
    precondition(weatherCity(selected: nil, cities: [], locationAllowed: false) == nil)

    // Tiempo: la ciudad antigua pasa a la lista de guardadas, sin repetir.
    var legacy = DockConfig(items: [DockItem(kind: .widget, widget: .weather, settings: WidgetSettings(city: "Lisboa"))])
    legacy.city = "Lisboa"
    let migrated = migratedWeatherCities(legacy)
    precondition(migrated.city == nil && migrated.items[0].settings?.city == nil)
    precondition(migrated.items[0].settings?.cities == ["Lisboa"] && migrated.items[0].settings?.selectedCity == nil)
    precondition(migratedWeatherCities(migrated) == migrated)  // ya migrada: no cambia

    // Widgets nuevos.
    precondition(clipboardHistory(["b", "a"], adding: "a") == ["a", "b"])  // sin duplicados, lo último arriba
    precondition(clipboardHistory((1...20).map(String.init), adding: "x").count == 20)
    precondition(minutesSeconds(1500) == "25:00" && minutesSeconds(59.2) == "1:00" && minutesSeconds(0) == "0:00")
    let teal = NSColor(srgbRed: 26 / 255, green: 43 / 255, blue: 60 / 255, alpha: 1)
    precondition(colorCode(teal, rgb: false) == "#1A2B3C" && colorCode(teal, rgb: true) == "rgb(26, 43, 60)")
    let now = Date()
    precondition(eventTimeText(now.addingTimeInterval(25 * 60 + 5), now: now) == "En 25 min")
    precondition(eventTimeText(now.addingTimeInterval(-60), now: now) == "Ahora")
    precondition(BatteryModel.symbol(90, charging: false) == "battery.100" && BatteryModel.symbol(10, charging: true) == "battery.100.bolt")
    precondition(WidgetKind.allCases.count == 16)

    // La configuración sobrevive a guardar y leer (incluida la copia del Dock de Apple, con clave ausente).
    var config = DockConfig.default
    config.items.append(DockItem(kind: .widget, widget: .note,
                                 settings: WidgetSettings(compact: true, color: .purple, note: "hola\nmundo")))
    config.hideAppleDock = true
    config.appleDockBackup = AppleDockBackup(autohide: false, delay: nil)
    let data = try! JSONEncoder().encode(config)
    precondition(try! JSONDecoder().decode(DockConfig.self, from: data) == config)

    // CPU: 50 ticks ocupados de 100.
    var before = host_cpu_load_info(), after = host_cpu_load_info()
    before.cpu_ticks = (100, 100, 100, 0)
    after.cpu_ticks = (130, 120, 150, 0)
    precondition(abs(SystemMonitor.usage(from: before, to: after) - 0.5) < 0.0001)
    precondition(SystemMonitor.usage(from: before, to: before) == 0)

    precondition(WeatherModel.symbol(0) == "sun.max.fill")
    precondition(WeatherModel.symbol(63) == "cloud.rain.fill")
    precondition(WeatherModel.symbol(-1) == "cloud.fill")

    print("selftest OK")
}
