# Benin Vibes — Cahier des charges

**Version du document :** 1.0  
**Date :** 8 novembre 2026  
**Statut :** Version de travail soumise à validation  
**Application visée :** Benin Vibes 1.0.0 (`versionCode` 1)  
**Plateforme livrée :** Android  
**Rédaction :** [À compléter]  
**Relecture :** [À compléter]  
**Validation :** [À compléter]  
**Diffusion :** [À compléter]

## Objet du document

Ce document constitue le cahier des charges de l'application **Benin Vibes**, une
application mobile de découverte et d'écoute de musique béninoise, entièrement
hors ligne.

L'application est déjà largement réalisée. Le document décrit donc :

- le besoin et le comportement attendu de la version 1.0 ;
- les exigences fonctionnelles et non fonctionnelles, numérotées et testables ;
- le contenu, les droits et les données ;
- les livrables, la recette et les limites connues.

La colonne **État** des exigences indique ce qui est livré, partiel ou reporté.
Elle ne remplace pas la recette finale sur appareil.

### Documents de référence

| Document | Rôle |
|---|---|
| `EVOLUTION.md` | Description produit, écrans et comportements |
| `AUDIO_NOTES.md` | Architecture audio, base locale et chaîne de contenu |
| `README.md` | Guide de démarrage du projet (à compléter) |
| `tool/README.md` | Outils de conversion audio et de génération du seed |

### Sommaire

1. Synthèse
2. Contexte et objectifs
3. Périmètre
4. Exigences fonctionnelles
5. Règles métier
6. Exigences non fonctionnelles
7. Contenu, droits et qualité éditoriale
8. Données et persistance
9. Livrables
10. Recette et stratégie de tests
11. Organisation, planning et budget
12. Risques
13. Écarts connus et dette technique
14. Évolutions futures
- Annexe A — Architecture technique
- Annexe B — Commandes de build et d'installation
- Annexe C — Glossaire
- Annexe D — Journal des versions du document
- Annexe E — Points à compléter avant validation

---

## 1. Synthèse

Benin Vibes est une application Android qui permet d'écouter un catalogue de
musique béninoise embarqué dans l'application. Elle ne dépend d'aucun serveur,
d'aucun compte utilisateur et d'aucune connexion réseau.

Le produit vise une expérience simple et soignée :

1. une découverte immédiate du catalogue dès l'ouverture ;
2. une navigation en trois onglets : **Accueil**, **Découvrir**, **Bibliothèque** ;
3. une écoute locale fiable, avec mini-lecteur, lecteur plein écran, file
   d'attente, favoris et paroles synchronisées ;
4. une identité visuelle premium, sombre et colorée, inspirée des grandes
   applications de musique.

Le périmètre de la version 1.0 est volontairement limité : pas de streaming, pas
de téléchargement, pas de réseau, pas de compte, pas de paiement.

---

## 2. Contexte et objectifs

### 2.1 Contexte

Le Bénin dispose d'une scène musicale riche et diverse : afro-folk, afropop,
gospel, musique traditionnelle, world, tchink system. Cette production circule
souvent mal en dehors des radios locales et des plateformes internationales, qui
la référencent peu et la monétisent difficilement.

Benin Vibes propose une expérience ciblée, légère et accessible, centrée sur un
catalogue local soigneusement sélectionné.

### 2.2 Problème à résoudre

- Accéder facilement à un catalogue béninois cohérent, sans dépendre du réseau.
- Découvrir des artistes et des genres locaux dans une interface agréable.
- Permettre une écoute immédiate, y compris dans des zones à connectivité
  limitée ou nulle.
- Mettre en valeur les artistes et leurs œuvres dans un cadre respectueux des
  droits.

### 2.3 Objectifs du produit

| Réf. | Objectif | Indicateur de réussite |
|---|---|---|
| OBJ-01 | Rendre le catalogue disponible hors ligne | 100 % des morceaux et pochettes lisibles en mode avion |
| OBJ-02 | Offrir une découverte simple | Un morceau peut être lancé en 3 interactions maximum depuis l'accueil |
| OBJ-03 | Proposer une expérience d'écoute complète | Mini-lecteur, lecteur, file, favoris et paroles opérationnels |
| OBJ-04 | Préserver les données de l'utilisateur | Favoris et état d'onboarding conservés entre deux lancements |
| OBJ-05 | Faciliter la mise à jour du catalogue | Ajout ou retrait d'un titre sans modifier le code applicatif |
| OBJ-06 | Respecter les droits des artistes | Autorisations écrites disponibles avant toute diffusion publique |

Les cibles chiffrées des indicateurs restent à valider : **[À compléter]**.

### 2.4 Indicateurs de succès à suivre

- Nombre de lancements et de morceaux écoutés : **[À compléter]**.
- Taux de complétion de l'onboarding : **[À compléter]**.
- Nombre de favoris enregistrés : **[À compléter]**.
- Taux de plantage et incidents de lecture : **[À compléter]**.
- Retours qualitatifs des utilisateurs pilotes : **[À compléter]**.

Aucun outil de mesure n'est intégré dans la version actuelle : le suivi est
manuel, dans le respect de la vie privée.

---

## 3. Périmètre

### 3.1 Périmètre inclus

- Application Android développée avec Flutter, en français.
- Catalogue embarqué : 37 morceaux, 9 artistes, 6 genres.
- Onboarding en trois écrans, affiché une seule fois.
- Accueil éditorialisé (À la une, Mix du jour, Nouveautés, Artistes populaires).
- Recherche par titre, artiste et genre.
- Fiches artistes et fiches genres.
- Bibliothèque : titres, favoris, artistes.
- Mini-lecteur, lecteur plein écran, file d'attente.
- Lecture aléatoire, répétition de la file, volume.
- Paroles synchronisées pour les morceaux qui en possèdent.
- Persistance locale des favoris et de l'état d'onboarding.
- Fonctionnement hors ligne complet.

### 3.2 Périmètre exclu de la version 1.0

| Élément exclu | Précision |
|---|---|
| Streaming et téléchargement | Aucun contenu n'est récupéré sur Internet |
| Compte utilisateur | Pas d'inscription, pas de synchronisation |
| Réseaux sociaux | Pas de partage, pas de commentaires, pas de profils publics |
| Achats et abonnements | Aucune monétisation intégrée |
| Publicités | Aucune régie publicitaire |
| Lecture en arrière-plan garantie | Pas de service audio de premier plan ni de contrôles système |
| Playlists personnalisées | Non implémentées dans la version 1.0 |
| Import de fichiers locaux | Le catalogue est fixé à la compilation |
| Version iOS | Dossier présent, mais non livré ni recetté |
| Version web ou desktop | Hors périmètre |
| Notifications push | La cloche affiche un message statique |
| Mesure d'audience | Aucun outil analytique intégré |

### 3.3 Publics cibles

| Persona | Besoin principal | Attentes |
|---|---|---|
| Auditeur béninois | Écouter de la musique locale sans consommer de données | Simplicité, rapidité, catalogue familier |
| Membre de la diaspora | Retrouver les artistes du pays | Qualité audio, pochettes, paroles |
| Découvreur curieux | Explorer les genres et artistes | Recherche, fiches artistes, suggestions |
| Artiste ou ayant droit | Être visible et respecté | Crédits, autorisations, qualité de présentation |
| Utilisateur en zone peu connectée | Écouter malgré un réseau faible | Fonctionnement 100 % hors ligne |

### 3.4 Contraintes du projet

- **C-01** — Ne pas ajouter de nouvelle dépendance sans validation explicite.
- **C-02** — Le catalogue audio, les pochettes et les paroles sont embarqués
  dans l'application.
- **C-03** — Aucune donnée utilisateur ne quitte l'appareil.
- **C-04** — L'application doit rester utilisable sans réseau, y compris au
  premier lancement.
- **C-05** — La distribution se fait par APK pour la version 1.0.
- **C-06** — La version de production devra être signée avec une clé de release
  dédiée, distincte de la clé de debug.
- **C-07** — Le poids de l'APK est contraint par les 37 MP3 embarqués.
- **C-08** — Les évolutions du catalogue passent par une nouvelle compilation.

### 3.5 Hypothèses

- H-01 — L'appareil cible dispose d'au moins 1 Go d'espace libre.
- H-02 — L'appareil exécute Android 7.0 (API 24) ou une version ultérieure.
- H-03 — L'utilisateur parle français.
- H-04 — Les autorisations de diffusion sont obtenues avant toute distribution
  publique.
- H-05 — Le catalogue reste de taille modeste (moins de 100 titres) à court
  terme.
- H-06 — La version 1.0 est diffusée à un cercle pilote, pas sur un store public.

