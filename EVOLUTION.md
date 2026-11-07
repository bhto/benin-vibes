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
- Artistes populaires : avatars ronds cerclés de la couleur de l'artiste

### 3. Mini-lecteur
Barre en verre dépoli flottant au-dessus de la navigation, visible sur tous les
onglets : pochette, titre, artiste, bouton play/pause blanc, bouton suivant et
fine barre de progression verte. Un tap ouvre le lecteur plein écran.

### 3 bis. Lecteur plein écran (« En lecture »)
Feuille modale qui sort du bas, fond dégradé de la teinte de l'artiste, grand
halo coloré, pochette plein cadre avec ombre, titre, artiste, favori, slider
avec temps, contrôles (aléatoire, précédent, play blanc, suivant, répétition)
et volume.

**Paroles** : un appui sur la pochette (ou sur l'icône « paroles » en haut à
droite) bascule vers les paroles synchronisées. La ligne en cours est mise en
avant (blanc + barre verte), le reste est estompé. Un appui sur une ligne
déplace la lecture à cet instant. Les textes embarqués sont des paroles de
démonstration originales, à remplacer par les textes officiels sous licence.

**File d'attente** : l'icône dédiée en haut à droite ouvre le panneau
« File d'attente ». Le titre en cours y est mis en avant, suivi des titres
« À suivre ». Chaque ligne peut être glissée pour changer l'ordre, retirée
d'un appui sur la croix, ou lancée d'un tap. La file est gérée par
`PlayerController` (`playNext`, `addToQueue`, `removeUpNext`, `moveUpNext`).
Un appui long sur un titre des nouveautés ou de la bibliothèque l'insère juste
après le morceau en cours (« lire ensuite »).

### 4. Découvrir (3e onglet)
Barre de recherche en verre et grille de genres colorés (Zinli, Afrobeat,
Gospel, Vodoun Jazz, Tchink System, Rumba, Highlife, Hip-hop), suivie d'un
rail « Artistes à suivre ».

### 5. Bibliothèque
Onglets Favoris, Playlists et Téléchargés (indicateur vert). Liste de titres
numérotés avec pochette, titre, artiste et menu « ⋯ » ; états vides soignés
pour les playlists et téléchargements.

## État actuel
Refonte premium terminée : thème sombre Outfit, onboarding animé, shell (header,
navigation flottante en verre, mini-lecteur glass), accueil (carrousel, mix,
nouveautés, artistes), Découvrir, Bibliothèque, lecteur plein écran, paroles
synchronisées et file d'attente. Photos d'artistes embarquées dans
`assets/artists/` (crédits dans `assets/artists/ATTRIBUTIONS.md`), teinte propre
à chaque artiste. L'architecture Supabase Storage est cadrée dans
`SUPABASE_NOTES.md`.

Fichiers : main.dart, theme.dart, data.dart, disc_sleeve.dart,
onboarding_page.dart, home_shell.dart, now_playing_sheet.dart,
player_controller.dart

## Prochaines étapes
1. Brancher `PlayerController` sur just_audio (le lecteur est aujourd'hui simulé)
2. Création de la base SQLite et branchement sur l'accueil et la bibliothèque
3. Remplacer les données de démo par les vrais titres et pochettes
4. Image de Gnonnas Pedro (aucune photo libre trouvée pour l'instant)