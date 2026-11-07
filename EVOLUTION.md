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

## Thème (dark doux)
- Fond : gris-vert ardoise #212A27, pas trop foncé
- Surfaces / cartes : #2B3532 et #36423E
- Couleur principale : vert clair #2FB36D
- Accent : jaune #FCD116 (boutons play, indicateurs, onglet actif)
- Touche rare : rouge #E8112D (point de notification, likes)
- Palette inspirée du drapeau béninois
- Typo suggérée : Poppins ou Outfit

## Navigation
Barre du bas (bottomNav) avec 3 onglets : Accueil, Découvrir, Bibliothèque.

## Header (commun aux 3 onglets)
- À gauche : « Bonjour 👋 » et le titre de l'onglet actif
- À droite : bouton recherche et bouton notifications (cloche avec point rouge)

## Écrans

### 1. Onboarding (3 écrans)
Chaque écran affiche une pochette d'où sort un vinyle qui tourne en continu.
Le disque sort avec un léger rebond quand la page devient active, et rentre
quand on la quitte.
- Écran 1 : « Le son du Bénin dans ta poche » (pochette verte)
- Écran 2 : « Découvre les artistes d'ici » (pochette rouge)
- Écran 3 : « Crée ta bibliothèque, écoute partout » (pochette jaune)
Éléments communs : bouton « Passer » en haut à droite (masqué au dernier écran),
indicateurs de page qui s'étirent sur la page active, bouton principal jaune
« Suivant » puis « Commencer ».

### 2. Accueil
Sections défilantes :
- À la une : grandes cartes en dégradé avec titre, artiste et bouton play
- Nouveautés : pochettes carrées avec titre et artiste
- Artistes populaires : avatars ronds avec le nom

### 3. Mini-lecteur
Barre flottante juste au-dessus de la bottomNav, visible sur tous les onglets :
pochette, titre, artiste, bouton play/pause jaune, bouton suivant, et fine barre
de progression. Un tap sur un titre dans l'app met à jour le mini-lecteur.
Prévu plus tard : un tap ouvre le lecteur plein écran.

### 4. Découvrir (3e onglet)
Barre de recherche et grille de genres colorés (Zinli, Afrobeat, Gospel,
Vodoun Jazz, Tchink System, Rumba, Highlife, Hip-hop).

### 5. Bibliothèque
Onglets Favoris, Playlists et Téléchargés (à remplacer éventuellement par
« Récents » ou « Albums », puisque les musiques sont déjà locales).
Liste de titres avec pochette, titre, artiste et menu « ⋮ ».

## État actuel
Code Flutter généré pour : thème, onboarding animé, shell (header, bottomNav,
mini-lecteur), accueil, Découvrir et Bibliothèque, avec des données de démo.
Fichiers : main.dart, theme.dart, data.dart, disc_sleeve.dart,
onboarding_page.dart, home_shell.dart

## Prochaines étapes
1. Écran lecteur plein écran (ouverture depuis le mini-lecteur)
2. Création de la base SQLite et branchement sur l'accueil et la bibliothèque
3. Intégration de just_audio avec les fichiers locaux
4. Remplacement des données de démo par les vrais titres et pochettes