---

## 4. Exigences fonctionnelles

### 4.1 Convention

- **Identifiant** : `EF-xx`.
- **Priorité** :
  - **Must** : indispensable à la version 1.0 ;
  - **Should** : important, peut être reporté avec justification ;
  - **Could** : confort, sans impact bloquant.
- **État** : `Livré`, `Partiel`, `Reporté`, `Hors périmètre`.
- Chaque critère d'acceptation est vérifiable manuellement ou par un test
  automatisé.

### 4.2 Tableau de synthèse

| ID | Exigence | Priorité | État |
|---|---|---|---|
| EF-01 | Onboarding en trois écrans, affiché une seule fois | Must | Livré |
| EF-02 | Accueil éditorialisé en quatre sections | Must | Livré |
| EF-03 | En-tête, navigation flottante et persistance de l'onglet | Must | Livré |
| EF-04 | Recherche transverse par titre, artiste et genre | Must | Livré |
| EF-05 | Découvrir : grille des genres, fiche genre et « Tout lire » | Must | Livré |
| EF-06 | Bibliothèque : liste des titres | Must | Livré |
| EF-07 | Favoris persistants | Must | Livré |
| EF-08 | Bibliothèque : artistes et fiche artiste | Must | Livré |
| EF-09 | Mini-lecteur permanent après le premier choix | Must | Livré |
| EF-10 | Lecteur plein écran | Must | Livré |
| EF-11 | File d'attente consultable et modifiable | Should | Livré |
| EF-12 | Lecture aléatoire | Should | Livré |
| EF-13 | Répétition de la file | Should | Partiel |
| EF-14 | Réglage du volume | Should | Livré |
| EF-15 | Paroles synchronisées | Should | Livré |
| EF-16 | Notifications et message de bienvenue | Could | Livré (statique) |
| EF-17 | Persistance locale et migration de schéma | Must | Livré |
| EF-18 | Robustesse en cas d'audio indisponible | Must | Livré |
| EF-19 | Cycle de vie, reprise et lecture en arrière-plan | Could | Partiel |
| EF-20 | États vides et cas limites | Must | Livré |

### 4.3 Détail des exigences

#### EF-01 — Onboarding en trois écrans, affiché une seule fois

**Priorité :** Must — **État :** Livré

**Description.** Au premier lancement, l'utilisateur voit trois écrans de
présentation. Chaque écran associe une pochette, un vinyle animé, un titre, un
sous-titre et un bouton principal. L'utilisateur peut passer l'onboarding ou le
terminer. Le passage est enregistré localement.

**Critères d'acceptation.**

- [ ] Au premier lancement, l'onboarding s'affiche avant l'accueil.
- [ ] Les trois écrans sont accessibles par glissement et par le bouton
      « Suivant ».
- [ ] Le bouton « Passer » est visible sur les deux premiers écrans et masqué
      sur le dernier.
- [ ] Le dernier écran affiche « Commencer » et ouvre l'accueil.
- [ ] « Passer » et « Commencer » enregistrent tous deux le passage.
- [ ] Au lancement suivant, l'accueil s'ouvre directement, sans onboarding.
- [ ] Effacer les données de l'application réactive l'onboarding.
- [ ] Un double appui sur le bouton de sortie ne provoque pas de double
      navigation.
- [ ] Si l'enregistrement échoue, l'application s'ouvre quand même.
- [ ] Les animations du vinyle ne bloquent jamais l'accès aux boutons.

**Cas limites.** Stockage inaccessible, écriture refusée, appareil lent.

---

#### EF-02 — Accueil éditorialisé en quatre sections

**Priorité :** Must — **État :** Livré

**Description.** L'accueil présente quatre sections défilantes :

1. **À la une** : carrousel de 5 morceaux tirés au hasard, avec mise en avant
   de la carte active.
2. **Mix du jour** : carte teintée mettant en avant un morceau, avec accès
   direct à la lecture.
3. **Nouveautés** : sélection de 10 morceaux tirés au hasard, avec pochette,
   titre et artiste.
4. **Artistes populaires** : avatars ronds des artistes, cerclés de leur
   couleur, ouvrant leur fiche.

**Critères d'acceptation.**

- [ ] Les quatre sections s'affichent dans l'ordre défini lorsque la
      bibliothèque contient assez de morceaux.
- [ ] « À la une » contient 5 cartes lorsque le catalogue le permet.
- [ ] La carte active est à l'échelle 1,0 et les voisines à 0,9.
- [ ] Un appui sur « Écouter » lance le morceau et affiche le mini-lecteur.
- [ ] Un appui sur la carte « Mix du jour » lance le morceau mis en avant.
- [ ] Un appui sur un titre des « Nouveautés » lance sa lecture.
- [ ] Un appui long sur un titre des « Nouveautés » l'insère juste après le
      morceau en cours et affiche une confirmation.
- [ ] Un appui sur un artiste ouvre sa fiche sans lancer de lecture.
- [ ] Les sections se masquent proprement si le catalogue est vide.
- [ ] Les images manquantes sont remplacées par une pochette de secours teintée.

**Cas limites.** Catalogue de moins de 5 titres, artiste sans image, image
corrompue.

---

#### EF-03 — En-tête, navigation flottante et persistance de l'onglet

**Priorité :** Must — **État :** Livré

**Description.** Un en-tête fixe affiche un salut dépendant de l'heure
(« Bonjour », « Bon après-midi », « Bonsoir », « Bonne nuit »), le titre de
l'onglet actif et un bouton de notifications. Une barre de navigation flottante
en verre dépoli propose trois onglets : Accueil, Découvrir, Bibliothèque.

**Critères d'acceptation.**

- [ ] L'en-tête reste fixe pendant le défilement du contenu.
- [ ] Le titre de l'onglet actif est affiché et animé lors du changement.
- [ ] Le salut correspond à la plage horaire en cours.
- [ ] Les trois onglets sont accessibles en un appui.
- [ ] L'onglet actif est distingué visuellement (couleur verte et pastille).
- [ ] Le contenu défile derrière la barre flottante.
- [ ] Le choix d'onglet est conservé lors des interactions internes.
- [ ] Le bouton de notifications est toujours accessible.

**Cas limites.** Texte agrandi, petit écran, rotation, changement d'heure pendant
la session.

---

#### EF-04 — Recherche transverse par titre, artiste et genre

**Priorité :** Must — **État :** Livré

**Description.** L'onglet Découvrir propose une barre de recherche. La recherche
porte sur le titre, le nom d'artiste et le genre. Elle ignore la casse et les
accents. Tous les mots saisis doivent être présents.

**Critères d'acceptation.**

- [ ] La recherche est accessible depuis l'onglet Découvrir.
- [ ] « kidjo » trouve les morceaux d'Angélique Kidjo.
- [ ] « angelique » trouve les mêmes morceaux malgré l'accent.
- [ ] Une recherche sur un genre renvoie les morceaux de ce genre.
- [ ] Une requête de plusieurs mots exige la présence de tous les mots.
- [ ] Une requête vide n'affiche aucun résultat.
- [ ] Le bouton d'effacement vide la requête et restaure la grille des genres.
- [ ] Un résultat peut être lancé directement depuis la liste.
- [ ] Sans résultat, un message clair s'affiche et des suggestions de morceaux
      sont proposées.
- [ ] Une suggestion peut être écoutée sans quitter la vue.

**Cas limites.** Accents majuscules, caractères spéciaux, espaces multiples,
requête très longue.

---

#### EF-05 — Découvrir : grille des genres, fiche genre et « Tout lire »

**Priorité :** Must — **État :** Livré

**Description.** L'onglet Découvrir affiche une grille de toutes les catégories
musicales de la base, avec le nombre de titres par genre. Un appui ouvre la
fiche du genre, qui liste ses morceaux et propose « Tout lire ».

**Critères d'acceptation.**

- [ ] Les six genres du catalogue sont affichés.
- [ ] Chaque carte de genre indique le nombre de morceaux disponibles.
- [ ] Un appui sur un genre ouvre sa fiche.
- [ ] La fiche liste uniquement les morceaux du genre.
- [ ] Un appui sur un morceau lance sa lecture et referme la fiche.
- [ ] « Tout lire » charge tous les morceaux du genre dans la file et démarre
      le premier.
- [ ] La fiche reste utilisable si un genre ne contient aucun morceau (état
      vide ou absence de la carte).

**Cas limites.** Genre sans morceau, genre supprimé, bibliothèque vide.

---

#### EF-06 — Bibliothèque : liste des titres

**Priorité :** Must — **État :** Livré

