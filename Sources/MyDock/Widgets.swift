import AppKit
import Darwin
import SwiftUI

/// Envoltorio común: alto del dock, fondo con el color elegido y, en compacto, ancho de icono.
struct WidgetView: View {
    let item: DockItem
    @ObservedObject var store: DockStore
    let size: CGFloat
    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let s = item.settings ?? WidgetSettings()
        let compact = s.compact == true
        Group {
            switch item.widget ?? .clock {
            case .clock: ClockWidget(s: s, compact: compact)
            case .weather: WeatherWidget(id: item.id, store: store, compact: compact)
            case .music: MusicWidget(s: s, compact: compact)
            case .system: SystemWidget(s: s, compact: compact)
            case .events: EventsWidget(s: s, compact: compact)
            case .reminders: RemindersWidget(s: s, compact: compact, edge: store.popoverEdge)
            case .pomodoro: PomodoroWidget(s: s, compact: compact)
            case .note: NoteWidget(id: item.id, store: store, compact: compact)
            case .battery: BatteryWidget(compact: compact)
            case .controls: ControlsWidget(s: s, compact: compact)
            case .clipboard: ClipboardWidget(s: s, compact: compact, edge: store.popoverEdge)
            case .diskNet: DiskNetWidget(s: s, compact: compact)
            case .downloads: FilesWidget(kind: .downloads, s: s, compact: compact, edge: store.popoverEdge)
            case .screenshots: FilesWidget(kind: .screenshots, s: s, compact: compact, edge: store.popoverEdge)
            case .search: SearchWidget(compact: compact, edge: store.popoverEdge)
            case .colorPicker: ColorPickerWidget(s: s, compact: compact)
            }
        }
        .fixedSize(horizontal: true, vertical: false)  // cada widget a su ancho ideal: nada de textos con «…»
        // VoiceOver: música y volumen dejan sus botones aparte; los demás se leen como una sola frase.
        .accessibilityElement(children: [.music, .controls].contains(item.widget ?? .clock) ? .contain : .combine)
        .padding(.horizontal, compact ? 6 : 10)
        .frame(minWidth: compact ? size : nil, minHeight: size, maxHeight: size)
        .background((s.color?.color?.opacity(0.35)) ?? Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        // Pulso al hacer clic: confirma que el clic ha llegado (con «Reducir movimiento», solo se atenúa).
        .scaleEffect(pressed && !reduceMotion ? 0.93 : 1)
        .opacity(pressed && reduceMotion ? 0.6 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: pressed)
        .simultaneousGesture(TapGesture().onEnded {
            pressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { pressed = false }
        })
        .padding(.bottom, 6)  // alinea con los iconos, que llevan el punto debajo
    }
}

/// Icono + título (+ subtítulo); en compacto, icono encima y título corto debajo.
struct WidgetLabel: View {
    let symbol: String
    let title: String
    var subtitle: String? = nil
    let compact: Bool
    var tint: Color? = nil

    var body: some View {
        if compact {
            VStack(spacing: 1) {
                Image(systemName: symbol).font(.body).foregroundStyle(tint ?? .primary).accessibilityHidden(true)
                Text(title).font(.caption2.weight(.semibold)).monospacedDigit().lineLimit(1)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.title3).foregroundStyle(tint ?? .primary).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(.callout.weight(.semibold)).monospacedDigit().lineLimit(1)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(Color.primary.opacity(0.75)).lineLimit(1)
                    }
                }
                .frame(maxWidth: 150, alignment: .leading)
            }
        }
    }
}

let secondaryText = Color.primary.opacity(0.75)

// MARK: Reloj

struct ClockWidget: View {
    let s: WidgetSettings
    let compact: Bool

