# Passer Plus ou Moins sur Supabase

1. **Créer le projet** : supabase.com > New project (région Europe). Garde le mot de passe de la base.
2. **Désactiver la confirmation par e-mail** : Authentication > Sign In / Providers > Email > désactive « Confirm email ».
3. **Créer les tables et le serveur** : SQL Editor > New query > colle tout `supabase/schema.sql` > Run.
   Tu peux le relancer sans risque. Les réglages du jeu (prix des œufs, chances, défis, cadeaux) se
   modifient ensuite dans Table Editor, tables `cfg_*`, sans toucher au code.
4. **Brancher le jeu** : Project Settings > API. Dans `www/index.html`, ligne `window.PM_SUPABASE`, remplace
   `url` par le Project URL et `key` par la clé `anon` (ou « publishable »). Jamais la clé `service_role`.
5. **Tester** : crée un compte, joue, ouvre un œuf. Si l'inscription répond « le serveur refuse la création
   de compte (email_address_invalid) », préviens Claude : c'est le domaine des faux e-mails à changer
   (réglage `emailDomain`).
6. Fusionne la pull request quand tu es content : le jeu bascule alors sur Supabase.

Anti-triche : le nombre secret, le score, les pièces, les œufs et les reventes sont calculés sur le serveur.
Le téléphone ne peut rien écrire directement dans la base.

## Duels automatiques (nouveau)

Les « codes de salle » n'existent plus. Dans **Duels**, le joueur choisit un niveau puis :

- **Duel occasionnel** : le jeu cherche automatiquement un autre joueur qui cherche aussi. Aucun trophée, aucune pièce.
- **Duel classé** (bouton « Jouer ») : le jeu cherche un adversaire avec un nombre de trophées proche (±100 au début, de plus en plus large quand l'attente dure). Le vainqueur gagne des trophées (plus s'il battait un joueur mieux classé), le perdant en perd (jamais en dessous de 0).

Règles anti-abus gérées par le serveur :
- une seule recherche à la fois par joueur, et jamais deux duels en même temps ;
- on ne peut plus annuler une fois l'adversaire trouvé ; quitter un duel en cours = défaite ;
- un joueur déconnecté plus de 30 s perd par forfait (l'autre gagne) ;
- deux mêmes joueurs ne peuvent pas se re-rencontrer en classé pendant 5 minutes (anti-« échange de victoires ») ;
- un duel sans gagnant au bout de 15 minutes est annulé, sans changement de trophées.

Ces réglages (`duel_k`, `duel_idle_s`, `duel_max_min`, `mm_window`, `mm_window_step`, `ranked_cooldown_min`) se modifient dans Table Editor > `cfg_settings`.

**À faire une fois :** recolle le fichier `schema.sql` en entier dans Supabase (SQL Editor > Run). Il peut être relancé sans risque, il ajoute les trophées et la file d'attente sans toucher aux comptes.