**Description.** L'onglet Bibliothèque propose trois sous-onglets : Titres,
Favoris et Artistes. « Titres » liste toute la bibliothèque dans un ordre
mélangé à l'ouverture, avec numéro, pochette, titre, artiste et genre.

**Critères d'acceptation.**

- [ ] Les trois sous-onglets sont visibles et sélectionnables.
- [ ] L'onglet Titres liste tous les morceaux de la bibliothèque.
- [ ] L'ordre est mélangé à chaque ouverture de l'application.
- [ ] Chaque ligne affiche un numéro, une pochette, le titre, l'artiste et le
      genre.
- [ ] Un appui lance le morceau.
- [ ] Un appui long insère le morceau juste après le titre en cours.
- [ ] Le mini-lecteur reste visible pendant la consultation de la liste.
- [ ] La liste reste fluide avec 37 morceaux.

**Cas limites.** Bibliothèque vide, pochette absente, titre très long.

---

#### EF-07 — Favoris persistants

**Priorité :** Must — **État :** Livré

**Description.** Depuis le lecteur plein écran, un cœur permet d'ajouter ou de
retirer le morceau en cours des favoris. Le choix est enregistré dans SQLite et
le morceau rejoint immédiatement l'onglet Favoris de la Bibliothèque.

**Critères d'acceptation.**

- [ ] Le cœur est actif lorsque le morceau est déjà aimé.
- [ ] Un appui ajoute le morceau aux favoris et met le cœur à jour.
- [ ] Un second appui le retire des favoris.
- [ ] Le morceau apparaît ou disparaît immédiatement de l'onglet Favoris.
- [ ] Les favoris sont conservés après fermeture et redémarrage de
      l'application.
- [ ] Les favoris sont conservés après mise à jour de l'APK avec `adb install -r`.
- [ ] Un favori reste accessible même s'il n'est plus dans la file d'attente.
- [ ] Une erreur d'écriture ne bloque pas l'interface et est journalisée.
- [ ] L'onglet Favoris affiche un message dédié lorsqu'il est vide.

**Cas limites.** Base indisponible, identifiant inconnu, double appui rapide.

---

#### EF-08 — Bibliothèque : artistes et fiche artiste

**Priorité :** Must — **État :** Livré

**Description.** Le sous-onglet Artistes regroupe les morceaux par artiste. Les
artistes sont mélangés à l'ouverture. Un appui ouvre la fiche de l'artiste avec
tous ses morceaux disponibles.

**Critères d'acceptation.**

- [ ] Chaque artiste disposant au moins d'un morceau est affiché une seule fois.
- [ ] L'ordre des artistes est mélangé à l'ouverture.
- [ ] Un appui ouvre la fiche de l'artiste.
- [ ] La fiche affiche le nom, l'image, la couleur et le nombre de morceaux.
- [ ] La fiche liste tous les morceaux de l'artiste.
- [ ] Aucun morceau ne démarre automatiquement à l'ouverture de la fiche.
- [ ] Un appui sur un morceau le lance et referme la fiche.
- [ ] Une image manquante est remplacée par une pochette de secours.

**Cas limites.** Artiste sans image, artiste avec un seul morceau, nom long.

---

#### EF-09 — Mini-lecteur permanent après le premier choix

**Priorité :** Must — **État :** Livré

**Description.** Dès qu'un morceau a été choisi, un mini-lecteur flottant
apparaît au-dessus de la navigation, sur les trois onglets. Il affiche la
pochette, le titre, l'artiste, un bouton lecture/pause, un bouton suivant et une
fine barre de progression.

**Critères d'acceptation.**

- [ ] Au premier lancement, aucun mini-lecteur n'est visible.
- [ ] Après le premier choix d'un morceau, le mini-lecteur apparaît.
- [ ] Il reste visible sur les trois onglets.
- [ ] La pochette, le titre et l'artiste correspondent au morceau en cours.
- [ ] Le bouton lecture/pause reflète l'état réel de lecture.
- [ ] Le bouton suivant passe au morceau suivant de la file.
- [ ] La barre de progression suit la position de lecture.
- [ ] Un appui sur le mini-lecteur ouvre le lecteur plein écran.
- [ ] Le mini-lecteur ne masque pas la navigation.

**Cas limites.** File vide, source audio indisponible, morceau de très longue
durée.

---

#### EF-10 — Lecteur plein écran

**Priorité :** Must — **État :** Livré

**Description.** Le lecteur s'ouvre comme une feuille modale depuis le bas. Il
reprend la teinte de l'artiste, affiche une grande pochette, le titre, l'artiste,
le favori, un curseur de position avec les temps, les contrôles de lecture et un
réglage de volume.

**Critères d'acceptation.**

- [ ] Le lecteur s'ouvre depuis le mini-lecteur.
- [ ] La pochette, le titre et l'artiste sont affichés.
- [ ] Le fond reprend la teinte de l'artiste.
- [ ] Le curseur de position reflète la position réelle.
- [ ] Le déplacement du curseur change la position de lecture.
- [ ] Les temps courant et total sont affichés au format `m:ss`.
- [ ] Les contrôles aléatoire, précédent, lecture/pause, suivant et répétition
      sont présents.
- [ ] Le bouton lecture/pause est visuellement prioritaire.
- [ ] Le favori est accessible et reflète l'état courant.
- [ ] Le volume est accessible sans quitter le lecteur.
- [ ] Le lecteur se ferme sans interrompre la lecture.
- [ ] Le titre reste centré, avec ou sans paroles.

**Cas limites.** Durée inconnue, position supérieure à la durée, source absente.

---

#### EF-11 — File d'attente consultable et modifiable

**Priorité :** Should — **État :** Livré

**Description.** Le lecteur propose un panneau « File d'attente ». Le morceau en
cours est mis en avant, suivi des titres à venir. Chaque titre à venir peut être
réordonné par glissement, retiré ou lancé.

**Critères d'acceptation.**

- [ ] Le panneau s'ouvre depuis le lecteur.
- [ ] Le morceau en cours est identifié comme tel.
- [ ] Les titres à venir sont listés dans l'ordre de lecture.
- [ ] Un glissement réordonne les titres à venir.
- [ ] Le titre en cours ne peut pas être retiré ni déplacé.
- [ ] La croix retire un titre à venir.
- [ ] Un appui sur un titre à venir le lance.
- [ ] Un appui long sur un titre de la bibliothèque ou des nouveautés l'insère
      juste après le morceau en cours.
- [ ] Un titre déjà présent dans la file n'est pas dupliqué par « lire ensuite » ;
      il est déplacé.
- [ ] Un message s'affiche lorsque la file n'a plus de titre à venir.

**Cas limites.** File réduite à un seul titre, réordonnancement extrême,
suppression du dernier titre à venir.

---

#### EF-12 — Lecture aléatoire

**Priorité :** Should — **État :** Livré

**Description.** Le mode aléatoire mélange uniquement les titres à venir. Le
morceau en cours n'est pas interrompu. La désactivation restaure l'ordre
d'origine lorsque celui-ci est encore connu.

**Critères d'acceptation.**

- [ ] Le bouton s'illumine en vert lorsqu'il est actif.
- [ ] L'activation ne change pas le morceau en cours.
- [ ] Les titres à venir sont mélangés.
- [ ] La désactivation restaure l'ordre d'origine connu.
- [ ] Le morceau en cours reste le même après désactivation.
- [ ] L'activation est sans effet visible sur une file d'un seul titre.
- [ ] L'état du mode est reflété dans le lecteur.

**Cas limites.** File vide, file d'un titre, activation/désactivation répétée,
nouvelle collection chargée pendant que le mode est actif.

---

#### EF-13 — Répétition de la file

**Priorité :** Should — **État :** Partiel — défaut signalé, correction reportée

**Description.** Le mode répétition doit renvoyer au début de la file après le
dernier titre. Sans répétition, la lecture s'arrête sur le dernier titre.

**Critères d'acceptation.**

- [ ] Le bouton s'illumine en vert lorsqu'il est actif.
- [ ] Sans répétition, la lecture s'arrête à la fin du dernier titre.
- [ ] Avec répétition, le premier titre de la file est relancé après le dernier.
- [ ] Le mode est reflété dans le lecteur.
- [ ] L'activation ou la désactivation ne modifie pas le morceau en cours.
- [ ] Le comportement est identique pour une file d'un seul titre.

**Constat.** Le contrôleur de lecture est couvert par un test automatisé, mais
un défaut d'exécution a été signalé sur appareil. La correction est
explicitement reportée par le demandeur. Voir la section 13.

---

#### EF-14 — Réglage du volume

**Priorité :** Should — **État :** Livré

