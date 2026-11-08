# Benin Vibes : app musicale béninoise (Flutter)

## Concept
Petite app mobile pour écouter des morceaux béninois d'artistes locaux.
Nom provisoire : « Benin Vibes » (« voix » / « langue » en fon/gbe).

## Choix techniques
- Framework : Flutter (Material 3)
- Lecture audio : just_audio
- Musiques : fichiers locaux embarqués (assets/audio/), pas d'API de streaming
- Base de données : SQLite (sqflite ou drift) pour les infos des morceaux
  (titre, artiste, genre, durée, chemin audio, chemin pochette, favoris, playlists)
- Prérequis : accord des artistes pour la diffusion de leurs titres

## Thème (premium, façon Apple Music)
- Fond : noir profond #070A09 avec halo vert en haut de l'écran
- Surfaces : #121816 et #1A211E, bordures blanches à 12 %
- Couleur principale : vert Bénin #2FB36D (actions, onglet actif, progression)
- Bouton de lecture : blanc cassé #F4F7F5, icône noire
- Accent rare : jaune #FCD116 (badge « À la une », point de notification)
- Touche rare : rouge #E8112D (likes)
- Typographie : **Outfit** embarquée dans `assets/fonts/` (300 → 800)
- Teinte dynamique par artiste pour les fonds, halos et pochettes de secours
- Transitions de pages Cupertino (glissement horizontal)

## Navigation
Barre flottante en verre dépoli (blur + bordure fine), détachée des bords,
avec 3 onglets : Accueil, Découvrir, Bibliothèque. L'onglet actif est vert
avec une pastille de fond discrète. Le contenu défile derrière la barre.

## Header (commun aux 3 onglets, fixe)
- À gauche : « Bonjour 👋 » et le titre de l'onglet actif (Outfit 27, tracking serré)
- À droite : boutons ronds en verre pour la recherche et les notifications
  (point jaune)
- Le header est posé sur le même dégradé que le contenu (aucune couture)

## Écrans

### 1. Onboarding (3 écrans)
Chaque écran affiche une pochette (logo « BENIN VIBES ») d'où sort un vinyle
qui tourne en continu. Le disque sort avec un léger rebond quand la page
devient active, et rentre quand on la quitte.
- Écran 1 : « Le son du Bénin dans ta poche » (pochette verte)
- Écran 2 : « Découvre les artistes d'ici » (pochette magenta)
- Écran 3 : « Crée ta bibliothèque, écoute partout » (pochette orange)
Éléments communs : wordmark « BENIN VIBES », bouton « Passer » en haut à droite
(masqué au dernier écran), indicateurs de page verts qui s'étirent, bouton
principal vert avec flèche « Suivant » puis « Commencer ».

### 2. Accueil
Sections défilantes :
- À la une : carrousel `PageView` avec accroche, scale 1.0 sur la carte active
  et 0.9 sur les voisines, photo plein cadre, badge jaune et bouton « Écouter »
- Mix du jour : grande carte teintée avec pochette et accès direct à la lecture
- Nouveautés : pochettes carrées avec ombre teintée, titre et artiste
- Artistes populaires : avatars ronds cerclés de la couleur de l'artiste.
  Un appui ouvre la fiche de l'artiste avec tous ses morceaux disponibles ;
  l'utilisateur choisit celui qu'il veut lancer.

### 3. Mini-lecteur
Barre en verre dépoli flottant au-dessus de la navigation, visible sur tous les
onglets **dès qu'un morceau a été choisi** : pochette, titre, artiste, bouton
play/pause blanc, bouton suivant et fine barre de progression verte. Un tap
ouvre le lecteur plein écran. Au premier lancement, il reste masqué tant que
l'utilisateur n'a pas sélectionné de musique.

### 3 bis. Lecteur plein écran (« En lecture »)
Feuille modale qui sort du bas, fond dégradé de la teinte de l'artiste, grand
halo coloré, pochette plein cadre avec ombre, titre, artiste, favori, slider
avec temps, contrôles (aléatoire, précédent, play blanc, suivant, répétition)
et volume.

