#!/usr/bin/env python3
"""Comprueba las traducciones: cada idioma de Resources/*.lproj debe tener todas las frases t("…") del
código, ninguna de más, y los mismos huecos de datos (%@, %ld) que la frase original."""
import glob, json, re, subprocess, sys

keys = []
for f in sorted(glob.glob("Sources/MyDock/*.swift")):
    for m in re.finditer(r'\bt\("((?:[^"\\]|\\.)*)"', open(f, encoding="utf-8").read()):
        key = m.group(1).encode().decode("unicode_escape").encode("latin-1").decode("utf-8")  # \n → salto de línea
        if key not in keys:
            keys.append(key)

def holes(text):
    # %1$@ cuenta igual que %@: el orden puede cambiar al traducir, el tipo no.
    return sorted(re.sub(r"%\d+\$", "%", h) for h in re.findall(r"%(?:\d+\$)?(?:@|ld|%)", text))

errors = 0
for path in sorted(glob.glob("Resources/*.lproj/Localizable.strings")):
    lang = path.split("/")[1]
    out = subprocess.run(["plutil", "-convert", "json", "-o", "-", path], capture_output=True, text=True)
    if out.returncode:
        print(f"{lang}: no se puede leer: {out.stderr.strip()}"); errors += 1; continue
    table = json.loads(out.stdout)
    if lang == "es.lproj" and not table:
        continue  # el español es el idioma de las claves: no necesita traducción
    for k in keys:
        if k not in table:
            print(f"{lang}: falta «{k}»"); errors += 1
        elif holes(k) != holes(table[k]):
            print(f"{lang}: huecos distintos en «{k}» → «{table[k]}»"); errors += 1
    for k in table:
        if k not in keys:
            print(f"{lang}: sobra «{k}»"); errors += 1

print(f"Traducciones: {len(keys)} frases, {len(glob.glob('Resources/*.lproj'))} idiomas, {errors} errores")
sys.exit(1 if errors else 0)
