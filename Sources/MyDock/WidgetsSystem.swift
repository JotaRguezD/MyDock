import AppKit
import Darwin
import IOKit.ps
import SwiftUI

// MARK: Batería

final class BatteryModel: ObservableObject {
    @Published var percent: Int?
    @Published var charging = false
    private var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.update() }
    }

    func update() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return }
        for source in sources {
            guard let d = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  d[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = d[kIOPSCurrentCapacityKey] as? Int, let max = d[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
            percent = current * 100 / max
            charging = d[kIOPSIsChargingKey] as? Bool ?? false
            return
        }
        percent = nil
    }

    static func symbol(_ percent: Int, charging: Bool) -> String {
        if charging { return "battery.100.bolt" }
        switch percent {
        case 88...: return "battery.100"
        case 63..<88: return "battery.75"
        case 38..<63: return "battery.50"
        case 13..<38: return "battery.25"
        default: return "battery.0"
        }
    }
}

struct BatteryWidget: View {
    let compact: Bool
    @StateObject private var model = BatteryModel()

    var body: some View {
        Group {
            if let p = model.percent {
                WidgetLabel(symbol: BatteryModel.symbol(p, charging: model.charging), title: "\(p)%",
                            subtitle: model.charging ? t("Cargando") : t("Batería"), compact: compact,
                            tint: p <= 20 && !model.charging ? .red : nil)
            } else {
                WidgetLabel(symbol: "powerplug", title: compact ? "AC" : t("Sin batería"), subtitle: t("Conectado a corriente"), compact: compact)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!) }
        .help(t("Abrir ajustes de Batería"))
    }
}

// MARK: Controles rápidos (volumen)

final class ControlsModel: ObservableObject {
    @Published var volume = 50.0
    @Published var muted = false
    private let queue = DispatchQueue(label: "mydock.controls")
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.refresh() }
    }

    private func run(_ source: String) -> NSAppleEventDescriptor? { NSAppleScript(source: source)?.executeAndReturnError(nil) }

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let volume = self.run("output volume of (get volume settings)")?.int32Value
            let muted = self.run("output muted of (get volume settings)")?.booleanValue
            DispatchQueue.main.async {
                if let volume { self.volume = Double(volume) }
                if let muted { self.muted = muted }
            }
        }
    }

    func setVolume(_ value: Double) {
        volume = value
        queue.async { [weak self] in _ = self?.run("set volume output volume \(Int(value))") }
    }

    func toggleMute() {
        muted.toggle()
        let muted = muted
        queue.async { [weak self] in _ = self?.run("set volume output muted \(muted)") }
    }
}

struct ControlsWidget: View {
    let s: WidgetSettings
    let compact: Bool
    @StateObject private var model = ControlsModel()

    var body: some View {
        HStack(spacing: 8) {
            Button { model.toggleMute() } label: {
                Image(systemName: model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill").font(.title3)
            }
            .help(model.muted ? t("Activar sonido") : t("Silenciar"))
            .accessibilityLabel(model.muted ? t("Activar sonido") : t("Silenciar"))
            if !compact {
                Slider(value: Binding(get: { model.volume }, set: { model.setVolume($0) }), in: 0...100)
                    .frame(width: 70)
                    .controlSize(.small)
                    .accessibilityLabel(t("Volumen"))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: Portapapeles

/// Historial compartido por todos los widgets de portapapeles. Solo en memoria: no se guarda en disco.
final class ClipboardModel: ObservableObject {
    static let shared = ClipboardModel()
    @Published private(set) var history: [String] = []
    private var lastChange = NSPasteboard.general.changeCount
    private var timer: Timer?
    // Gestores de contraseñas marcan así lo que copian: no se guarda.
    private static let privateTypes: Set<String> = ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType",
                                                     "com.agilebits.onepassword", "org.nspasteboard.AutoGeneratedType"]

    private init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.check() }
    }

    func check() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChange else { return }
        lastChange = pb.changeCount
        let types = Set((pb.types ?? []).map(\.rawValue))
        guard types.isDisjoint(with: Self.privateTypes), let text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        history = clipboardHistory(history, adding: text)
    }

    func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func clear() { history = [] }
}

/// Lo nuevo arriba, sin duplicados, como mucho 20.
func clipboardHistory(_ history: [String], adding text: String) -> [String] {
    Array(([text] + history.filter { $0 != text }).prefix(20))
}

struct ClipboardWidget: View {
    let s: WidgetSettings
    let compact: Bool
    let edge: Edge
    @ObservedObject private var model = ClipboardModel.shared
    @State private var open = false

