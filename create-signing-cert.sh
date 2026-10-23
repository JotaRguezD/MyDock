#!/bin/bash
# Crea (una sola vez) un certificado propio de firma de código en el llavero de inicio de sesión.
# Con una firma estable, macOS recuerda los permisos de MyDock entre versiones;
# con la firma provisional (ad hoc) los vuelve a pedir tras cada compilación.
# El certificado no se marca como de confianza: solo sirve para firmar MyDock.
set -euo pipefail
NAME="MyDock Local Signing"

if security find-certificate -c "$NAME" >/dev/null 2>&1; then
    echo "Ya existe el certificado «$NAME»."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=$NAME" \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null
# Contraseña de un solo uso para el .p12 temporal; el archivo se borra al acabar.
PASS=$(openssl rand -hex 16)
# Cifrado antiguo: el de OpenSSL 3 por defecto no lo lee «security import».
openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -out "$TMP/id.p12" -name "$NAME" \
    -passout "pass:$PASS" -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1
security import "$TMP/id.p12" -k "$HOME/Library/Keychains/login.keychain-db" -P "$PASS" -T /usr/bin/codesign
echo "Creado el certificado «$NAME». Para borrarlo: Acceso a Llaveros › Inicio de sesión › Mis certificados."
