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
