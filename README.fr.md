<p align="center"><img src="icon/AppIcon.png" width="160" alt="Icône de MyDock"></p>

<p align="center"><a href="README.md">English</a> · <a href="README.es.md">Español</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt.md">Português</a></p>

# MyDock

Un Dock pour macOS avec des widgets, des séparateurs et des groupes d’apps. Il fonctionne à côté du Dock d’Apple ou à sa place, sans modifier le système.

## Téléchargement et installation

1. Téléchargez **`MyDock-x.y.z.dmg`** depuis la [dernière version](https://github.com/JotaRguezD/MyDock/releases/latest).
2. Ouvrez le `.dmg` et faites glisser **MyDock** dans le dossier **Applications**.
3. Ouvrez MyDock depuis Applications.

### La première ouverture

MyDock n’est pas signé par un développeur vérifié par Apple : macOS ne l’ouvrira donc pas directement la première fois.

- **macOS 15 Sequoia ou ultérieur** : un avertissement s’affiche ; cliquez sur **Terminé**. Ouvrez **Réglages Système › Confidentialité et sécurité**, faites défiler jusqu’en bas et cliquez sur **Ouvrir quand même** à côté de MyDock. Confirmez avec votre mot de passe.
- **macOS 14 Sonoma** : faites un clic droit sur MyDock dans Applications, choisissez **Ouvrir** et confirmez.

Cette opération n’est à faire qu’une seule fois. Les mises à jour s’installent de la même façon : téléchargez le nouveau `.dmg` et faites glisser MyDock dans Applications pour remplacer l’ancienne version. Vos réglages et autorisations sont conservés.

### Configuration requise

- macOS 14 Sonoma ou ultérieur.
- N’importe quel Mac : processeur Intel ou puce Apple (M1, M2, M3…).

## Fonctionnalités

### Apps, dossiers et groupes

- **Épinglez des apps et des dossiers** en les faisant glisser depuis le Finder ; un clic sur un dossier l’ouvre dans le Finder. Pour les réorganiser, faites glisser les icônes dans le Dock.
- **Apps ouvertes** : les apps non épinglées apparaissent automatiquement après les apps épinglées, comme dans le Dock d’Apple. Un point sous l’icône indique que l’app est ouverte.
- **Groupes** : plusieurs apps dans une seule icône ; un clic ouvre une petite fenêtre avec toutes les apps. Déposez une app sur un groupe pour l’y ajouter.
- **Séparateurs et espaces** : autant que vous voulez, où vous voulez.
- **Corbeille**, à la fin du Dock comme dans celui d’Apple : cliquez pour l’ouvrir, déposez-y des fichiers pour les mettre à la corbeille ou une icône du Dock pour la retirer, et clic droit › **Vider la corbeille…** (demande toujours une confirmation). Elle peut être masquée dans les réglages.
- **Les apps et les widgets sont dans des zones séparées** : d’abord les apps, puis les widgets, avec un séparateur entre les deux.
- **Animations** : à l’ouverture d’une app, son icône rebondit jusqu’à ce qu’elle soit lancée ; les widgets réagissent par une petite pulsation quand on clique dessus.

### Menus du clic droit

Les menus s’ouvrent juste au-dessus du Dock avec une petite flèche pointant vers l’icône, comme dans le Dock d’Apple, et ne cachent donc jamais les icônes voisines : faites un clic droit sur une autre icône et son menu s’ouvre aussitôt. C’est valable pour les apps, les widgets, les groupes, la corbeille et le fond du Dock.

| App | Options |
|---|---|
| Ouverte | Ses fenêtres · ses actions principales, tirées de son menu Fichier (Nouvelle fenêtre, Nouvel événement…) · **Options** › · Masquer · **Quitter** · Forcer à quitter |
| Épinglée, fermée | Afficher dans le Finder · Déplacer vers un groupe · Retirer du Dock · Quitter (en gris) |
| Dans un groupe, fermée | Sortir dans le Dock · Retirer du groupe · Quitter (en gris) |

Dans **Options**, une app ouverte propose les mêmes choix que lorsqu’elle est fermée (ou **Garder dans le Dock** si elle n’est pas épinglée). Les fenêtres et les actions nécessitent l’autorisation Accessibilité. Chaque Dock affiche son propre menu : un clic droit dans le Dock d’Apple ouvre toujours celui d’Apple.

### 16 widgets

| Essentiels | Productivité | Système | Utilitaires |
|---|---|---|---|
| Horloge et date | Prochains événements | Batterie | Téléchargements |
| Météo | Rappels | Volume | Captures d’écran |
| Musique | Pomodoro | Presse-papiers | Rechercher |
| CPU et mémoire | Note rapide | Disque et réseau | Pipette |

- **Horloge et date** : un clic ouvre Calendrier.
- **Météo** : celle de votre position ou de vos villes enregistrées ; clic droit › **Ville** pour changer rapidement. Un clic ouvre l’app Météo.
- **Musique** : le morceau en cours dans n’importe quelle app (Spotify, Musique, un navigateur…), avec les boutons précédent, lecture/pause et suivant. Un clic ouvre l’app qui joue.
- **CPU et mémoire**, **Disque et réseau** : utilisation en temps réel ; un clic ouvre le Moniteur d’activité.
- **Prochains événements** : votre prochain événement du Calendrier et le temps restant.
- **Rappels** : vos tâches en attente ; vous pouvez les marquer comme terminées directement depuis le Dock.
- **Pomodoro** : minuteur de concentration et de pause, avec un son à la fin.
- **Note rapide** : un court texte que vous écrivez et qui reste dans le Dock.
- **Batterie** : pourcentage et état de charge.
- **Volume** : couper le son et curseur de volume.
- **Presse-papiers** : ce que vous avez copié récemment, pour le copier à nouveau d’un clic.
- **Téléchargements** et **Captures d’écran** : vos derniers fichiers, pour les ouvrir ou les faire glisser dans une autre app.
- **Rechercher** : trouvez des apps et des fichiers sans ouvrir Spotlight.
- **Pipette** : prélevez une couleur n’importe où à l’écran et copiez son code.

Chaque widget ne peut être ajouté qu’une seule fois.

### Personnalisation

- **Chaque widget** : version **compacte** (de la taille d’une icône) ou **large**, **couleur de fond** et ses propres options : format 12 ou 24 heures, secondes, villes de la météo, °C ou °F, minutes du Pomodoro, nombre d’éléments à afficher…
- **Position** : en bas, en haut, à gauche ou à droite. En haut, sous la barre des menus, il peut cohabiter avec le Dock d’Apple avec seulement vos widgets.
- **Taille des icônes** : petite, moyenne ou grande.
- **Masquer automatiquement** : le Dock se masque et réapparaît quand vous amenez le pointeur au bord de l’écran.
- **Dock à utiliser** : MyDock uniquement, MyDock et celui d’Apple, ou revenir à celui d’Apple.
- **Ajuster les fenêtres au Dock** (facultatif) : les fenêtres agrandies s’arrêtent là où commence MyDock, comme avec le Dock d’Apple. Si le Dock se masque automatiquement, les fenêtres occupent tout l’écran. Quand une app est en plein écran, MyDock se masque et apparaît quand vous amenez le pointeur au bord.
- **Ouvrir à l’ouverture de session**.
- **Mode clair ou sombre** : suit celui de votre Mac.
- **17 langues** : anglais, espagnol, catalan, galicien, basque, français, allemand, italien, portugais, norvégien, danois, finnois, japonais, chinois simplifié, coréen, hindi et arabe. MyDock utilise la langue de votre Mac ou celle que vous choisissez dans les réglages.

## Utilisation

- **Clic droit sur le fond du Dock** : ajouter des séparateurs, des espaces, des groupes et des widgets, ainsi que les options principales (position, taille, masquage, Dock à utiliser…).
- **Clic droit sur un widget** : ses réglages, version compacte ou large, et le retirer.
- **Réglages…** (dans le menu du clic droit sur le fond) : une fenêtre avec toutes les options. À gauche, **Général** et une section par widget ; le bouton **+** ajoute des widgets.

> Le Dock d’Apple ne permet pas de faire glisser ses icônes vers une autre app : en faire sortir une la retire. Ajoutez les apps à MyDock depuis le Finder.

## Autorisations

MyDock ne demande une autorisation que lorsqu’une fonction en a besoin, et macOS s’en souvient :

| Pour | Autorisation |
|---|---|
| Météo de votre position | Localisation (facultatif : sans elle, ajoutez vos villes à la main) |
| Corbeille | Finder (pour savoir si la corbeille contient des éléments et la vider) |
| Prochains événements | Calendriers |
| Rappels | Rappels |
| Téléchargements | Dossier Téléchargements |
| Captures d’écran | Dossier Bureau (ou l’endroit où vous enregistrez vos captures) |
| Ajuster les fenêtres au Dock, et les fenêtres et actions d’une app ouverte dans son menu du clic droit | Accessibilité |

Si vous refusez, le widget affiche « Sans autorisation » ; un clic ouvre le réglage pour l’accorder.

## Confidentialité

- Aucun compte et aucune analyse. Vos réglages sont enregistrés uniquement sur votre Mac.
- Le widget Météo envoie à [Open-Meteo](https://open-meteo.com) uniquement des coordonnées arrondies (précision d’environ 1 km) pour obtenir la température. Les noms des villes sont recherchés avec le service de cartes d’Apple.
- L’historique du presse-papiers est conservé uniquement en mémoire : il n’est jamais écrit sur le disque, il est effacé quand MyDock quitte et il ignore ce que copient les gestionnaires de mots de passe.

## Sécurité

- **Hardened Runtime de macOS** : aucun autre programme ne peut injecter de code dans MyDock pour profiter de ses autorisations. De plus, MyDock ne peut demander que les autorisations du tableau ci-dessus.
- **Signature** : toutes les versions sont signées avec le même certificat ; macOS reconnaît donc les mises à jour comme la même app et conserve vos autorisations.
- **Vérifiez que le `.dmg` est authentique** : sur la page de chaque version, GitHub affiche l’empreinte SHA-256 du `.dmg` à côté de son nom, dans *Assets*. Dans l’app Terminal, saisissez :

  ```bash
  shasum -a 256 ~/Downloads/MyDock-x.y.z.dmg
  ```

  Le résultat doit correspondre exactement à cette empreinte. Sinon, ne l’ouvrez pas.
- Téléchargez MyDock uniquement depuis la [page officielle des versions](https://github.com/JotaRguezD/MyDock/releases).

## Questions fréquentes

**Puis-je ne plus voir le Dock d’Apple ?**
Oui : clic droit › **Dock à utiliser › MyDock uniquement**. Quand MyDock quitte, le Dock d’Apple réapparaît exactement comme avant, même si MyDock plante ou est forcé à quitter.

**Quand j’agrandis une fenêtre, elle passe sous MyDock.**
Activez **Ajuster les fenêtres au Dock** dans Réglages › Général et accordez l’autorisation Accessibilité.

**Pourquoi le morceau que j’écoute n’apparaît-il pas ?**
Le widget Musique affiche ce que macOS indique dans « À l’écoute » du Centre de contrôle. Si un lecteur n’y apparaît pas, MyDock ne peut pas le voir non plus.

## Désinstallation

1. Désactivez **Ouvrir à l’ouverture de session** et choisissez **Quitter MyDock**. Si vous utilisiez « MyDock uniquement », le Dock d’Apple réapparaît comme avant.
2. Supprimez MyDock d’Applications.
3. Pour supprimer aussi vos réglages, supprimez le dossier `~/Library/Application Support/MyDock`.

## Licence

[MIT](LICENSE) © 2026 [JotaRguezD](https://github.com/JotaRguezD)