**Description.** Un curseur dans le lecteur règle directement le volume du
moteur audio, sans état intermédiaire.

**Critères d'acceptation.**

- [ ] Le curseur va de 0 (muet) à 1 (maximum).
- [ ] Le changement est appliqué immédiatement au moteur audio.
- [ ] Le volume est conservé lors du changement de morceau dans la session.
- [ ] Le volume par défaut est audible sans être maximal.
- [ ] Le réglage ne provoque pas de coupure ni de redémarrage du morceau.

**Cas limites.** Volume à 0, changement rapide, source absente (mode simulé).

---

#### EF-15 — Paroles synchronisées

**Priorité :** Should — **État :** Livré

**Description.** Lorsqu'un morceau possède des paroles, le lecteur affiche une
icône et un badge. La pochette ou l'icône bascule vers les paroles. La ligne en
cours est mise en avant et le reste est estompé. Un appui sur une ligne déplace
la lecture à cet instant.

**Critères d'acceptation.**

- [ ] L'icône et le badge n'apparaissent que si le morceau possède des paroles.
- [ ] Un appui sur la pochette ou l'icône ouvre les paroles.
- [ ] La ligne correspondant à la position courante est mise en avant.
- [ ] Les autres lignes sont estompées.
- [ ] Un appui sur une ligne déplace la lecture à l'instant correspondant.
- [ ] Le défilement manuel met le suivi automatique en pause.
- [ ] Une pastille « Revenir aux paroles » apparaît après un défilement manuel.
- [ ] La pastille recentre la ligne chantée, même après un grand défilement.
- [ ] Le retour à la pochette est possible.
- [ ] Un fichier de paroles non marqué comme synchronisé reste lisible et ne
      provoque pas d'exception.
- [ ] L'interface reste fluide pendant le défilement.

**Cas limites.** Fichier de paroles absent, JSON invalide, horodatages
désordonnés, morceau sans paroles.

**Note éditoriale.** Les cinq jeux de paroles embarqués sont des textes de
démonstration originaux. Ils doivent être remplacés par les textes officiels
sous licence avant toute diffusion publique.

---

#### EF-16 — Notifications et message de bienvenue

**Priorité :** Could — **État :** Livré (statique)

**Description.** Le bouton en forme de cloche, avec un point jaune, ouvre une
feuille contenant un message de bienvenue statique. Aucune notification push
n'est envoyée.

**Critères d'acceptation.**

- [ ] La cloche est visible dans l'en-tête.
- [ ] Le point jaune est affiché.
- [ ] Un appui ouvre la feuille de message.
- [ ] La feuille se ferme sans perturber la lecture.
- [ ] Aucun message ne s'affiche en dehors de cette action.

**Cas limites.** Ouverture répétée, lecture en cours.

---

#### EF-17 — Persistance locale et migration de schéma

**Priorité :** Must — **État :** Livré

**Description.** La bibliothèque est stockée dans une base SQLite locale, créée
et remplie au premier lancement depuis le seed embarqué. Les favoris et l'état
d'onboarding sont persistés. Une base créée par une version antérieure est
migrée sans perte.

**Critères d'acceptation.**

- [ ] Au premier lancement, la base est créée et remplie avec 6 genres,
      9 artistes et 37 morceaux.
- [ ] Les contraintes d'intégrité sont actives à chaque ouverture.
- [ ] Un morceau référence toujours un artiste et un genre existants.
- [ ] Dans le seed, les identifiants de morceau et les positions sont uniques.
- [ ] Une durée nulle ou négative est refusée.
- [ ] Un favori est persisté dans la colonne `liked`.
- [ ] Une base version 1 reçoit la colonne `liked` sans perdre ses données.
- [ ] Le chargement de la bibliothèque fonctionne après migration.
- [ ] Si SQLite n'est pas disponible, le seed embarqué sert de repli.
- [ ] Le marqueur d'onboarding est relu après redémarrage.

**Cas limites.** Base corrompue, disque plein, migration interrompue, seed
invalide.

---

#### EF-18 — Robustesse en cas d'audio indisponible

**Priorité :** Must — **État :** Livré

**Description.** Si un fichier audio est absent, illisible ou si le moteur audio
échoue, l'application ne doit pas planter. L'interface reste utilisable et une
progression simulée permet de continuer à naviguer.

**Critères d'acceptation.**

- [ ] Un morceau sans source ne provoque pas de plantage.
- [ ] Un message technique est journalisé, sans alerte intrusive.
- [ ] L'interface reste navigable.
- [ ] La progression est simulée pour les commandes de lecture.
- [ ] Le passage au morceau suivant reste possible.
- [ ] L'erreur est corrigée dès qu'une source valide est disponible.

**Cas limites.** Asset manquant, fichier externe corrompu, moteur audio
indisponible, changement rapide de morceau.

---

#### EF-19 — Cycle de vie, reprise et lecture en arrière-plan

**Priorité :** Could — **État :** Partiel / hors périmètre 1.0

**Description attendue à terme.** La lecture devrait pouvoir continuer lorsque
l'application passe en arrière-plan ou que l'écran est verrouillé, avec des
contrôles système et une notification média. La file, la position, le mode
aléatoire, la répétition et le volume devraient être restaurés au redémarrage.

**Critères d'acceptation (cible future).**

- [ ] La lecture continue lorsque l'application est en arrière-plan.
- [ ] Une notification média permet lecture/pause et suivant/précédent.
- [ ] La file et la position sont restaurées après redémarrage.
- [ ] Les modes aléatoire et répétition sont restaurés.
- [ ] Le volume est restauré.
- [ ] Une interruption (appel, débranchement d'écouteurs) est gérée proprement.

**Constat.** Non implémenté dans la version 1.0. La lecture n'est pas garantie
en arrière-plan et aucun état de lecture n'est restauré. Voir section 13.

---

#### EF-20 — États vides et cas limites

**Priorité :** Must — **État :** Livré

**Description.** Chaque écran doit présenter un état vide ou une solution de
repli compréhensible : pas de favori, pas de résultat de recherche, catalogue
vide, image absente, source audio absente.

**Critères d'acceptation.**

- [ ] L'onglet Favoris vide affiche un message explicite.
- [ ] Une recherche sans résultat affiche un message et des suggestions.
- [ ] Une bibliothèque vide affiche un message dédié au lieu d'un écran blanc.
- [ ] Une pochette manquante est remplacée par un visuel de secours.
- [ ] Une file d'attente sans titre à venir affiche un message.
- [ ] Aucun état vide ne provoque d'exception non gérée.

**Cas limites.** Tous les cas ci-dessus combinés à une lecture en cours.

---

## 5. Règles métier

| Réf. | Règle |
|---|---|
| RM-01 | Aucun morceau ne démarre sans un choix explicite de l'utilisateur. |
| RM-02 | Activer ou couper l'aléatoire ne change jamais le morceau en cours. |
| RM-03 | La file d'attente ne contient jamais deux fois le même morceau. |
| RM-04 | « Lire ensuite » déplace un morceau déjà présent au lieu de le dupliquer. |
| RM-05 | Le morceau en cours ne peut être ni retiré ni déplacé de la file. |
| RM-06 | La répétition ne s'applique qu'à la fin de la file. |
| RM-07 | Le favori est la seule donnée utilisateur persistée dans SQLite. |
| RM-08 | L'état d'onboarding est persisté dans un fichier marqueur local. |
| RM-09 | La file, la position, le volume, l'aléatoire et la répétition sont volatils. |
| RM-10 | Le catalogue embarqué fait foi ; aucune mise à jour distante n'est possible. |
| RM-11 | La recherche exige la présence de tous les mots saisis. |
| RM-12 | La ligne de paroles active est la dernière dont l'horodatage précède la position. |
| RM-13 | Les identifiants de morceau sont stables et ne doivent pas être réutilisés. |
| RM-14 | Un artiste ou un genre utilisé ne peut pas être supprimé. |
| RM-15 | Une image absente ne doit jamais empêcher l'affichage d'un morceau. |

---

## 6. Exigences non fonctionnelles

Les valeurs ci-dessous sont des **cibles à valider** sur l'appareil de référence.
Elles ne constituent pas des mesures déjà réalisées, sauf mention explicite.

### 6.1 Fonctionnement hors ligne

**ENF-01 — Autonomie réseau.** L'application doit fonctionner intégralement sans
connexion : onboarding, accueil, recherche, lecture, favoris, paroles, file
d'attente.

- [ ] Toutes les fonctions sont utilisables en mode avion.
- [ ] Aucun écran n'affiche d'erreur réseau.
- [ ] Le manifeste fusionné de l'APK de release ne déclare aucune permission
      `INTERNET`.
- [ ] Aucun contenu n'est chargé depuis une URL distante.

**Note.** Le build de debug ajoute la permission `INTERNET` pour les outils
Flutter ; elle ne doit pas figurer dans l'APK de release. La permission
`ACCESS_NETWORK_STATE` peut être apportée par la bibliothèque média (Media3)
sans qu'aucun contenu ne soit téléchargé.

**ENF-02 — Confidentialité.** Aucune donnée personnelle n'est collectée,
transmise ou partagée.

- [ ] Aucun outil analytique ni SDK publicitaire n'est intégré.
- [ ] Les favoris et le marqueur d'onboarding restent sur l'appareil.
- [ ] La désinstallation efface toutes les données de l'application.
- [ ] Aucun identifiant publicitaire n'est lu.

### 6.2 Compatibilité

**ENF-03 — Plateforme.** Android 7.0 (API 24) minimum, cible API 36.

- [ ] L'APK s'installe sur un appareil API 24 ou supérieur.
- [ ] L'APK `arm64-v8a` s'installe sur l'appareil de référence.
- [ ] L'application se lance sans erreur sur l'appareil de référence.
- [ ] Le comportement est identique en mode portrait et paysage, ou le mode est
      explicitement limité.
- [ ] La version iOS n'est pas livrée pour la version 1.0.

### 6.3 Performance

**ENF-04 — Démarrage.** Cible proposée : accueil affiché en moins de 3 secondes
sur l'appareil de référence, hors premier lancement.

- [ ] Le premier lancement (création de la base) reste inférieur à 8 secondes.
- [ ] Les lancements suivants affichent l'accueil en moins de 3 secondes.
- [ ] Aucun écran blanc prolongé n'est observé.

**ENF-05 — Fluidité.** Cible proposée : 60 images par seconde sur les
défilements et les animations principales.

- [ ] Le défilement de l'accueil reste fluide.
- [ ] Le défilement des paroles reste fluide.
- [ ] Le changement d'onglet ne provoque pas de saccade visible.
- [ ] Les pochettes sont décodées à une taille adaptée à l'affichage.

**ENF-06 — Recherche.** Cible proposée : résultats affichés en moins de 100 ms
pour 37 morceaux.

- [ ] La saisie ne provoque pas de blocage de l'interface.
- [ ] Les résultats se mettent à jour à chaque frappe.

### 6.4 Taille et stockage

**ENF-07 — Poids de l'application.** Le poids est assumé et documenté.

- [ ] L'APK contient les 37 MP3, soit environ 259 Mo d'audio.
- [ ] Le total des assets est d'environ 261 Mo.
- [ ] L'APK final fait environ 300 Mo par architecture.
- [ ] L'utilisateur est informé du poids avant installation (fiche de
      distribution ou message).
