import AppKit

/// Texto traducido al idioma de MyDock. La clave es la frase en español; si lleva datos, al estilo
/// de String(format:): %@ para textos y %d para números (en otro orden: %1$@, %2$d…).
/// Todas las frases de la interfaz pasan por aquí para poder extraerlas y traducirlas (Resources/*.lproj).
func t(_ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.main.localizedString(forKey: key, value: key, table: nil)
    return args.isEmpty ? format : String(format: format, locale: Locale.current, arguments: args)
}

/// Idioma de MyDock: el del sistema o uno elegido en Ajustes. Se guarda como «AppleLanguages» solo para
/// MyDock (lo que hace macOS en Ajustes del Sistema › Idioma › Aplicaciones) y se aplica al reiniciar.
enum AppLanguage {
    /// Código y nombre en su propio idioma (así cada cual reconoce el suyo).
    static let all: [(code: String, name: String)] = [
        ("es", "Español"), ("en", "English"), ("ca", "Català"), ("gl", "Galego"), ("eu", "Euskara"),
        ("fr", "Français"), ("de", "Deutsch"), ("it", "Italiano"), ("pt", "Português"),
        ("nb", "Norsk"), ("da", "Dansk"), ("fi", "Suomi"),
        ("ja", "日本語"), ("zh-Hans", "简体中文"), ("ko", "한국어"), ("hi", "हिन्दी"), ("ar", "العربية"),
    ]

    /// nil = el del sistema.
    static var chosen: String? {
        let domain = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        return (domain?["AppleLanguages"] as? [String])?.first
    }

    static func choose(_ code: String?) {
        guard code != chosen else { return }
        if let code { UserDefaults.standard.set([code], forKey: "AppleLanguages") } else { UserDefaults.standard.removeObject(forKey: "AppleLanguages") }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = t("El idioma cambiará al reiniciar MyDock.")
            alert.addButton(withTitle: t("Reiniciar ahora"))
            alert.addButton(withTitle: t("Más tarde"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            // Se vuelve a abrir desde un proceso aparte, un segundo después de cerrarse.
            let relaunch = Process()
            relaunch.executableURL = URL(fileURLWithPath: "/bin/sh")
            relaunch.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", Bundle.main.bundlePath]
            try? relaunch.run()
            NSApp.terminate(nil)
        }
    }
}