    var body: some View {
        TimelineView(.periodic(from: Calendar.current.dateInterval(of: .minute, for: .now)!.start, by: s.seconds == true ? 1 : 60)) { context in
            VStack(spacing: 0) {
                Text(context.date, format: timeFormat)
                    .font(.system(compact ? .callout : .title3, design: .rounded).weight(.semibold)).monospacedDigit()
                if !compact && s.hideDate != true {
                    Text(context.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                        .font(.caption).foregroundStyle(secondaryText)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { openPath("/System/Applications/Calendar.app") }
        .help(t("Abrir Calendario"))
    }

    private var timeFormat: Date.FormatStyle {
        let hour: Date.FormatStyle.Symbol.Hour = s.hour12 == true
            ? .defaultDigits(amPM: .abbreviated) : .twoDigits(amPM: .omitted)
        let base = Date.FormatStyle().hour(hour).minute(.twoDigits)
        return s.seconds == true ? base.second(.twoDigits) : base
    }
}

// MARK: Música (cualquier app que suene: Spotify, Música, navegadores…, vía MediaRemote)

final class MusicModel: ObservableObject {
    @Published var player: String?
    @Published var title = ""
    @Published var artist = ""
    @Published var playing = false
    private var bundleID: String?

    private static let fallbackPlayers = ["com.spotify.client", "com.apple.Music"]
    private static let mediaRemote = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)
    private typealias SendCommand = @convention(c) (UInt32, CFDictionary?) -> Bool
    private static let sendCommand = dlsym(mediaRemote, "MRMediaRemoteSendCommand").map { unsafeBitCast($0, to: SendCommand.self) }
    /// Desde macOS 15.4 MediaRemote solo da «ahora suena» a binarios de Apple; osascript lo es, nuestro proceso no.
    private static let nowPlayingScript = """
        ObjC.import('Foundation')
        $.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/MediaRemote.framework/').load
        function run() {
            const R = $.NSClassFromString('MRNowPlayingRequest'), item = R.localNowPlayingItem
            const client = R.localNowPlayingPlayerPath.client
            if (item.isNil() || client.isNil()) return ''
            const info = item.nowPlayingInfo, s = v => v.isNil() ? '' : ObjC.unwrap(v.description)
            const get = k => info.isNil() ? '' : s(info.objectForKey('kMRMediaRemoteNowPlayingInfo' + k))
            return [s(client.displayName), s(client.bundleIdentifier), get('Title'), get('Artist'), R.localIsPlaying ? '1' : '0'].join('\\n')
        }
        """
    private let queue = DispatchQueue(label: "mydock.music")
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        queue.async { [weak self] in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-l", "JavaScript", "-e", Self.nowPlayingScript]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice
            guard (try? task.run()) != nil else { return }
            let out = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            task.waitUntilExit()
            let parts = out.trimmingCharacters(in: .newlines).components(separatedBy: "\n")
            let found = parts.count == 5 && !parts[2].isEmpty ? parts : nil
            DispatchQueue.main.async {
                guard let self else { return }
                self.player = found?[0]
                self.bundleID = found?[1]
                self.title = found?[2] ?? ""
                self.artist = found?[3] ?? ""
                self.playing = found?[4] == "1"
            }
        }
    }

    /// Abre la app que suena; si no hay ninguna, el primer reproductor instalado (Spotify antes que Música).
    func openPlayer() {
        let ids = bundleID.map { [$0] } ?? Self.fallbackPlayers
        guard let url = ids.lazy.compactMap({ NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }).first else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }

    enum Command: UInt32 { case togglePlayPause = 2, next = 4, previous = 5 }

    func send(_ command: Command) {
        guard player != nil else { return }
        _ = Self.sendCommand?(command.rawValue, nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.refresh() }
    }
}

struct MusicWidget: View {
    let s: WidgetSettings
    let compact: Bool
    @StateObject private var model = MusicModel()

    var body: some View {
        HStack(spacing: 8) {
            if model.player == nil {
                WidgetLabel(symbol: "music.note", title: compact ? "—" : t("Sin música"), compact: compact, tint: secondaryText)
            } else if compact {
                Button { model.send(.togglePlayPause) } label: {
                    Image(systemName: model.playing ? "pause.fill" : "play.fill").font(.title3)
                }
                .accessibilityLabel(model.playing ? t("Pausar") : t("Reproducir"))
            } else {
                if s.hideControls != true {
                    Button { model.send(.previous) } label: { Image(systemName: "backward.fill") }
                        .accessibilityLabel(t("Anterior"))
                    Button { model.send(.togglePlayPause) } label: {
                        Image(systemName: model.playing ? "pause.fill" : "play.fill").font(.title3)
                    }
                    .accessibilityLabel(model.playing ? t("Pausar") : t("Reproducir"))
                    Button { model.send(.next) } label: { Image(systemName: "forward.fill") }
                        .accessibilityLabel(t("Siguiente"))
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.title).font(.callout.weight(.semibold)).lineLimit(1)
                    Text(model.artist).font(.caption).foregroundStyle(secondaryText).lineLimit(1)
                }
                .frame(maxWidth: 140, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onTapGesture { model.openPlayer() }  // los botones de reproducción tienen prioridad
        .help(model.player == nil ? t("Abrir reproductor") : t("%@ — %@ · abrir %@", model.title, model.artist, model.player!))
    }
}

// MARK: CPU y memoria

final class SystemMonitor: ObservableObject {
    @Published var cpu = 0.0
    @Published var memory = 0.0
    private var previous: host_cpu_load_info?
    private var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.update() }
    }

    func update() {
        if let load = Self.cpuLoad() {
            if let previous { cpu = Self.usage(from: previous, to: load) }
            previous = load
        }
        memory = Self.memoryUsage()
    }

    static func cpuLoad() -> host_cpu_load_info? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info : nil
    }

    /// Fracción de tiempo ocupado entre dos lecturas (ticks: user, system, idle, nice).
    static func usage(from a: host_cpu_load_info, to b: host_cpu_load_info) -> Double {
        let user = Double(b.cpu_ticks.0 &- a.cpu_ticks.0)
        let system = Double(b.cpu_ticks.1 &- a.cpu_ticks.1)
        let idle = Double(b.cpu_ticks.2 &- a.cpu_ticks.2)
        let nice = Double(b.cpu_ticks.3 &- a.cpu_ticks.3)
        let total = user + system + idle + nice
        return total > 0 ? (user + system + nice) / total : 0
    }

    // shortcut: activa + wired + comprimida se acerca a «Memoria usada» del Monitor de Actividad sin ser idéntica.
    static func memoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let pages = UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return Double(pages) * Double(vm_kernel_page_size) / Double(ProcessInfo.processInfo.physicalMemory)
    }
}