- [ ] L'espace nécessaire inclut l'APK et le cache d'extraction audio.

**ENF-08 — Cache audio.** Le cache d'extraction de `just_audio` est vidé au
démarrage pour garantir la version embarquée.

- [ ] Une mise à jour de l'APK ne lit pas un ancien MP3 mis en cache.
- [ ] Le nettoyage n'empêche pas le démarrage en cas d'échec.
- [ ] L'utilisateur dispose d'assez d'espace pour l'écoute (environ 259 Mo
      supplémentaires si tout le catalogue est lu).

### 6.5 Fiabilité et maintenabilité

**ENF-09 — Robustesse.** Aucun plantage ne doit résulter d'une source absente,
d'une base indisponible ou d'un fichier de paroles invalide.

- [ ] Les erreurs sont journalisées sans interrompre l'interface.
- [ ] L'application reste utilisable après une erreur de lecture.
- [ ] Une base absente est recréée et remplie depuis le seed au lancement.

**ENF-10 — Qualité du code.** Le projet doit rester analysable et testé.

- [ ] `flutter analyze` ne remonte aucun problème.
- [ ] Les 60 tests automatisés passent.
- [ ] Aucun test n'est ignoré sans justification.
- [ ] Les ajouts de dépendances sont validés explicitement.

**ENF-11 — Sécurité et signature.**

- [ ] Aucun secret n'est stocké dans le dépôt.
- [ ] La base SQLite reste dans le stockage privé de l'application.
- [ ] La version de production utilise une clé de release dédiée.
- [ ] La version 1.0 signée en debug est réservée aux tests internes.

### 6.6 Accessibilité et langue

**ENF-12 — Langue.** L'interface et les métadonnées sont en français.

- [ ] Les textes affichés sont en français.
- [ ] Les caractères accentués s'affichent correctement.
- [ ] Les formats de durée sont lisibles (`m:ss`).

**ENF-13 — Accessibilité.** Cible proposée, à valider.

- [ ] Les boutons icônes disposent d'une infobulle ou d'un libellé sémantique.
- [ ] Les contrastes principaux sont suffisants sur fond sombre.
- [ ] Le texte agrandi jusqu'à 130 % ne provoque pas de débordement bloquant.
- [ ] Les actions principales restent atteignables au pouce.

### 6.7 Distribution

**ENF-14 — Installation et mise à jour.**

- [ ] L'APK s'installe par `adb install`.
- [ ] Une mise à jour avec `adb install -r` conserve les favoris et le marqueur
      d'onboarding.
- [ ] Une désinstallation suivie d'une réinstallation repart d'un état neuf.
- [ ] Les trois APK par architecture sont produits par
      `--split-per-abi`.
- [ ] L'APK destiné à l'appareil de référence est `arm64-v8a`.

---

## 7. Contenu, droits et qualité éditoriale

### 7.1 Composition du catalogue

| Élément | Quantité | Remarque |
|---|---|---|
| Genres | 6 | Afro-folk, Afropop, Gospel, Traditionnel, World, Tchink System |
| Artistes | 9 | Dont Angélique Kidjo, Afafa, Sagbohan Danialou, Kiri Kanta |
| Morceaux | 37 | MP3 192 kbps |
| Pochettes | 9 | Une par artiste |
| Jeux de paroles | 5 | Paroles de démonstration |
| Poids audio | 259,4 Mo | 37 fichiers |
| Poids total des assets | 260,8 Mo | Hors code et bibliothèques |

Le catalogue détaillé et la taxonomie figurent dans `AUDIO_NOTES.md`.

### 7.2 Exigences de droits

**CR-01 — Autorisation de diffusion.** Chaque morceau doit disposer d'une
autorisation écrite couvrant l'enregistrement et l'œuvre musicale, pour le
territoire et la durée de diffusion prévus.

**CR-02 — Crédits.** Les artistes, auteurs, compositeurs et ayants droit doivent
être crédités dans l'application ou dans les documents de distribution.

**CR-03 — Paroles.** Les paroles diffusées doivent être officielles et
autorisées. Les textes actuels sont des textes de démonstration à remplacer.

**CR-04 — Images.** Les photos d'artistes et pochettes doivent être utilisables
et créditées.

**CR-05 — Retrait.** Un ayant droit doit pouvoir demander le retrait d'un titre.
La procédure et le délai de traitement sont à définir : **[À compléter]**.

**CR-06 — Traçabilité.** Un registre des autorisations doit associer chaque
morceau à sa pièce justificative : **[À compléter]**.

**CR-07 — Conformité.** Les formalités auprès de l'organisme de gestion
collective compétent doivent être vérifiées : **[À préciser]**.

**CR-08 — Diffusion.** Aucune diffusion publique avant validation des droits,
même si l'application est techniquement prête.

### 7.3 Qualité éditoriale

- Les titres, artistes et genres doivent être orthographiés correctement.
- Les durées doivent correspondre aux fichiers audio.
- Les pochettes doivent être au format carré, sans déformation.
- Les paroles doivent être horodatées et relues.
- Les genres doivent rester cohérents avec la taxonomie validée.
- Un morceau sans pochette doit tout de même s'afficher avec un visuel de
  secours.

### 7.4 Mentions et informations légales

La version 1.0 ne comporte pas encore d'écran de mentions légales. Avant une
distribution publique, l'application doit inclure :

- [ ] une mention des droits et crédits ;
- [ ] une politique de confidentialité ;
- [ ] les conditions d'utilisation ;
- [ ] un contact pour les ayants droit ;
- [ ] la version de l'application et l'identifiant de build.

---

## 8. Données et persistance

### 8.1 Entités fonctionnelles

