import AppKit
import SwiftUI

/// La Papelera, al final del dock como en el de Apple. macOS protege su carpeta, así que su estado
/// (vacía o con algo) y vaciarla se le piden a Finder (permiso de Automatización, una sola vez).
final class TrashModel: ObservableObject {
    static let shared = TrashModel()
    /// Clave fija para saber dónde está en el dock (para soltarle cosas encima).
    static let id = UUID(uuidString: "00000000-0000-0000-0000-00000000DEAD")!
    @Published private(set) var full = false
    private let queue = DispatchQueue(label: "mydock.trash")
    private var timer: Timer?

    private init() {
        refresh()
        // Lo que se tira desde Finder no avisa a MyDock: se pregunta a menudo (es una consulta muy ligera).
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        queue.async { [weak self] in
            let count = NSAppleScript(source: "tell application \"Finder\" to count items of trash")?.executeAndReturnError(nil).int32Value ?? 0
            DispatchQueue.main.async { if self?.full != (count > 0) { self?.full = count > 0 } }  // sin redibujar si no cambia
        }
    }

    func open() { openPath(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").path) }

    /// Archivos soltados encima: a la Papelera (se pueden recuperar), como hace el Dock de Apple.
    func moveToTrash(_ urls: [URL]) {
        for url in urls {
            do { try FileManager.default.trashItem(at: url, resultingItemURL: nil) } catch {
                NSLog("MyDock: no se pudo mover a la Papelera \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        refresh()
    }

    /// Borra para siempre: siempre se pide confirmación antes.
    func empty() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = t("¿Vaciar la papelera?")
            alert.informativeText = t("Los archivos de la papelera se borrarán para siempre. No se puede deshacer.")
            alert.addButton(withTitle: t("Vaciar"))
            alert.addButton(withTitle: t("Cancelar"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            self.queue.async { [weak self] in
                _ = NSAppleScript(source: "tell application \"Finder\" to empty trash")?.executeAndReturnError(nil)
                self?.refresh()
            }
        }
    }
}

struct TrashView: View {
    let size: CGFloat
    let edge: DockPosition
    @ObservedObject private var trash = TrashModel.shared

    var body: some View {
        // El mismo icono que las apps: crece al pasar el ratón y da un salto al hacer clic.
        AppIconView(path: "", size: size, running: false, edge: edge,
                    image: NSImage(named: trash.full ? NSImage.trashFullName : NSImage.trashEmptyName),
                    label: t("Papelera"), value: trash.full ? t("Con elementos") : t("Vacía"),
                    action: { trash.open() })
            .rightClickMenu(edge: edge) {
                nsMenu([.item(t("Abrir")) { trash.open() }, .divider,
                        .item(t("Vaciar papelera…"), trash.full ? { trash.empty() } : nil)])
            }
            .background(GeometryReader { g in
                Color.clear.preference(key: ItemFrames.self, value: [TrashModel.id: g.frame(in: .global)])
            })
    }
}