struct SystemWidget: View {
    let s: WidgetSettings
    let compact: Bool
    @StateObject private var monitor = SystemMonitor()

    var body: some View {
        Group {
            if compact {
                VStack(spacing: 1) {
                    Image(systemName: "cpu").font(.body)
                    Text("\(Int(monitor.cpu * 100))%").font(.caption2.weight(.semibold)).monospacedDigit()
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if s.hideCPU != true { Meter(label: "CPU", value: monitor.cpu) }
                    if s.hideRAM != true { Meter(label: "RAM", value: monitor.memory) }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { openPath("/System/Applications/Utilities/Activity Monitor.app") }
        .help(t("CPU %ld%% · RAM %ld%% · abrir Monitor de Actividad", Int(monitor.cpu * 100), Int(monitor.memory * 100)))
    }
}

/// Barra con etiqueta y porcentaje (CPU, RAM, disco…).
struct Meter: View {
    let label: String
    let value: Double
    var text: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            Text(label).font(.caption2.weight(.semibold)).frame(width: 30, alignment: .leading)
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.15))
                Capsule().fill(value > 0.85 ? Color.red : value > 0.6 ? Color.orange : Color.green)
                    .frame(width: 60 * min(max(value, 0), 1))
            }
            .frame(width: 60, height: 6)
            Text(text ?? "\(Int(value * 100))%").font(.caption2).monospacedDigit().frame(minWidth: 30, alignment: .trailing)
        }
    }
}
