import AppKit

/// Ajustes del Dock de Apple antes de ocultarlo, para dejarlos tal cual (nil = la clave no existía).
struct AppleDockBackup: Codable, Equatable {
    var autohide: Bool
    var delay: Double?
}

/// Oculta el Dock de Apple con «ocultar automáticamente» y un retardo enorme: nunca llega a salir.
enum AppleDock {
    static let hiddenDelay = 1000.0
    private static let domain = "com.apple.dock" as CFString

    static func read() -> AppleDockBackup {
        AppleDockBackup(autohide: CFPreferencesCopyAppValue("autohide" as CFString, domain) as? Bool ?? false,
                        delay: CFPreferencesCopyAppValue("autohide-delay" as CFString, domain) as? Double)
    }

    static var isHidden: Bool { read() == AppleDockBackup(autohide: true, delay: hiddenDelay) }

    private static var watching = false

    /// Si MyDock se cierra de golpe (un fallo o «Forzar salida») no llega a devolver el Dock de Apple.
    /// Un proceso aparte vigila a MyDock y, si desaparece con el Dock aún oculto, lo deja como estaba.
    /// Tras un cierre normal el Dock ya está restaurado y el vigilante no hace nada.
    static func watchForCrash(restoring backup: AppleDockBackup) {
        guard !watching else { return }
        watching = true
        let delay = backup.delay.map { "/usr/bin/defaults write com.apple.dock autohide-delay -float \($0)" }
            ?? "/usr/bin/defaults delete com.apple.dock autohide-delay"
        // Rutas completas: nadie puede colar un programa con el mismo nombre.
        let script = """
        while kill -0 \(getpid()) 2>/dev/null; do /bin/sleep 2; done
        /bin/sleep 3
        /usr/bin/pgrep -x MyDock >/dev/null && exit 0  # otro MyDock (p. ej. una versión nueva) ya se encarga del Dock
        [ "$(/usr/bin/defaults read com.apple.dock autohide-delay 2>/dev/null)" = "\(Int(hiddenDelay))" ] || exit 0
        /usr/bin/defaults write com.apple.dock autohide -bool \(backup.autohide); \(delay); /usr/bin/killall Dock
        """
        let watcher = Process()
        watcher.executableURL = URL(fileURLWithPath: "/bin/sh")
        watcher.arguments = ["-c", script]
        try? watcher.run()
    }

    static func write(_ settings: AppleDockBackup) {
        CFPreferencesSetAppValue("autohide" as CFString, settings.autohide as NSNumber, domain)
        CFPreferencesSetAppValue("autohide-delay" as CFString, settings.delay.map { $0 as NSNumber }, domain)
        CFPreferencesAppSynchronize(domain)
        restart()
    }

    /// El Dock solo relee sus ajustes al reiniciarse (macOS lo vuelve a abrir solo).
    static func restart() {
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["Dock"]
        try? killall.run()
        killall.waitUntilExit()
    }
}

extension DockStore {
    /// Elige el dock: true = solo MyDock (Apple oculto), false = los dos.
    func setHideAppleDock(_ hide: Bool) {
        config.hideAppleDock = hide
        applyAppleDock()
    }

    /// Al arrancar y al cambiar la opción.
    func applyAppleDock() {
        guard config.hideAppleDock == true else { return restoreAppleDock() }
        // Si ya hay copia (p. ej. MyDock se cerró de golpe), los ajustes actuales son los nuestros: no se pisa.
        if config.appleDockBackup == nil { config.appleDockBackup = AppleDock.read() }
        if !AppleDock.isHidden { AppleDock.write(AppleDockBackup(autohide: true, delay: AppleDock.hiddenDelay)) }
        if let backup = config.appleDockBackup { AppleDock.watchForCrash(restoring: backup) }
    }

    /// Devuelve el Dock de Apple a como estaba (al elegir «los dos» y al cerrar MyDock).
    func restoreAppleDock() {
        guard let backup = config.appleDockBackup else { return }
        AppleDock.write(backup)
        config.appleDockBackup = nil
    }
}
