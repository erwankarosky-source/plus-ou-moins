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

## Pseudos : changement réel et liste noire (nouveau)

**Comment ça marche.** Chaque compte a un identifiant de connexion **permanent** (caché, jamais montré au joueur) qui ne change jamais. Le pseudo n'est qu'une étiquette qui pointe vers lui. Quand tu changes un pseudo, l'ancien ne permet plus de se connecter, le nouveau oui, et le joueur garde tout (pièces, pets, score, trophées). Les comptes existants gardent leur identifiant actuel : rien n'est perdu.

**Renommer un joueur** (Supabase > SQL Editor) :

```sql
select admin_rename_player('AncienPseudo', 'NouveauPseudo');
```

Tu peux aussi simplement modifier la colonne `name` dans Table Editor > `profiles` : un garde-fou vérifie le nouveau pseudo et met à jour la connexion tout seul (ne touche pas à `login_email`). Chaque changement est noté dans la table `name_history`.

**Règles d'un pseudo** (vérifiées par le serveur, impossibles à contourner depuis le jeu) : 2 à 14 caractères ; lettres, chiffres, espace, `_` `.` `'` `-` (pas d'emoji ni de symboles) ; pas déjà pris (majuscules ignorées) ; pas dans la liste noire.

**Liste noire** (table `blocked_names`, modifiable dans Table Editor ou par commande) :

```sql
select admin_block_name('motinterdit');                -- interdit tout pseudo qui CONTIENT ce mot
select admin_block_name('admin', 'exact', 'réservé');  -- interdit seulement ce pseudo exact
select admin_unblock_name('motinterdit');              -- retire un mot
select * from admin_blocked_players();                 -- joueurs dont le pseudo actuel est interdit
```

La comparaison ignore majuscules, accents, espaces, ponctuation, lettres répétées et les astuces du genre `4dm1n` ou `a d m i n`. Quelques noms réservés sont déjà dedans (admin, modo, staff, support...). Un joueur dont le pseudo devient interdit **n'est pas bloqué** : utilise `admin_blocked_players()` pour le trouver puis renomme-le.

Ces commandes `admin_...` ne peuvent être lancées que depuis ton SQL Editor, jamais depuis le jeu.

**À faire une fois :** recolle `schema.sql` en entier (il peut être relancé sans risque), puis mets à jour l'appli (nouvel APK / nouvelle page web). Les anciennes versions du jeu ne sauront plus se connecter après le changement, il faut donc que tous les joueurs aient la nouvelle.

## Amis (nouveau)

Un petit bouton « personne + » en haut à droite du menu ouvre l'écran **Amis** (invisible pour les invités). Chaque joueur a un **code d'ami** unique de 8 caractères (ex. `G63A-2AFD`), attribué une fois pour toutes (les comptes existants en reçoivent un en collant `schema.sql`).

- On envoie une demande avec le code ; l'autre joueur voit une pastille avec le nombre de demandes en attente sur le bouton, puis **accepte ou refuse**.
- Liste d'amis (avec trophées), retrait d'un ami (avec confirmation), annulation d'une demande envoyée.
- Les amis suivent les changements de pseudo automatiquement.
- Protections côté serveur : pas de demande à soi-même, pas de doublon (même si les deux joueurs s'écrivent en même temps : si l'autre t'avait déjà demandé, vous devenez amis directement), on ne peut répondre qu'à ses propres demandes, 10 mauvais codes en 10 minutes = pause, plafond de 100 amis et 20 demandes en attente.

**À faire une fois :** recolle `schema.sql` en entier (relançable sans risque).

## Clubs (nouveau)

Un second petit bouton (bouclier), juste sous celui des amis, ouvre l'écran **Clubs** (invisible pour les invités). Une pastille indique les demandes d'adhésion à traiter si tu es chef ou officier.

**Règles** (toutes vérifiées par le serveur) :
- Un joueur est dans **un seul club** à la fois. Nom : 3 à 20 caractères (lettres, chiffres, espace, `_ . ' -`), unique (majuscules ignorées), pas dans la liste noire.
- Deux types de club, au choix du chef (modifiable) : **Ouvert** (on entre directement) ou **Sur demande** (le chef ou un officier accepte/refuse). Passer un club en « Ouvert » accepte les demandes en attente tant qu'il y a de la place.
- **Chef** : tout gérer (réglages, officiers, exclusion, passer la direction, dissoudre). **Officier** : traiter les demandes et exclure les simples membres. **Membre** : voir le club et le quitter.
- Si le chef quitte, la direction passe à un officier (sinon au plus ancien membre). Le dernier membre qui part ferme le club.
- Maximum 30 membres par club, 3 demandes en attente par joueur. Un club est classé selon le total des trophées de ses membres.

**Liste noire des noms de clubs** : table `blocked_club_names` (Table Editor) ou par commande ; la liste des pseudos interdits s'applique aussi aux noms de clubs.

```sql
select admin_block_club_name('motinterdit');                 -- interdit tout nom qui CONTIENT ce mot
select admin_block_club_name('officiel', 'exact', 'réservé'); -- seulement ce nom exact
select admin_unblock_club_name('motinterdit');
select admin_rename_club('AncienNom', 'NouveauNom');         -- renommer un club
select * from admin_blocked_clubs();                          -- clubs dont le nom est (devenu) interdit
```

Les limites (`club_cap`, `club_max_requests`) se règlent dans `cfg_settings`.

**À faire une fois :** recolle `schema.sql` en entier (relançable sans risque), puis installe le nouvel APK.