| Entité | Champs principaux | Persistance |
|---|---|---|
| Genre | identifiant, slug, nom, couleur, icône | SQLite |
| Artiste | identifiant, slug, nom, pochette, teinte | SQLite |
| Morceau | identifiant, titre, artiste, genre, position, durée, audio, pochette, paroles, favori | SQLite |
| Ligne de paroles | horodatage, texte | Asset JSON |
| Favori | identifiant du morceau, indicateur `liked` | SQLite |
| Onboarding | indicateur de passage | Fichier marqueur |
| File d'attente | liste ordonnée de morceaux | Mémoire volatile |
| Position de lecture | temps courant | Mémoire volatile |
| Volume, aléatoire, répétition | état de session | Mémoire volatile |

### 8.2 Schéma SQLite (version 2)

```sql
CREATE TABLE genres (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  slug  TEXT NOT NULL UNIQUE,
  name  TEXT NOT NULL UNIQUE,
  color TEXT NOT NULL,
  icon  TEXT NOT NULL
);

CREATE TABLE artists (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  slug       TEXT NOT NULL UNIQUE,
  name       TEXT NOT NULL UNIQUE,
  cover_path TEXT,
  tint       TEXT NOT NULL
);

CREATE TABLE tracks (
  id               TEXT PRIMARY KEY,
  title            TEXT NOT NULL,
  artist_id        INTEGER NOT NULL,
  genre_id         INTEGER NOT NULL,
  position         INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
  audio_path       TEXT NOT NULL,
  cover_path       TEXT,
  lyrics_path      TEXT,
  lyrics_synced    INTEGER NOT NULL DEFAULT 0
                   CHECK (lyrics_synced IN (0, 1)),
  liked            INTEGER NOT NULL DEFAULT 0
                   CHECK (liked IN (0, 1)),
  FOREIGN KEY (artist_id) REFERENCES artists (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (genre_id) REFERENCES genres (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE (artist_id, title)
);

CREATE INDEX idx_tracks_artist   ON tracks (artist_id);
CREATE INDEX idx_tracks_genre    ON tracks (genre_id);
CREATE INDEX idx_tracks_position ON tracks (position);
```

**Invariants.**

- `PRAGMA foreign_keys = ON` à chaque ouverture.
- Un artiste ou un genre utilisé ne peut pas être supprimé.
- Un morceau possède toujours un artiste et un genre.
- Un identifiant de morceau est unique.
- Un couple `(artiste, titre)` est unique.
- `liked` et `lyrics_synced` valent 0 ou 1.
- La durée est strictement positive.

**Migration.** Une base en version 1 reçoit la colonne `liked` via `onUpgrade`,
sans perte de données.

### 8.3 Seed et cycle de vie des données

1. Au premier lancement, la base est créée.
2. `assets/data/library.json` est lu et inséré.
3. Les paroles sont chargées depuis les assets au moment de la construction de
   la bibliothèque.
4. Les favoris sont écrits dans `tracks.liked`.
5. Si SQLite n'est pas disponible, le même seed est lu directement.
6. Une mise à jour de l'application ne remplace pas la base existante ; les
   favoris sont conservés.

### 8.4 Matrice de persistance

| Donnée | Survit à la fermeture | Survit à `adb install -r` | Survit à une désinstallation |
|---|---|---|---|
| Favoris | Oui | Oui | Non |
| Onboarding terminé | Oui | Oui | Non |
| File d'attente | Non | Non | Non |
| Position de lecture | Non | Non | Non |
| Volume | Non | Non | Non |
| Aléatoire / répétition | Non | Non | Non |
| Playlists | Non implémentées | — | — |

### 8.5 Données personnelles

L'application ne collecte aucune donnée personnelle. Les seules données
stockées sont les favoris et le marqueur d'onboarding, dans le stockage privé de
l'application. Elles ne sont ni lues ni transmises par un tiers.

---

## 9. Livrables

| Réf. | Livrable | Contenu | Échéance |
|---|---|---|---|
| L-01 | Code source | Dépôt Flutter, branche de livraison | [À compléter] |
| L-02 | APK de production | `app-arm64-v8a-release.apk` | [À compléter] |
| L-03 | APK par architecture | `armeabi-v7a`, `arm64-v8a`, `x86_64` | [À compléter] |
| L-04 | Documentation produit | `EVOLUTION.md`, `SPEC.md`, `AUDIO_NOTES.md` | [À compléter] |
| L-05 | Guide de build | Commandes de compilation et d'installation | [À compléter] |
| L-06 | Rapport de tests | Résultats `analyze` et tests automatisés | [À compléter] |
| L-07 | Sources graphiques | SVG de l'icône, pochettes, polices | [À compléter] |
| L-08 | Registre des droits | Autorisations et crédits par morceau | [À compléter] |
| L-09 | Mentions légales | Crédits, confidentialité, contact | [À compléter] |
| L-10 | Fiche de version | Notes de version et correctifs | [À compléter] |

---

## 10. Recette et stratégie de tests

### 10.1 Environnement de recette

| Élément | Valeur |
|---|---|
| Système de développement | Windows |
| Framework | Flutter / Dart, SDK `^3.13.7` |
| Appareil de référence | TECNO KL5, architecture `arm64-v8a` |
| Version Android de l'appareil | [À compléter] |
| Version testée | 1.0.0+1 |
| Mode | Release |
| Réseau | Mode avion activé pour la recette hors ligne |
| Données | Application réinstallée ou données effacées avant le parcours initial |

### 10.2 Tests automatisés

**Commande :** `flutter test`  
**Résultat attendu :** 60 tests passent.  
**Commande :** `flutter analyze`  
**Résultat attendu :** aucun problème.

| Fichier | Couverture |
|---|---|
| `test/database_test.dart` | Schéma, seed, clés étrangères, favoris, migration v1, chargement |
| `test/library_seed_test.dart` | Intégrité du seed, références, unicité, assets, paroles |
| `test/library_search_test.dart` | Casse, accents, genre, mots multiples, requête vide |
| `test/player_controller_test.dart` | File, lecture, favoris, aléatoire, répétition, moteur réel, volume, simulation |
| `test/onboarding_store_test.dart` | Marqueur absent/présent, dossier inaccessible |
| `test/widget_test.dart` | Onboarding, accueil, recherche, artistes, favoris, paroles, file, notifications |

### 10.3 Plan de recette manuelle

| ID | Scénario | Résultat attendu |
|---|---|---|
| R-01 | Installer l'APK sur un appareil vierge | Installation réussie, icône Benin Vibes visible |
| R-02 | Lancer l'application | Onboarding affiché |
| R-03 | Terminer l'onboarding avec « Commencer » | Accueil affiché |
| R-04 | Fermer et relancer l'application | Accueil affiché directement |
| R-05 | Effacer les données puis relancer | Onboarding réaffiché |
| R-06 | Activer le mode avion et parcourir l'application | Toutes les fonctions restent disponibles |
| R-07 | Lancer un morceau depuis « À la une » | Lecture démarre, mini-lecteur visible |
| R-08 | Changer d'onglet pendant la lecture | Mini-lecteur toujours visible, lecture continue |
| R-09 | Ouvrir le lecteur et déplacer le curseur | Position et temps mis à jour |
| R-10 | Ajouter puis retirer un favori | Onglet Favoris mis à jour immédiatement |
| R-11 | Redémarrer l'application | Favori conservé |
| R-12 | Rechercher « kidjo », « agolo », « gospel » | Résultats cohérents |
| R-13 | Rechercher une chaîne absente | Message et suggestions affichés |
| R-14 | Ouvrir un genre et « Tout lire » | Tous les titres du genre sont dans la file |
| R-15 | Ouvrir une fiche artiste | Aucun morceau ne démarre seul |
| R-16 | Réordonner, retirer et lancer un titre de la file | Comportement conforme |
| R-17 | Activer l'aléatoire | Le morceau en cours ne change pas |
| R-18 | Activer la répétition et laisser la file se terminer | Le premier titre est relancé (défaut connu) |
| R-19 | Ouvrir les paroles et faire défiler | Suivi en pause, pastille de retour visible |
| R-20 | Appuyer sur « Revenir aux paroles » après un grand défilement | Recentrage correct |
| R-21 | Ouvrir la cloche | Message de bienvenue affiché |
| R-22 | Mettre à jour l'APK avec `adb install -r` | Favoris et onboarding conservés |
| R-23 | Désinstaller puis réinstaller | État neuf, onboarding affiché |
| R-24 | Vérifier le poids de l'APK | Environ 300 Mo |
| R-25 | Vérifier le manifeste de l'APK | Aucune permission `INTERNET` |

### 10.4 Critères de recette

La version 1.0 est acceptée si :

