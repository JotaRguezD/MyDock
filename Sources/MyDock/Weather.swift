import AppKit
import CoreLocation
import SwiftUI

// MARK: Ubicación actual

/// Ubicación del Mac (macOS pide permiso la primera vez) y nombre del sitio, compartidos por todo MyDock.
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationProvider()
    @Published private(set) var location: CLLocation?
    @Published private(set) var placeName: String?
    @Published private(set) var status: CLAuthorizationStatus
    private let manager = CLLocationManager()

    private override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer  // para el tiempo basta con la ciudad
    }

    var allowed: Bool { status == .authorizedAlways }  // en macOS no existe «solo mientras se usa»
    /// Sin permiso ni posibilidad de pedirlo: toca usar una ciudad guardada.
    var refused: Bool { status == .denied || status == .restricted }

    /// Pide permiso si aún no se ha pedido; si ya lo hay, actualiza la posición.
    func refresh() {
        if status == .notDetermined { manager.requestWhenInUseAuthorization() } else if allowed { manager.requestLocation() }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if allowed { manager.requestLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let new = locations.last else { return }
        // Solo se avisa si se ha movido más de 1 km: evita recargar el tiempo por nada.
        if let location, location.distance(from: new) < 1000 { return }
        location = new
        CLGeocoder().reverseGeocodeLocation(new) { [weak self] places, _ in
            DispatchQueue.main.async { self?.placeName = places?.first?.locality ?? places?.first?.name }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("MyDock: no se pudo obtener la ubicación: \(error.localizedDescription)")
    }

    static func openPrivacy() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
    }
}

// MARK: Ciudades (con el servicio de mapas de Apple)

enum CityLookup {
    private static var cache: [String: (CLLocationCoordinate2D, String)] = [:]

    /// Coordenadas y nombre oficial de una ciudad escrita a mano; nil si no existe.
    static func find(_ name: String) async -> (coordinate: CLLocationCoordinate2D, name: String)? {
        if let hit = await MainActor.run(body: { cache[name] }) { return hit }
        guard let place = try? await CLGeocoder().geocodeAddressString(name).first, let location = place.location else { return nil }
        let found = (location.coordinate, place.locality ?? place.name ?? name)
        await MainActor.run { cache[name] = found }
        return found
    }
}

// MARK: Tiempo (temperatura de Open-Meteo, sin clave)

final class WeatherModel: ObservableObject {
    @Published var temperature: Double?
    @Published var code = 0
    @Published var place = ""
    @Published var failed = false

    private struct Forecast: Decodable {
        struct Current: Decodable { let temperature_2m: Double; let weather_code: Int }
        let current: Current
    }

    func load(_ coordinate: CLLocationCoordinate2D, place: String, fahrenheit: Bool) async {
        do {
            var url = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            // Coordenadas redondeadas a ~1 km: Open-Meteo no necesita saber más.
            url.queryItems = [.init(name: "latitude", value: String(format: "%.2f", coordinate.latitude)),
                              .init(name: "longitude", value: String(format: "%.2f", coordinate.longitude)),
                              .init(name: "current", value: "temperature_2m,weather_code"),
                              .init(name: "temperature_unit", value: fahrenheit ? "fahrenheit" : "celsius")]
            let forecast = try JSONDecoder().decode(Forecast.self, from: try await URLSession.shared.data(from: url.url!).0)
            await MainActor.run {
                temperature = forecast.current.temperature_2m
                code = forecast.current.weather_code
                self.place = place
                failed = false
            }
        } catch {
            await MainActor.run { failed = true }
        }
    }

    func fail() { failed = true }

    /// Código WMO de Open-Meteo → SF Symbol.
    static func symbol(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1...3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 80...82: return "cloud.heavyrain.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

struct WeatherWidget: View {
    let id: UUID
    @ObservedObject var store: DockStore
    let compact: Bool
    @StateObject private var model = WeatherModel()
    @ObservedObject private var location = LocationProvider.shared

    var body: some View {
        let s = store.settings(id)
        let city = weatherCity(selected: s.selectedCity, cities: s.cities ?? [], locationAllowed: !location.refused)
        // Sin permiso de ubicación y sin ciudades: hay que añadir una.
        let needsCity = city == nil && location.refused
        let symbol = needsCity ? "location.slash" : model.failed ? "exclamationmark.icloud" : WeatherModel.symbol(model.code)
        let temp = needsCity ? "—" : model.temperature.map { "\(Int($0.rounded()))°" } ?? "--"
        let here = location.placeName ?? (location.location == nil ? t("Ubicación…") : t("Mi ubicación"))  // el nombre llega después
        let caption = needsCity ? t("Añade una ciudad") : model.failed ? t("Sin datos") : city == nil ? here : (model.place.isEmpty ? city! : model.place)
        Group {
            if compact {
                VStack(spacing: 1) {
                    Image(systemName: symbol).symbolRenderingMode(.multicolor).font(.body)
                    Text(temp).font(.caption2.weight(.semibold))
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: symbol).symbolRenderingMode(.multicolor).font(.title2)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(temp).font(.system(.title3, design: .rounded).weight(.semibold))
                        Text(caption).font(.caption).foregroundStyle(secondaryText)
                    }
                }
            }
        }
        .help(needsCity ? t("Sin permiso de ubicación: clic para añadir una ciudad") : t("Tiempo en %@ · abrir Tiempo", caption))
        .contentShape(Rectangle())
        .onTapGesture {
            if needsCity { SettingsWindow.shared.show(store, select: id) } else { openPath("/System/Applications/Weather.app") }
        }
        // Se recarga al cambiar de ciudad, de unidades o de ubicación, y cada 15 minutos.
        .task(id: "\(city ?? "aquí")|\(s.fahrenheit == true)|\(location.location.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" } ?? "-")") {
            while !Task.isCancelled {
                await update(city: city, fahrenheit: s.fahrenheit == true)
                try? await Task.sleep(for: .seconds(900))
            }
        }
    }

    private func update(city: String?, fahrenheit: Bool) async {
        if let city {
            guard let found = await CityLookup.find(city) else { return await MainActor.run { model.fail() } }
            await model.load(found.coordinate, place: found.name, fahrenheit: fahrenheit)
        } else {
            await MainActor.run { location.refresh() }
            guard let here = await MainActor.run(body: { location.location }) else { return }  // llegará y recargará
            await model.load(here.coordinate, place: "", fahrenheit: fahrenheit)
        }
    }
}
