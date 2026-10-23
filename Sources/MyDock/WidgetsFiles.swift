import AppKit
import SwiftUI

// MARK: Descargas y Capturas

enum FilesKind { case downloads, screenshots }

final class FilesModel: ObservableObject {
    @Published private(set) var files: [URL] = []
    let folder: URL
    private let kind: FilesKind
    private var timer: Timer?

    init(_ kind: FilesKind) {
        self.kind = kind
        folder = kind == .downloads
            ? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
            : Self.screenshotFolder()
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.update() }
    }

    /// Donde guarda macOS las capturas: lo elegido en Captura de pantalla › Opciones, o el Escritorio.
    static func screenshotFolder() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let custom = (CFPreferencesCopyAppValue("location" as CFString, "com.apple.screencapture" as CFString) as? String)
            .map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
        return custom ?? home.appendingPathComponent("Desktop")
    }

    func update() {
        let keys: [URLResourceKey] = [.addedToDirectoryDateKey, .creationDateKey, .isHiddenKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys,
                                                                      options: [.skipsHiddenFiles]) else { return }
        let wanted = kind == .downloads ? urls.filter { $0.pathExtension != "download" } : urls.filter(Self.isScreenshot)
        func date(_ u: URL) -> Date {
            let v = try? u.resourceValues(forKeys: Set(keys))
            return v?.addedToDirectoryDate ?? v?.creationDate ?? .distantPast
        }
        let newest = Array(wanted.sorted { date($0) > date($1) }.prefix(20))
        if newest != files { files = newest }
    }

    /// Spotlight marca las capturas con kMDItemIsScreenCapture, sea cual sea su nombre o idioma.
    static func isScreenshot(_ url: URL) -> Bool {
        guard let item = MDItemCreateWithURL(nil, url as CFURL) else { return false }
        return (MDItemCopyAttribute(item, "kMDItemIsScreenCapture" as CFString) as? Bool) == true
    }
}

struct FilesWidget: View {
    let kind: FilesKind
    let s: WidgetSettings
    let compact: Bool
    let edge: Edge
    @StateObject private var model: FilesModel
    @State private var open = false

    init(kind: FilesKind, s: WidgetSettings, compact: Bool, edge: Edge) {
        self.kind = kind
        self.s = s
        self.compact = compact
        self.edge = edge
        _model = StateObject(wrappedValue: FilesModel(kind))
    }

    var body: some View {
        let title = kind == .downloads ? t("Descargas") : t("Capturas")
        let symbol = kind == .downloads ? "arrow.down.circle" : "camera.viewfinder"
        WidgetLabel(symbol: symbol, title: compact ? "\(model.files.count)" : title,
                    subtitle: model.files.first?.lastPathComponent ?? t("Vacío"), compact: compact, tint: .accentColor)
            .contentShape(Rectangle())
            .onTapGesture { open.toggle() }
            .help(t("Últimos archivos de %@", title))
            .popover(isPresented: $open, arrowEdge: edge) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title).font(.headline)
                        Spacer()
                        Button(t("Abrir carpeta")) { open = false; NSWorkspace.shared.open(model.folder) }
                    }
                    if model.files.isEmpty { Text(t("No hay archivos.")).foregroundStyle(.secondary) }
                    ForEach(model.files.prefix(s.itemCount ?? 10), id: \.self) { url in
                        HStack(spacing: 8) {
                            Image(nsImage: kind == .screenshots ? (NSImage(contentsOf: url) ?? NSWorkspace.shared.icon(forFile: url.path))
                                                                : NSWorkspace.shared.icon(forFile: url.path))
                                .resizable().aspectRatio(contentMode: .fit).frame(width: 32, height: 32)
                            Text(url.lastPathComponent).lineLimit(1)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { open = false; NSWorkspace.shared.open(url) }
                        .onDrag { NSItemProvider(contentsOf: url) ?? NSItemProvider() }  // arrastrable a otras apps
                        .contextMenu {
                            Button(t("Mostrar en Finder")) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                        }
                        .help(t("Clic para abrir · arrastra para usarlo en otra app"))
                    }
                }
                .padding(12)
                .frame(width: 320)
            }
    }
}

// MARK: Buscar (Spotlight)

final class SearchModel: ObservableObject {
    @Published private(set) var results: [URL] = []
    private let query = NSMetadataQuery()

    init() {
        query.searchScopes = [NSMetadataQueryLocalComputerScope]
        query.sortDescriptors = [NSSortDescriptor(key: "kMDItemLastUsedDate", ascending: false)]
        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: .main) { [weak self] _ in
            self?.collect()
        }
    }

    func search(_ text: String) {
        query.stop()
        let text = text.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else { results = []; return }
        query.predicate = NSPredicate(format: "%K LIKE[cd] %@", NSMetadataItemFSNameKey, "*\(text)*")
        query.start()
    }

    private func collect() {
        query.disableUpdates()
        defer { query.enableUpdates() }
        let urls = (0..<min(query.resultCount, 200)).compactMap {
            (query.result(at: $0) as? NSMetadataItem)?.value(forAttribute: NSMetadataItemPathKey) as? String
        }.map { URL(fileURLWithPath: $0) }
        // Las apps primero, como en Spotlight.
        results = Array((urls.filter { $0.pathExtension == "app" } + urls.filter { $0.pathExtension != "app" }).prefix(12))
    }
}

struct SearchWidget: View {
    let compact: Bool
    let edge: Edge
    @StateObject private var model = SearchModel()
    @State private var open = false
    @State private var text = ""

    var body: some View {
        WidgetLabel(symbol: "magnifyingglass", title: t("Buscar"), subtitle: compact ? nil : t("Apps y archivos"), compact: compact)
            .contentShape(Rectangle())
            .onTapGesture {
                NSApp.activate(ignoringOtherApps: true)  // para poder escribir en el popover
                open.toggle()
            }
            .help(t("Buscar apps y archivos"))
            .popover(isPresented: $open, arrowEdge: edge) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField(t("Buscar apps y archivos"), text: $text)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: text) { model.search($0) }
                        .onSubmit { if let first = model.results.first { launch(first) } }
                    ForEach(model.results, id: \.self) { url in
                        HStack(spacing: 8) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable().frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(FileManager.default.displayName(atPath: url.path)).lineLimit(1)
                                Text(url.deletingLastPathComponent().path).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { launch(url) }
                    }
                }
                .padding(12)
                .frame(width: 360)
            }
    }

    private func launch(_ url: URL) {
        open = false
        text = ""
        openPath(url.path)
    }
}