- [ ] toutes les exigences **Must** sont satisfaites ;
- [ ] aucun défaut bloquant ou critique n'est ouvert ;
- [ ] `flutter analyze` ne remonte aucun problème ;
- [ ] les 60 tests automatisés passent ;
- [ ] l'APK s'installe et démarre sur l'appareil de référence ;
- [ ] le parcours complet fonctionne en mode avion ;
- [ ] les favoris et l'onboarding survivent à un redémarrage ;
- [ ] l'icône de l'application est celle de Benin Vibes ;
- [ ] les droits de diffusion sont documentés pour les morceaux distribués ;
- [ ] les écarts connus sont acceptés et listés.

### 10.5 Jeu de données de recette

- Catalogue complet : 6 genres, 9 artistes, 37 morceaux.
- Cas particuliers à couvrir :
  - morceau avec paroles synchronisées ;
  - morceau sans paroles ;
  - artiste sans image ;
  - recherche sans résultat ;
  - file d'un seul titre ;
  - source audio volontairement absente.

### 10.6 Réinitialisation

```powershell
# Repartir d'un état neuf
adb uninstall com.example.benin_vibes
adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

# Ou conserver l'installation et effacer les données
adb shell pm clear com.example.benin_vibes
```

---

## 11. Organisation, planning et budget

### 11.1 Rôles et responsabilités

| Rôle | Responsable | Responsabilités |
|---|---|---|
| Commanditaire | [À compléter] | Validation du périmètre et de la recette |
| Chef de produit | [À compléter] | Priorisation, contenu, coordination |
| Développement Flutter | [À compléter] | Application, tests, builds |
| Design | [À compléter] | Identité visuelle, icône, écrans |
| Contenu et droits | [À compléter] | Catalogue, autorisations, crédits |
| Recette | [À compléter] | Tests manuels et validation |
| Distribution | [À compléter] | Signature, APK, diffusion |

### 11.2 Phases et jalons

| Phase | Contenu | Début | Fin | Statut |
|---|---|---|---|---|
| Cadrage | Besoin, périmètre, priorités | [À compléter] | [À compléter] | En cours |
| Conception | Écrans, identité, architecture | [À compléter] | [À compléter] | Réalisé |
| Développement | Fonctions v1.0 | [À compléter] | [À compléter] | Réalisé en grande partie |
| Contenu et droits | Catalogue, autorisations | [À compléter] | [À compléter] | À compléter |
| Recette interne | Tests automatisés et manuels | [À compléter] | [À compléter] | À planifier |
| Pilote | Diffusion restreinte | [À compléter] | [À compléter] | À planifier |
| Mise à disposition | Version validée | [À compléter] | [À compléter] | À planifier |

### 11.3 Budget prévisionnel

| Poste | Détail | Montant |
|---|---|---|
| Développement | Temps de développement et tests | [À compléter] |
| Design | Icône, pochettes, direction artistique | [À compléter] |
| Contenu et droits | Autorisations, paroles officielles | [À compléter] |
| Recette | Appareils et temps de test | [À compléter] |
| Distribution | Signature, publication, support | [À compléter] |
| Maintenance | Correctifs et mises à jour | [À compléter] |
| **Total** | | **[À compléter]** |

### 11.4 Gouvernance

- Toute évolution du périmètre fait l'objet d'un avenant à ce document.
- Toute nouvelle dépendance doit être validée explicitement.
- Toute modification du catalogue doit être tracée dans le registre des droits.
- Les versions sont identifiées par `versionName` et `versionCode`.

---

## 12. Risques

| Réf. | Risque | Probabilité | Impact | Mesure de réduction |
|---|---|---|---|---|
| RI-01 | Droits de diffusion incomplets | Moyenne | Critique | Registre des autorisations, validation avant diffusion |
| RI-02 | Paroles de démonstration diffusées | Élevée | Élevé | Remplacer par les textes officiels autorisés |
| RI-03 | APK très volumineux | Certaine | Moyen | Documenter le poids, limiter le catalogue, envisager une installation guidée |
| RI-04 | Cache audio dupliqué sur l'appareil | Moyenne | Moyen | Nettoyage au démarrage, information utilisateur |
| RI-05 | Signature debug en production | Certaine | Critique | Créer une clé de release avant toute publication |
| RI-06 | Identifiant `com.example` | Certaine | Élevé | Choisir un identifiant définitif avant publication |
| RI-07 | Défaut de répétition | Avérée | Moyen | Correction planifiée et test sur appareil |
| RI-08 | Absence de lecture en arrière-plan | Certaine | Moyen | Documenter la limite, prévoir `audio_service` |
| RI-09 | Perte des favoris lors d'une manipulation | Faible | Moyen | Sauvegarde locale documentée, tests de migration |
| RI-10 | Appareils Android anciens ou variés | Moyenne | Moyen | Tester API 24 et appareil de référence |
| RI-11 | Recette limitée à un seul appareil physique | Moyenne | Moyen | Tester au moins un second appareil ou un émulateur API 24 |
| RI-12 | Catalogue figé à chaque build | Certaine | Moyen | Accepté en v1.0, prévoir un catalogue distant en v2 |
| RI-13 | Absence de version iOS | Certaine | Faible | Hors périmètre, à arbitrer ultérieurement |
| RI-14 | Absence de mentions légales | Certaine | Élevé | Ajouter les écrans avant diffusion publique |

---

## 13. Écarts connus et dette technique

| Réf. | Écart | Impact | Décision / statut |
|---|---|---|---|
| EC-01 | La répétition est signalée comme non fonctionnelle sur appareil | Le dernier titre ne relance pas la file | Reporté à la demande du commanditaire ; test unitaire existant |
| EC-02 | Pas de lecture en arrière-plan ni de contrôles système | La lecture n'est pas garantie hors application | Hors périmètre v1.0 ; évolution prévue |
| EC-03 | Playlists non implémentées | Pas de listes personnalisées | Reporté en version ultérieure |
| EC-04 | File, position, volume, aléatoire et répétition non persistés | Reprise impossible après redémarrage | Accepté en v1.0 |
| EC-05 | Le dossier `assets/artists/` n'est pas exploité par les fiches artistes | Six images dédiées restent inutilisées ; les fiches s'appuient sur les pochettes | À nettoyer ou à utiliser |
| EC-06 | Release signée avec la clé debug | Inadapté à une publication officielle | Corriger avant diffusion publique |
| EC-07 | Identifiant `com.example.benin_vibes` | Impropre à une publication | À remplacer avant publication |
| EC-08 | `README.md` encore générique | Documentation d'accueil incomplète | À réécrire |
| EC-09 | Notifications statiques | Pas de véritable centre de notifications | Accepté en v1.0 |
| EC-10 | 5 jeux de paroles de démonstration | Risque juridique et éditorial | Remplacer par les textes officiels |
| EC-11 | Pas de mentions légales ni de crédits dans l'app | Non conforme pour une diffusion publique | À ajouter |
| EC-12 | Pas d'écran de réglages | Volume et options limités au lecteur | Accepté en v1.0 |
| EC-13 | Pas de version iOS livrée | Couverture limitée à Android | Hors périmètre |
| EC-14 | Catalogue mis à jour uniquement par build | Pas de mise à jour distante | Accepté en v1.0 |
| EC-15 | `assets/icons/` n'est pas empaqueté | Le SVG source n'est pas dans l'APK | Intentionnel ; les PNG générés suffisent |

---

## 14. Évolutions futures

| Priorité | Évolution | Objectif |
|---|---|---|
| P0 | Correction de la répétition | Fiabiliser les contrôles de lecture |
| P0 | Signature release et identifiant définitif | Permettre une diffusion officielle |
| P0 | Registre des droits et paroles officielles | Sécuriser juridiquement le catalogue |
| P1 | Lecture en arrière-plan et contrôles système | Écoute écran verrouillé |
| P1 | Reprise de la file et de la position | Continuité après redémarrage |
| P1 | Playlists personnalisées persistantes | Organisation de la bibliothèque |
| P1 | Images d'artistes dédiées et nettoyage des assets | Exploiter ou retirer les images non utilisées |
| P2 | Écran de réglages et mentions légales | Conformité et confort |
| P2 | Accessibilité renforcée | Lecteurs d'écran et textes agrandis |
| P2 | Catalogue enrichi et mise à jour distante | Actualité éditoriale |
| P3 | Version iOS | Élargir la diffusion |
| P3 | Import de fichiers locaux | Personnalisation de la bibliothèque |

---

## Annexe A — Architecture technique

### A.1 Pile technique

