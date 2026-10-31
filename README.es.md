<p align="center"><img src="icon/AppIcon.png" width="160" alt="Icono de MyDock"></p>

<p align="center"><a href="README.md">English</a> · <a href="README.es.md">Español</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt.md">Português</a></p>

# MyDock

Un dock para macOS con widgets, separadores y grupos de apps. Funciona junto al Dock de Apple o en su lugar, sin tocar el sistema.

## Descarga e instalación

1. Descarga el archivo **`MyDock-x.y.z.dmg`** de la [última versión](https://github.com/JotaRguezD/MyDock/releases/latest).
2. Abre el `.dmg` y arrastra **MyDock** a la carpeta **Aplicaciones**.
3. Abre MyDock desde Aplicaciones.

### La primera vez que la abres

MyDock no está firmada por un desarrollador verificado por Apple, así que macOS no la abrirá directamente la primera vez:

- **macOS 15 Sequoia o posterior**: al abrirla verás un aviso; pulsa **Aceptar**. Ve a **Ajustes del Sistema › Privacidad y seguridad**, baja hasta el final y pulsa **Abrir igualmente** junto a MyDock. Confirma con tu contraseña.
- **macOS 14 Sonoma**: haz clic derecho sobre MyDock en Aplicaciones, elige **Abrir** y confirma.

Solo hay que hacerlo una vez. Las actualizaciones se instalan igual: descarga el nuevo `.dmg` y arrastra MyDock a Aplicaciones para sustituir la anterior. Tus ajustes y permisos se conservan.

### Requisitos

- macOS 14 Sonoma o posterior.
- Cualquier Mac: con procesador Intel o con chip Apple (M1, M2, M3…).

## Qué hace

### Apps, carpetas y grupos

- **Ancla apps y carpetas** arrastrándolas desde Finder; al hacer clic en una carpeta se abre en Finder. Para cambiarlas de sitio, arrastra los iconos dentro del dock.
- **Apps abiertas**: las que no tienes ancladas aparecen solas, después de las ancladas, como en el Dock de Apple. Un punto bajo el icono indica que la app está abierta.
- **Grupos**: varias apps en un solo icono; al hacer clic se abre una ventanita con todas. Suelta una app encima del grupo para meterla.
- **Separadores y espacios**: todos los que quieras, donde quieras.
- **Papelera**, al final del dock como en el de Apple: clic para abrirla, suelta archivos encima para moverlos a la Papelera o un icono del dock para quitarlo, y clic derecho › **Vaciar papelera…** (siempre pide confirmación). Se puede ocultar en Ajustes.
- **Las apps y los widgets van en zonas separadas**: primero las apps, después los widgets, con un separador entre ambos.
- **Animaciones**: al abrir una app, su icono rebota hasta que termina de abrirse; los widgets hacen un pequeño pulso al pulsarlos.

### Menús del clic derecho

Los menús se abren justo encima del dock con una flechita que apunta al icono, como en el Dock de Apple, así que nunca tapan los iconos de al lado: haz clic derecho en otro icono y su menú se abre al momento. Vale para apps, widgets, grupos, la Papelera y el fondo del dock.

| App | Opciones |
|---|---|
| Abierta | Sus ventanas · sus acciones principales, de su menú Archivo (Nueva ventana, Nuevo evento…) · **Opciones** › · Ocultar · **Salir** · Forzar salida |
| Anclada, cerrada | Mostrar en Finder · Mover a grupo · Quitar del dock · Salir (en gris) |
| Dentro de un grupo, cerrada | Sacar al dock · Quitar del grupo · Salir (en gris) |

En **Opciones**, una app abierta tiene lo mismo que cuando está cerrada (o **Mantener en el dock** si no está anclada). Las ventanas y las acciones necesitan el permiso de Accesibilidad. Cada dock enseña su propio menú: el clic derecho en el Dock de Apple sigue abriendo el de Apple.

### 16 widgets

| Básicos | Productividad | Sistema | Utilidades |
|---|---|---|---|
| Reloj y fecha | Próximos eventos | Batería | Descargas |
| Tiempo | Recordatorios | Volumen | Capturas |
| Música | Pomodoro | Portapapeles | Buscar |
| CPU y memoria | Nota rápida | Disco y red | Selector de color |

- **Reloj y fecha**: al hacer clic abre Calendario.
- **Tiempo**: el de tu ubicación o el de tus ciudades guardadas; clic derecho › **Ciudad** para cambiar rápidamente. Al hacer clic abre la app Tiempo.
- **Música**: la canción que suena en cualquier app (Spotify, Música, un navegador…), con botones de anterior, reproducir/pausar y siguiente. Al hacer clic abre la app que suena.
- **CPU y memoria**, **Disco y red**: uso en tiempo real; al hacer clic abren el Monitor de Actividad.
- **Próximos eventos**: tu siguiente evento del Calendario y cuánto falta.
- **Recordatorios**: tus tareas pendientes; puedes marcarlas como hechas desde el propio dock.
- **Pomodoro**: temporizador de concentración y descanso, con aviso sonoro.
- **Nota rápida**: un texto que escribes y se queda guardado en el dock.
- **Batería**: porcentaje y si está cargando.
- **Volumen**: silenciar y barra de volumen.
- **Portapapeles**: lo último que has copiado, para volver a copiarlo con un clic.
- **Descargas** y **Capturas**: tus últimos archivos, para abrirlos o arrastrarlos a otra app.
- **Buscar**: encuentra apps y archivos sin abrir Spotlight.
- **Selector de color**: coge un color de cualquier parte de la pantalla y copia su código.

Cada widget solo puede estar una vez en el dock.

### Personalización

- **Cada widget**: versión **compacta** (del tamaño de un icono) o **amplia**, **color de fondo** y sus propias opciones: formato de 12 o 24 horas, segundos, ciudades del tiempo, °C o °F, minutos del Pomodoro, cuántos elementos mostrar…
- **Posición**: abajo, arriba, a la izquierda o a la derecha. Arriba, bajo la barra de menús, puede convivir con el Dock de Apple solo con tus widgets.
- **Tamaño de los iconos**: pequeño, mediano o grande.
- **Ocultar automáticamente**: el dock se esconde y vuelve al llevar el ratón al borde de la pantalla.
- **Qué dock usar**: solo MyDock, MyDock junto al de Apple, o volver al de Apple.
- **Ajustar ventanas al dock** (opcional): las ventanas maximizadas se paran donde empieza MyDock, como con el Dock de Apple. Si el dock se oculta automáticamente, las ventanas ocupan toda la pantalla. Con una app a pantalla completa, MyDock se esconde y aparece al llevar el ratón al borde.
- **Abrir al iniciar sesión**.
- **Modo claro u oscuro**: sigue el del Mac.
- **17 idiomas**: español, inglés, catalán, gallego, euskera, francés, alemán, italiano, portugués, noruego, danés, finés, japonés, chino simplificado, coreano, hindi y árabe. Usa el del Mac o el que elijas en Ajustes.

## Uso

- **Clic derecho en el fondo del dock**: añadir separadores, espacios, grupos y widgets, y las opciones principales (posición, tamaño, ocultar, qué dock usar…).
- **Clic derecho en un widget**: sus ajustes, versión compacta o amplia, y quitarlo.
- **Ajustes…** (en el clic derecho del fondo): una ventana con todas las opciones. A la izquierda, **General** y un apartado por cada widget; el botón **+** añade widgets.

> El Dock de Apple no deja sacar sus iconos para llevarlos a otra app: al arrastrar uno fuera, lo elimina. Añade las apps a MyDock desde Finder.

## Permisos

MyDock solo pide un permiso cuando algo lo necesita, y macOS lo recuerda:

| Para | Permiso |
|---|---|
| Tiempo de tu ubicación | Ubicación (opcional: sin él, añade tus ciudades a mano) |
| Papelera | Finder (para saber si la Papelera tiene algo y vaciarla) |
| Próximos eventos | Calendario |
| Recordatorios | Recordatorios |
| Descargas | Carpeta Descargas |
| Capturas | Carpeta Escritorio (o donde guardes las capturas) |
| Ajustar ventanas al dock, y las ventanas y acciones de una app abierta en su menú del clic derecho | Accesibilidad |

Si dices que no, el widget mostrará «Sin permiso»; un clic te lleva al ajuste para darlo.

## Privacidad

- No hay cuentas ni analíticas. Tu configuración se guarda solo en tu Mac.
- El widget del tiempo envía a [Open-Meteo](https://open-meteo.com) solo unas coordenadas redondeadas (precisión de ~1 km) para obtener la temperatura. Los nombres de las ciudades se buscan con el servicio de mapas de Apple.
- El historial del portapapeles solo está en memoria: no se guarda en disco, se borra al cerrar MyDock y no incluye lo que copian los gestores de contraseñas.

## Seguridad

- **Runtime reforzado de macOS**: ningún otro programa puede inyectar código en MyDock para aprovechar sus permisos. Además, MyDock solo puede pedir los permisos de la tabla anterior.
- **Firma**: todas las versiones están firmadas con el mismo certificado, así que macOS reconoce las actualizaciones como la misma app y conserva tus permisos.
- **Comprueba que el `.dmg` es auténtico**: en la página de cada versión, GitHub muestra la huella SHA-256 del `.dmg` junto a su nombre, en *Assets*. En la app Terminal, escribe:

  ```bash
  shasum -a 256 ~/Downloads/MyDock-x.y.z.dmg
  ```

  El resultado debe coincidir exactamente con esa huella. Si no coincide, no lo abras.
- Descarga MyDock solo desde la [página de versiones oficial](https://github.com/JotaRguezD/MyDock/releases).

## Preguntas frecuentes

**¿Puedo dejar de ver el Dock de Apple?**
Sí: clic derecho › **Dock a usar › Solo MyDock**. Al cerrar MyDock, el Dock de Apple vuelve a aparecer tal y como lo tenías, incluso si MyDock se cierra de golpe por un fallo o con «Forzar salida».

**Al maximizar una ventana se mete por debajo de MyDock.**
Activa **Ajustar ventanas al dock** en Ajustes › General y da el permiso de Accesibilidad.

**¿Por qué no aparece la canción que escucho?**
El widget de música enseña lo mismo que macOS muestra como «Ahora suena» en el Centro de control. Si un reproductor no aparece ahí, MyDock tampoco puede verlo.

## Desinstalar

1. Desactiva **Abrir al iniciar sesión** y elige **Salir de MyDock**. Si usabas «Solo MyDock», el Dock de Apple vuelve a aparecer como lo tenías.
2. Borra MyDock de Aplicaciones.
3. Si quieres borrar también tus ajustes, borra la carpeta `~/Library/Application Support/MyDock`.

## Licencia

[MIT](LICENSE) © 2026 [JotaRguezD](https://github.com/JotaRguezD)
