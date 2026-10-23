#!/bin/bash
# Compila MyDock para Intel y Apple Silicon y lo empaqueta como build/MyDock.app
#   ./build.sh           → solo compila
#   ./build.sh install   → además la instala en /Applications y la abre
#   ./build.sh dmg       → además crea dist/MyDock-<versión>.dmg para publicar
set -euo pipefail
cd "$(dirname "$0")"

python3 check-translations.py  # que ningún idioma se quede con frases sin traducir

for arch in x86_64 arm64; do
    swift build -c release --triple "$arch-apple-macosx14.0"
done
# Las comprobaciones se ejecutan con el binario del procesador de este Mac.
".build/$(uname -m)-apple-macosx/release/MyDock" --selftest

APP=build/MyDock.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp icon/AppIcon.icns "$APP/Contents/Resources/"  # se regenera con: swift icon/make-icon.swift
cp -R Resources/*.lproj "$APP/Contents/Resources/"  # traducciones (inglés = idioma de reserva)
lipo -create .build/x86_64-apple-macosx/release/MyDock .build/arm64-apple-macosx/release/MyDock \
     -output "$APP/Contents/MacOS/MyDock"
cp Info.plist "$APP/Contents/"

# Firma estable si existe el certificado (./create-signing-cert.sh): macOS recuerda los permisos entre versiones.
if security find-certificate -c "MyDock Local Signing" >/dev/null 2>&1; then
    SIGN="MyDock Local Signing"
else
    echo "Aviso: firma provisional; macOS volverá a pedir los permisos. Ejecuta ./create-signing-cert.sh"
    SIGN="-"
fi
# Runtime reforzado: nadie puede inyectar código en MyDock para heredar sus permisos.
codesign --force --options runtime --entitlements MyDock.entitlements --sign "$SIGN" "$APP"
echo "Listo: $APP ($(lipo -archs "$APP/Contents/MacOS/MyDock"))"

case "${1:-}" in
install)
    # /Applications es una ruta fija: la que usa «Abrir al iniciar sesión».
    # Cierre ordenado (devuelve el Dock de Apple si estaba oculto) y espera a que termine.
    osascript -e 'quit app "MyDock"' 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -x MyDock >/dev/null || break; sleep 0.5; done
    pkill -x MyDock || true
    sleep 3  # que el Dock de Apple termine de reiniciarse antes de que la nueva lo vuelva a ocultar
    rm -rf /Applications/MyDock.app
    cp -R "$APP" /Applications/
    open /Applications/MyDock.app
    echo "Instalada en /Applications/MyDock.app"
    ;;
dmg)
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)
    DMG="dist/MyDock-$VERSION.dmg"
    STAGE=$(mktemp -d)
    trap 'rm -rf "$STAGE"' EXIT
    cp -R "$APP" "$STAGE/"
    ln -s /Applications "$STAGE/Applications"  # para instalar arrastrando la app encima
    mkdir -p dist
    rm -f "$DMG"
    hdiutil create -volname "MyDock" -srcfolder "$STAGE" -format UDZO -ov "$DMG" >/dev/null
    # Huella para publicar junto al .dmg: quien lo descarga puede comprobar que es el auténtico.
    (cd dist && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
    echo "DMG: $DMG"
    echo "SHA-256: $(cut -d' ' -f1 "$DMG.sha256")"
    ;;
esac