**Favoris** : le cœur est actif si le morceau est déjà aimé. Un appui écrit
la colonne `liked` dans SQLite et le titre rejoint immédiatement l'onglet
« Favoris » de la Bibliothèque.

**Aléatoire et répétition** : les deux boutons s'illuminent en vert quand ils
sont actifs. L'aléatoire mélange les titres à venir sans interrompre le morceau
en cours et restaure l'ordre d'origine quand on le coupe. La répétition renvoie
au début de la file après le dernier titre ; sans elle, la lecture s'arrête.

**Volume** : le slider du bas règle directement le volume du moteur audio
(`JustAudioEngine.setVolume`), sans passer par un état local.

**Paroles** : l'icône « paroles » et le badge sur la pochette n'apparaissent
que si le morceau possède des paroles. Un appui sur la pochette (ou sur
l'icône) bascule vers les paroles synchronisées. La ligne en cours est mise en
avant (blanc + barre verte), le reste est estompé. Un appui sur une ligne
déplace la lecture à cet instant. Dès que l'utilisateur fait défiler les
paroles à la main, le suivi automatique se met en pause et une petite pastille
« Revenir aux paroles » apparaît pour recentrer la ligne chantée. Les textes
embarqués sont des paroles de démonstration originales, à remplacer par les
textes officiels sous licence.

**File d'attente** : l'icône dédiée en haut à droite ouvre le panneau
« File d'attente ». Le titre en cours y est mis en avant, suivi des titres
« À suivre ». Chaque ligne peut être glissée pour changer l'ordre, retirée
d'un appui sur la croix, ou lancée d'un tap. La file est gérée par
`PlayerController` (`playNext`, `addToQueue`, `removeUpNext`, `moveUpNext`).
Un appui long sur un titre des nouveautés ou de la bibliothèque l'insère juste
après le morceau en cours (« lire ensuite »).

### 4. Découvrir (3e onglet)
Barre de recherche fonctionnelle (titre, artiste, genre, insensible aux accents)
et grille de toutes les catégories de la base (Afro-folk, Afropop, Gospel,
Traditionnel, World, Tchink System), avec le nombre de titres par genre. Un
appui ouvre la fiche du genre : liste de ses morceaux et bouton « Tout lire »
qui charge toute la catégorie dans la file d'attente. Sans résultat, la
recherche propose quelques titres au hasard, écoutables sans quitter la vue.

### 5. Bibliothèque
Onglets Titres, Favoris et Artistes (indicateur vert). « Titres » liste toute
la bibliothèque en ordre aléatoire, numérotée avec pochette, titre, artiste et
genre. « Favoris » reprend les morceaux aimés depuis le lecteur, persistés dans
la colonne `tracks.liked` de SQLite. « Artistes » regroupe les titres par
artiste, avec les artistes eux-mêmes mélangés.

## État actuel
Application fonctionnelle hors ligne : thème sombre Outfit, onboarding animé,
shell (header, navigation flottante en verre, mini-lecteur glass), accueil
(carrousel aléatoire, mix, nouveautés, artistes), fiches artistes, fiches
genres avec « Tout lire », Découvrir,
Bibliothèque, lecteur plein écran, paroles synchronisées et file d'attente.
Bibliothèque SQLite (artistes, genres, morceaux, favoris en version 2 du
schéma) et 37 MP3 embarqués dans `assets/audio/`, lus avec `just_audio`.
L'architecture est décrite dans `AUDIO_NOTES.md`.

Fichiers : main.dart, theme.dart, data.dart, disc_sleeve.dart,
onboarding_page.dart, home_shell.dart, artist_page.dart, genre_page.dart,
now_playing_sheet.dart, player_controller.dart.

## Prochaines étapes
1. Playlists persistantes
2. Lecture en arrière-plan et contrôles système (`audio_service`)
3. Images d'artistes manquantes (Gnonnas Pedro)