    var body: some View {
        let latest = model.history.first.map { $0.replacingOccurrences(of: "\n", with: " ") }
        WidgetLabel(symbol: "doc.on.clipboard", title: compact ? "\(model.history.count)" : t("Portapapeles"),
                    subtitle: latest ?? t("Vacío"), compact: compact)
            .contentShape(Rectangle())
            .onTapGesture { open.toggle() }
            .help(t("Historial del portapapeles"))
            .popover(isPresented: $open, arrowEdge: edge) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(t("Portapapeles")).font(.headline)
                        Spacer()
                        Button(t("Borrar")) { model.clear() }.disabled(model.history.isEmpty)
                    }
                    if model.history.isEmpty {
                        Text(t("Copia algo y aparecerá aquí.")).foregroundStyle(.secondary)
                    }
                    ForEach(model.history.prefix(s.itemCount ?? 10), id: \.self) { text in
                        Button {
                            model.copy(text)
                            open = false
                        } label: {
                            Text(text.replacingOccurrences(of: "\n", with: " ")).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 3)
                        .help(t("Copiar de nuevo"))
                    }
                }
                .padding(12)
                .frame(width: 300)
            }
    }
}

// MARK: Disco y red

final class DiskNetModel: ObservableObject {
    @Published var diskUsed = 0.0
    @Published var diskFree = ""
    @Published var down = ""
    @Published var up = ""
    private var last: (bytesIn: UInt64, bytesOut: UInt64, at: Date)?
    private var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.update() }
    }

    func update() {
        if let v = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
           let total = v.volumeTotalCapacity, let free = v.volumeAvailableCapacityForImportantUsage, total > 0 {
            diskUsed = 1 - Double(free) / Double(total)
            diskFree = t("%@ libres", ByteCountFormatter.string(fromByteCount: free, countStyle: .file))
        }
        let now = Self.networkBytes()
        if let last {
            let seconds = max(Date().timeIntervalSince(last.at), 0.1)
            down = Self.rate(now.bytesIn, last.bytesIn, seconds)
            up = Self.rate(now.bytesOut, last.bytesOut, seconds)
        }
        last = (now.bytesIn, now.bytesOut, Date())
    }

    // shortcut: los contadores de if_data son de 32 bits y dan la vuelta a los 4 GB; ese intervalo se descarta (0).
    static func rate(_ now: UInt64, _ before: UInt64, _ seconds: TimeInterval) -> String {
        let bytes = now >= before ? Double(now - before) / seconds : 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .binary) + "/s"
    }

    /// Bytes recibidos y enviados por todas las interfaces de red salvo la de bucle local.
    static func networkBytes() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let first = addrs else { return (0, 0) }
        defer { freeifaddrs(addrs) }
        var bytesIn: UInt64 = 0, bytesOut: UInt64 = 0
        for p in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let ifa = p.pointee
            guard let addr = ifa.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK),
                  ifa.ifa_flags & UInt32(IFF_LOOPBACK) == 0, let data = ifa.ifa_data else { continue }
            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            bytesIn += UInt64(stats.ifi_ibytes)
            bytesOut += UInt64(stats.ifi_obytes)
        }
        return (bytesIn, bytesOut)
    }
}

struct DiskNetWidget: View {
    let s: WidgetSettings
    let compact: Bool
    @StateObject private var model = DiskNetModel()

    var body: some View {
        Group {
            if compact {
                VStack(spacing: 1) {
                    Image(systemName: "arrow.down").font(.caption)
                    Text(model.down).font(.system(size: 9, weight: .semibold)).monospacedDigit()
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if s.hideDisk != true { Meter(label: t("Disco"), value: model.diskUsed, text: model.diskFree) }
                    if s.hideNetwork != true {
                        Text("↓ \(model.down)   ↑ \(model.up)").font(.caption2).monospacedDigit()
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { openPath("/System/Applications/Utilities/Activity Monitor.app") }
        .help(t("Bajada %@ · subida %@ · %@", model.down, model.up, model.diskFree))
    }
}

// MARK: Selector de color

struct ColorPickerWidget: View {
    let s: WidgetSettings
    let compact: Bool
    @State private var picked: NSColor?

    var body: some View {
        let code = picked.map { colorCode($0, rgb: s.rgbFormat == true) }
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(picked.map { Color(nsColor: $0) } ?? Color.clear)
                Circle().strokeBorder(.primary.opacity(0.4))
                if picked == nil { Image(systemName: "eyedropper").font(.callout) }
            }
            .frame(width: 24, height: 24)
            if !compact {
                VStack(alignment: .leading, spacing: 0) {
                    Text(code ?? t("Coger color")).font(.callout.weight(.semibold)).monospacedDigit()
                    Text(code == nil ? t("Clic y elige en pantalla") : t("Copiado")).font(.caption).foregroundStyle(secondaryText)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            NSColorSampler().show { color in
                guard let color else { return }
                picked = color
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(colorCode(color, rgb: s.rgbFormat == true), forType: .string)
            }
        }
        .help(code.map { t("%@ copiado · clic para coger otro", $0) } ?? t("Coger un color de la pantalla"))
    }
}

func colorCode(_ color: NSColor, rgb: Bool) -> String {
    let c = color.usingColorSpace(.sRGB) ?? color
    let r = Int((c.redComponent * 255).rounded()), g = Int((c.greenComponent * 255).rounded()), b = Int((c.blueComponent * 255).rounded())
    return rgb ? "rgb(\(r), \(g), \(b))" : String(format: "#%02X%02X%02X", r, g, b)
}