| Composant | Choix | Rôle |
|---|---|---|
| Framework | Flutter (Material 3) | Interface multiplateforme |
| Langage | Dart, SDK `^3.13.7` | Développement |
| Audio | `just_audio` `^0.10.6` | Lecture des MP3 embarqués |
| Base locale | `sqflite` `^2.4.2` | Bibliothèque, favoris |
| Chemins | `path` `^1.9.1` | Construction des chemins |
| Stockage applicatif | `path_provider` `^2.1.6` | Marqueur d'onboarding |
| Icônes Material | `cupertino_icons` `^1.0.8` | Icônes complémentaires |
| Tests SQLite | `sqflite_common_ffi` `^2.3.6` | Tests sur machine de développement |
| Lints | `flutter_lints` `^6.0.0` | Qualité du code |

Aucune dépendance n'a été ajoutée pour l'icône ou l'onboarding.

### A.2 Organisation du code

| Fichier / dossier | Responsabilité |
|---|---|
| `lib/main.dart` | Démarrage, chargement, onboarding, injection des dépendances |
| `lib/theme.dart` | Couleurs, typographie, thème sombre |
| `lib/data.dart` | Modèles `Track`, `Artist`, `Genre`, `Library`, recherche |
| `lib/onboarding_page.dart` | Trois écrans d'introduction |
| `lib/onboarding_store.dart` | Marqueur de passage de l'onboarding |
| `lib/home_shell.dart` | En-tête, navigation, accueil, découverte, bibliothèque, mini-lecteur |
| `lib/artist_page.dart` | Fiche artiste |
| `lib/genre_page.dart` | Fiche genre et « Tout lire » |
| `lib/now_playing_sheet.dart` | Lecteur plein écran, paroles, file d'attente |
| `lib/player_controller.dart` | État de lecture, file, favoris, aléatoire, répétition |
| `lib/disc_sleeve.dart` | Pochette et vinyle animés |
| `lib/audio/` | Abstraction du moteur audio, `just_audio`, résolution des sources |
| `lib/database/` | Schéma SQLite, seed, dépôt de bibliothèque |
| `assets/audio/` | 37 MP3 |
| `assets/covers/` | 9 pochettes |
| `assets/artists/` | Images d'artistes (dossier présent, non exploité par les fiches) |
| `assets/lyrics/` | 5 jeux de paroles JSON |
| `assets/data/library.json` | Seed de la bibliothèque |
| `assets/fonts/` | Police Outfit (300 à 800) |
| `assets/icons/app_icon.svg` | Source de l'icône, non embarquée dans l'APK |
| `tool/generate_icons.ps1` | Génération des icônes Android |
| `tool/convert_audio.ps1` | Conversion des sources audio |
| `tool/build_library_seed.ps1` | Génération du seed |
| `android/app/src/main/res/mipmap-*` | Icônes Android générées |

### A.3 Chaîne de lecture audio

1. `PlayerController` reçoit un morceau et demande une source.
2. `AudioSourceResolver` cherche d'abord un éventuel MP3 dans le stockage
   externe de l'application, puis l'asset `assets/audio/<fichier>.mp3`.
3. `JustAudioEngine` charge la source avec `setAsset`.
4. La position, la durée et l'état de lecture proviennent du moteur réel.
5. La fin d'un morceau déclenche l'enchaînement automatique.
6. Si aucune source n'est disponible, une progression simulée maintient
   l'interface utilisable.

**Cache.** `just_audio` extrait chaque MP3 dans un fichier temporaire.
`JustAudioEngine.clearAssetCache()` est appelé au démarrage pour éviter de lire
une ancienne version après une mise à jour de l'APK.

### A.4 Chaîne de contenu

1. Les sources sont déposées dans `music_in/<Artiste>/`.
2. `tool/convert_audio.ps1` produit des MP3 192 kbps, des pochettes 600 × 600 et
   des paroles JSON `[{ "t": <ms>, "text": "..." }]`.
3. `tool/build_library_seed.ps1` lit le manifeste, attribue les genres, copie les
   assets et écrit `assets/data/library.json`.
4. Au premier lancement, l'application crée SQLite et insère le seed.
5. Les paroles sont chargées depuis les assets au chargement de la bibliothèque.

### A.5 Icône et identité Android

- Source : `assets/icons/app_icon.svg`.
- Génération : `tool/generate_icons.ps1`.
- Rendu du SVG : Microsoft Edge en mode headless.
- Redimensionnement : `System.Drawing` (Windows).
- Sorties : `ic_launcher.png` (48 à 192 px) et
  `ic_launcher_foreground.png` (108 à 432 px).
- Icône adaptative : `mipmap-anydpi-v26/ic_launcher.xml` avec fond vert
  `#2FB36D`.
- Aucun paquet `flutter_launcher_icons` n'est utilisé.

### A.6 Configuration Android

| Paramètre | Valeur |
|---|---|
| `applicationId` | `com.example.benin_vibes` (à remplacer) |
| `namespace` | `com.example.benin_vibes` |
| `minSdk` | 24 |
| `targetSdk` | 36 |
| `versionName` | 1.0.0 |
| `versionCode` | 1 |
| Signature release | Clé debug (provisoire) |

### A.7 Tests

```powershell
flutter analyze
flutter test
```

Les tests SQLite utilisent `sqflite_common_ffi` sur la machine de développement.
Les tests d'interface utilisent un moteur audio factice et une bibliothèque de
test.

---

## Annexe B — Commandes de build et d'installation

### B.1 Construire les APK de release

```powershell
flutter build apk --release --split-per-abi
```

- `--release` : compilation optimisée, sans outils de debug.
- `--split-per-abi` : produit un APK par architecture processeur :
  - `app-armeabi-v7a-release.apk` ;
  - `app-arm64-v8a-release.apk` ;
  - `app-x86_64-release.apk`.

Chaque APK ne contient que les bibliothèques natives de son architecture. Les
assets, elles, sont identiques dans les trois APK.

Pour éviter la vérification réseau de Pub :

```powershell
flutter build apk --release --split-per-abi --no-pub
```

### B.2 Installer sur l'appareil

```powershell
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

- `-r` remplace l'application en conservant ses données : favoris, marqueur
  d'onboarding.
- L'appareil de référence (TECNO KL5) est en `arm64-v8a`.

### B.3 Vérifications utiles

```powershell
# Appareils connectés
adb devices

# Poids de l'APK
Get-Item build\app\outputs\flutter-apk\app-arm64-v8a-release.apk |
  Select-Object Name, Length

# Permissions du manifeste fusionné
aapt dump permissions build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

# Réinitialiser les données
adb shell pm clear com.example.benin_vibes
```

---

## Annexe C — Glossaire

| Terme | Définition |
|---|---|
| APK | Paquet d'installation Android |
| ABI | Interface binaire de l'application, liée à l'architecture du processeur |
| `arm64-v8a` | Architecture 64 bits des appareils Android récents |
| Asset | Fichier embarqué dans l'application (audio, image, paroles, police) |
| Seed | Données initiales de la bibliothèque, lues au premier lancement |
| Onboarding | Parcours de présentation affiché au premier lancement |
| Mini-lecteur | Barre de lecture réduite, visible au-dessus de la navigation |
| File d'attente | Liste ordonnée des morceaux à lire |
| Aléatoire | Mode qui mélange les titres à venir |
| Répétition | Mode qui relance la file après le dernier titre |
| Paroles synchronisées | Texte horodaté qui suit la position de lecture |
| SQLite | Base de données locale embarquée |
| Cache | Copie temporaire d'un fichier pour accélérer l'accès |
| Ayants droit | Personnes ou organismes titulaires des droits sur une œuvre |
| MoSCoW | Méthode de priorisation Must / Should / Could / Won't |
| Recette | Vérification finale du produit avant diffusion |

---

## Annexe D — Journal des versions du document

| Version | Date | Auteur | Modifications |
|---|---|---|---|
| 0.1 | 8 novembre 2026 | [À compléter] | Création du cahier des charges à partir de `EVOLUTION.md` |
| 1.0 | 8 novembre 2026 | [À compléter] | Version de travail complète, en attente de validation |

---

## Annexe E — Points à compléter avant validation

- [ ] Nom et coordonnées du commanditaire.
- [ ] Rédacteur, relecteur et validateur du document.
- [ ] Dates de début et de fin de chaque phase.
- [ ] Budget détaillé et source de financement.
- [ ] Responsables design, développement, contenu et recette.
- [ ] Appareil et version Android exacts de la recette.
- [ ] Cibles chiffrées des indicateurs de succès.
- [ ] Procédure de retrait d'un titre et délai de traitement.
- [ ] Registre des autorisations et crédits.
- [ ] Textes officiels des paroles.
- [ ] Identifiant définitif de l'application.
- [ ] Clé de signature de release.
- [ ] Politique de confidentialité et mentions légales.
- [ ] Décision sur la version iOS.
- [ ] Décision sur la lecture en arrière-plan.
- [ ] Décision sur les playlists.
