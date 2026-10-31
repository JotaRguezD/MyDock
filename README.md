<p align="center"><img src="icon/AppIcon.png" width="160" alt="MyDock icon"></p>

<p align="center"><a href="README.md">English</a> · <a href="README.es.md">Español</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt.md">Português</a></p>

# MyDock

A dock for macOS with widgets, separators and app groups. It works alongside Apple's Dock or instead of it, without modifying the system.

## Download and installation

1. Download **`MyDock-x.y.z.dmg`** from the [latest release](https://github.com/JotaRguezD/MyDock/releases/latest).
2. Open the `.dmg` and drag **MyDock** to the **Applications** folder.
3. Open MyDock from Applications.

### The first time you open it

MyDock isn't signed by a developer verified by Apple, so macOS won't open it directly the first time:

- **macOS 15 Sequoia or later**: you'll see a warning; click **Done**. Go to **System Settings › Privacy & Security**, scroll to the bottom and click **Open Anyway** next to MyDock. Confirm with your password.
- **macOS 14 Sonoma**: right-click MyDock in Applications, choose **Open** and confirm.

You only need to do this once. Updates install the same way: download the new `.dmg` and drag MyDock to Applications to replace the old one. Your settings and permissions are kept.

### Requirements

- macOS 14 Sonoma or later.
- Any Mac: Intel or Apple silicon (M1, M2, M3…).

## What it does

### Apps, folders and groups

- **Pin apps and folders** by dragging them from Finder; clicking a folder opens it in Finder. To rearrange them, drag the icons within the dock.
- **Open apps**: apps you haven't pinned appear automatically after the pinned ones, just like in Apple's Dock. A dot under the icon means the app is open.
- **Groups**: several apps in a single icon; click it to open a small window with all of them. Drop an app onto a group to add it.
- **Separators and spaces**: as many as you want, wherever you want.
- **Trash**, at the end of the dock like in Apple's: click to open it, drop files on it to move them to the Trash or a dock icon to remove it, and right-click › **Empty Trash…** (always asks for confirmation). It can be hidden in Settings.
- **Apps and widgets live in separate areas**: apps first, then widgets, with a separator between them.
- **Animations**: when you open an app, its icon bounces until it finishes opening; widgets give a small pulse when clicked.

### Right-click menus

Menus open just above the dock with a small arrow pointing at the icon, like in Apple's Dock, so they never cover the icons next to it: right-click another icon and its menu opens straight away. This goes for apps, widgets, groups, the Trash and the dock background.

| App | Options |
|---|---|
| Open | Its windows · its main actions, from its File menu (New Window, New Event…) · **Options** › · Hide · **Quit** · Force Quit |
| Pinned, closed | Show in Finder · Move to Group · Remove from Dock · Quit (greyed out) |
| Inside a group, closed | Move to Dock · Remove from Group · Quit (greyed out) |

Under **Options**, an open app has the same choices it has when closed (or **Keep in Dock** if it isn't pinned). The windows and actions need the Accessibility permission. Each dock shows its own menu: right-clicking in Apple's Dock still opens Apple's.

### 16 widgets

| Basics | Productivity | System | Utilities |
|---|---|---|---|
| Clock & Date | Upcoming Events | Battery | Downloads |
| Weather | Reminders | Volume | Screenshots |
| Music | Pomodoro | Clipboard | Search |
| CPU & Memory | Quick Note | Disk & Network | Color Picker |

- **Clock & Date**: click to open Calendar.
- **Weather**: for your location or your saved cities; right-click › **City** to switch quickly. Click to open the Weather app.
- **Music**: the song playing in any app (Spotify, Music, a browser…), with previous, play/pause and next buttons. Click to open the app that's playing.
- **CPU & Memory**, **Disk & Network**: live usage; click to open Activity Monitor.
- **Upcoming Events**: your next Calendar event and how long until it starts.
- **Reminders**: your pending tasks; you can mark them as done right from the dock.
- **Pomodoro**: focus and break timer, with a sound when it ends.
- **Quick Note**: a short text you write that stays in the dock.
- **Battery**: percentage and whether it's charging.
- **Volume**: mute and a volume slider.
- **Clipboard**: what you copied recently, to copy it again with one click.
- **Downloads** and **Screenshots**: your latest files, to open them or drag them into another app.
- **Search**: find apps and files without opening Spotlight.
- **Color Picker**: pick a color from anywhere on screen and copy its code.

Each widget can only be added once.

### Customization

- **Each widget**: **compact** (icon-sized) or **wide** version, **background color** and its own options: 12- or 24-hour format, seconds, weather cities, °C or °F, Pomodoro minutes, how many items to show…
- **Position**: bottom, top, left or right. At the top, below the menu bar, it can live alongside Apple's Dock with just your widgets.
- **Icon size**: small, medium or large.
- **Automatically Hide**: the dock hides and comes back when you move the pointer to the edge of the screen.
- **Dock to Use**: MyDock only, MyDock alongside Apple's Dock, or back to Apple's.
- **Fit windows to the dock** (optional): maximized windows stop where MyDock begins, like with Apple's Dock. If the dock hides automatically, windows use the whole screen. With an app in full screen, MyDock hides and appears when you move the pointer to the edge.
- **Open at Login**.
- **Light or dark mode**: follows your Mac.
- **17 languages**: English, Spanish, Catalan, Galician, Basque, French, German, Italian, Portuguese, Norwegian, Danish, Finnish, Japanese, Simplified Chinese, Korean, Hindi and Arabic. It uses your Mac's language or the one you choose in Settings.

## Usage

- **Right-click the dock background**: add separators, spaces, groups and widgets, plus the main options (position, size, hiding, which dock to use…).
- **Right-click a widget**: its settings, compact or wide version, and remove it.
- **Settings…** (in the background right-click menu): a window with every option. On the left, **General** and one section per widget; the **+** button adds widgets.

> Apple's Dock doesn't let you drag its icons into another app: dragging one out removes it. Add apps to MyDock from Finder.

## Permissions

MyDock only asks for a permission when something needs it, and macOS remembers it:

| For | Permission |
|---|---|
| Weather for your location | Location (optional: without it, add your cities by hand) |
| Trash | Finder (to know whether the Trash has items and to empty it) |
| Upcoming Events | Calendar |
| Reminders | Reminders |
| Downloads | Downloads folder |
| Screenshots | Desktop folder (or wherever you save screenshots) |
| Fit windows to the dock, and an open app's windows and actions in its right-click menu | Accessibility |

If you say no, the widget shows "No permission"; clicking it takes you to the setting to grant it.

## Privacy

- No accounts and no analytics. Your settings are stored only on your Mac.
- The weather widget sends [Open-Meteo](https://open-meteo.com) only rounded coordinates (about 1 km precision) to get the temperature. City names are looked up with Apple's maps service.
- The clipboard history is kept in memory only: it's never written to disk, it's cleared when MyDock quits, and it skips anything copied by password managers.

## Security

- **macOS Hardened Runtime**: no other program can inject code into MyDock to take advantage of its permissions. MyDock can also only request the permissions in the table above.
- **Signing**: every release is signed with the same certificate, so macOS recognizes updates as the same app and keeps your permissions.
- **Check that the `.dmg` is genuine**: on each release page, GitHub shows the `.dmg`'s SHA-256 fingerprint next to its name, under *Assets*. In the Terminal app, type:

  ```bash
  shasum -a 256 ~/Downloads/MyDock-x.y.z.dmg
  ```

  The result must match that fingerprint exactly. If it doesn't, don't open it.
- Only download MyDock from the [official releases page](https://github.com/JotaRguezD/MyDock/releases).

## FAQ

**Can I stop seeing Apple's Dock?**
Yes: right-click › **Dock to Use › MyDock Only**. When MyDock quits, Apple's Dock comes back exactly as you had it, even if MyDock crashes or is force quit.

**When I maximize a window, it goes under MyDock.**
Turn on **Fit windows to the dock** in Settings › General and grant the Accessibility permission.

**Why doesn't the song I'm listening to show up?**
The music widget shows whatever macOS shows as Now Playing in Control Center. If a player doesn't appear there, MyDock can't see it either.

## Uninstall

1. Turn off **Open at Login** and choose **Quit MyDock**. If you were using "MyDock Only", Apple's Dock comes back as you had it.
2. Delete MyDock from Applications.
3. To also delete your settings, delete the folder `~/Library/Application Support/MyDock`.

## License

[MIT](LICENSE) © 2026 [JotaRguezD](https://github.com/JotaRguezD)
