# Plus ou Moins

Un jeu de devinette pour téléphone : trouve le nombre mystère en un minimum d'essais et de temps, gagne des pièces, ouvre des œufs et collectionne des pets (y compris des versions brillantes).

## Jouer

- **Sur Android** : télécharge **PlusOuMoins.apk** dans la [dernière Release](https://github.com/erwankarosky-source/plus-ou-moins/releases/tag/latest), ouvre-le sur ton téléphone et installe-le (autorise les sources inconnues si Android le demande).
- **Dans le navigateur** : https://erwankarosky-source.github.io/plus-ou-moins/

## Ce que contient le jeu

- 4 niveaux : Facile (1-10), Normal (1-100), Difficile (1-1000) et Nightmare (sans limite), avec des multiplicateurs de score.
- Comptes avec pseudo et mot de passe, ou mode « Jouer sans compte ».
- Classement séparé pour chaque niveau.
- Boutique d'œufs, 20 pets répartis en 5 raretés, versions brillantes et équipe de 3 pets avec des bonus.
- Cadeau du jour avec une série de 7 jours.
- Duels entre amis : l'hôte crée une salle et donne le code, puis lance la partie quand un ami a rejoint. Le premier qui trouve le nombre gagne.

## Pour les développeurs

Le jeu est une seule page HTML (`www/index.html`) enveloppée dans une appli Android avec [Capacitor](https://capacitorjs.com/). Les comptes, le classement et les duels utilisent Firebase (Authentication et Firestore).

Les compilations se font toutes seules avec GitHub Actions : à chaque modification de `main`, l'APK est reconstruit et publié dans la Release, et la version web est mise à jour.
