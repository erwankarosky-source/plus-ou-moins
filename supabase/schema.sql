-- =====================================================================
-- Plus ou Moins : base de données Supabase (serveur maître de tout)
-- À coller en entier dans Supabase > SQL Editor > New query > Run.
-- Peut être relancé sans risque : il ne touche pas aux comptes existants.
-- Le téléphone ne peut RIEN écrire directement : il passe par les fonctions
-- ci-dessous, qui vérifient tout (nombre secret, score, pièces, œufs...).
-- =====================================================================

-- ---------- Réglages du jeu (lisibles par tous, modifiables dans Table Editor) ----------
create table if not exists cfg_levels (
  id text primary key, max_n bigint, par int not null, time_s int not null, mult int not null
);
create table if not exists cfg_rarities (
  r int primary key, id text not null, name text not null, sell int not null
);
create table if not exists cfg_pets (
  id text primary key, name text not null, pct int not null, r int not null,
  kind text not null check (kind in ('coin', 'score')), uni text not null
);
create table if not exists cfg_eggs (
  id text primary key, name text not null, price int not null, odds numeric[] not null, uni text not null
);
create table if not exists cfg_settings (key text primary key, value numeric not null);
create table if not exists cfg_daily (day_idx int primary key, coins int, egg text);
create table if not exists cfg_missions (
  id text primary key, title text not null, descr text not null default '',
  type text not null check (type in ('games', 'hatch', 'score', 'tries')),
  level text not null default '', target int not null, reward int not null,
  ord int not null default 0, active boolean not null default true
);

insert into cfg_levels (id, max_n, par, time_s, mult) values
  ('easy', 10, 3, 20, 1), ('normal', 100, 6, 60, 2), ('hard', 1000, 9, 120, 4), ('nightmare', null, 24, 300, 8)
on conflict (id) do nothing;
insert into cfg_rarities (r, id, name, sell) values
  (0, 'commun', 'Commun', 2), (1, 'rare', 'Rare', 6), (2, 'epique', 'Épique', 25),
  (3, 'legendaire', 'Légendaire', 100), (4, 'mythique', 'Mythique', 400)
on conflict (r) do nothing;
insert into cfg_pets (id, name, pct, r, kind, uni) values
  ('cat', 'Chaton', 6, 0, 'coin', 'prairie'), ('bunny', 'Lapin', 5, 0, 'score', 'prairie'),
  ('frog', 'Grenouille', 7, 0, 'coin', 'prairie'), ('duck', 'Canard', 6, 0, 'score', 'prairie'),
  ('snail', 'Escargot', 8, 0, 'coin', 'prairie'),
  ('cloud', 'Nuage', 10, 1, 'score', 'ciel'), ('panda', 'Panda', 12, 1, 'coin', 'prairie'),
  ('fox', 'Renard', 11, 1, 'score', 'prairie'), ('penguin', 'Pingouin', 14, 1, 'coin', 'prairie'),
  ('octopus', 'Pieuvre', 13, 1, 'score', 'cosmos'),
  ('unicorn', 'Licorne', 24, 2, 'coin', 'cosmos'), ('dragon', 'Dragonnet', 20, 2, 'score', 'cosmos'),
  ('owl', 'Hibou', 21, 2, 'coin', 'ciel'), ('ghost', 'Fantôme', 18, 2, 'score', 'ciel'),
  ('phoenix', 'Phénix', 32, 3, 'score', 'ciel'), ('star', 'Étoile', 38, 3, 'coin', 'ciel'),
  ('moon', 'Lune', 34, 3, 'score', 'ciel'),
  ('galaxy', 'Galaxie', 55, 4, 'score', 'cosmos'), ('sun', 'Soleil', 60, 4, 'coin', 'cosmos'),
  ('rainbow', 'Arc-en-ciel', 50, 4, 'score', 'ciel')
on conflict (id) do nothing;
insert into cfg_eggs (id, name, price, odds, uni) values
  ('pastel', 'Œuf pastel', 25, '{70,24,5,0.9,0.1}', 'prairie'),
  ('etoile', 'Œuf étoilé', 120, '{40,40,15,4.5,0.5}', 'ciel'),
  ('cosmique', 'Œuf cosmique', 500, '{0,45,38,14,3}', 'cosmos')
on conflict (id) do nothing;
insert into cfg_settings (key, value) values
  ('shiny_chance', 3), ('shiny_mult', 1.5), ('shiny_sell_mult', 4), ('uni_weight', 5), ('coin_div', 150),
  ('duel_k', 40), ('duel_idle_s', 30), ('duel_max_min', 15), ('mm_window', 100), ('mm_window_step', 15), ('ranked_cooldown_min', 5)
on conflict (key) do nothing;
insert into cfg_daily (day_idx, coins, egg) values
  (0, 15, null), (1, 20, null), (2, 25, null), (3, 35, null), (4, 45, null), (5, 60, null), (6, null, 'etoile')
on conflict (day_idx) do nothing;
insert into cfg_missions (id, title, descr, type, level, target, reward, ord) values
  ('d1', 'Premiers pas', '', 'games', '', 5, 50, 1),
  ('d2', 'Éleveur', '', 'hatch', '', 3, 60, 2),
  ('d3', 'Éclair', '', 'tries', 'normal', 6, 100, 3),
  ('d4', 'Gros score', '', 'score', 'normal', 1200, 150, 4),
  ('d5', 'Marathonien', '', 'games', '', 25, 200, 5)
on conflict (id) do nothing;

-- ---------- Données des joueurs (personne ne peut les lire ni les écrire directement) ----------
create table if not exists profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  name_lower text not null unique,
  coins bigint not null default 0 check (coins >= 0),
  games int not null default 0,
  hatched int not null default 0,
  best bigint not null default 0,
  best_lvl text not null default '',
  b_easy bigint not null default 0,
  b_normal bigint not null default 0,
  b_hard bigint not null default 0,
  b_nightmare bigint not null default 0,
  inv jsonb not null default '{}',
  team jsonb not null default '[]',
  daily_day date,
  daily_streak int not null default 0,
  mp jsonb not null default '{}',
  mc jsonb not null default '{}',
  sid text,
  created_at timestamptz not null default now()
);
alter table profiles add column if not exists trophies int not null default 0 check (trophies >= 0);
alter table profiles add column if not exists duel_wins int not null default 0;
-- Identifiant de connexion PERMANENT (invisible pour le joueur) : il ne change jamais, même si le pseudo change.
-- Les comptes existants gardent leur identifiant actuel (copié depuis auth.users).
alter table profiles add column if not exists login_email text;
alter table profiles add column if not exists duel_losses int not null default 0;
create index if not exists profiles_b_easy on profiles (b_easy desc);
create index if not exists profiles_b_normal on profiles (b_normal desc);
create index if not exists profiles_b_hard on profiles (b_hard desc);
create index if not exists profiles_b_nightmare on profiles (b_nightmare desc);

-- Pseudos interdits (modifiable par l'administrateur dans Table Editor > blocked_names, ou avec admin_block_name).
--   mode 'exact'    : interdit seulement ce pseudo-là (ex. admin)
--   mode 'contains' : interdit tout pseudo qui CONTIENT le mot (ex. un gros mot)
-- La comparaison ignore majuscules, accents, espaces, ponctuation, chiffres-lettres (4=a, 3=e, 0=o...) et lettres répétées.
create table if not exists blocked_names (
  word text primary key,
  mode text not null default 'contains' check (mode in ('exact', 'contains')),
  note text,
  added_at timestamptz not null default now()
);
-- Historique des changements de pseudo
create table if not exists name_history (
  id bigint generated always as identity primary key,
  uid uuid not null,
  old_name text,
  new_name text not null,
  changed_at timestamptz not null default now()
);
insert into blocked_names (word, mode, note) values
  ('admin', 'exact', 'réservé'), ('administrateur', 'exact', 'réservé'), ('moderateur', 'exact', 'réservé'),
  ('modo', 'exact', 'réservé'), ('staff', 'exact', 'réservé'), ('support', 'exact', 'réservé'), ('plusoumoins', 'exact', 'réservé')
on conflict (word) do nothing;

create table if not exists games (
  id uuid primary key default gen_random_uuid(),
  uid uuid not null references profiles (id) on delete cascade,
  lvl text not null references cfg_levels (id),
  secret bigint not null,
  low numeric not null default 1,
  high numeric,
  tries int not null default 0,
  started_at timestamptz not null default now(),
  status text not null default 'playing',
  duel_code text
);
create index if not exists games_uid on games (uid);

-- Duels : un duel = deux joueurs, un nombre secret partagé, le premier qui le trouve gagne.
-- (Les anciennes "salles à code" n'existent plus : tout passe par le matchmaking.)
create table if not exists duels (
  code text primary key,
  lvl text not null references cfg_levels (id),
  host uuid,
  hname text,
  status text not null default 'playing',      -- playing | done | closed
  started_at timestamptz,
  winner uuid,
  winner_name text,
  winner_tries int,
  winner_time numeric,
  created_at timestamptz not null default now()
);
alter table duels alter column host drop not null;
alter table duels alter column hname drop not null;
alter table duels add column if not exists mode text not null default 'casual';   -- casual | ranked
alter table duels add column if not exists p1 uuid;
alter table duels add column if not exists p2 uuid;
alter table duels add column if not exists reason text;                          -- found | forfeit | timeout
alter table duels add column if not exists delta_w int not null default 0;       -- trophées gagnés par le vainqueur
alter table duels add column if not exists delta_l int not null default 0;       -- trophées perdus par le perdant
create table if not exists duel_secrets (code text primary key references duels (code) on delete cascade, secret bigint not null);
create table if not exists duel_players (
  code text not null references duels (code) on delete cascade,
  uid uuid not null,
  name text not null,
  joined_at timestamptz not null default now(),
  left_room boolean not null default false,
  primary key (code, uid)
);
alter table duel_players add column if not exists last_seen timestamptz not null default now();
create index if not exists duel_players_uid on duel_players (uid);
create index if not exists duels_status on duels (status);

-- File d'attente du matchmaking : une seule ligne par joueur (donc jamais deux recherches en même temps).
create table if not exists duel_queue (
  uid uuid primary key references profiles (id) on delete cascade,
  mode text not null check (mode in ('casual', 'ranked')),
  lvl text not null references cfg_levels (id),
  trophies int not null default 0,
  joined_at timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  matched_code text
);

-- Sécurité : RLS activée partout. Seuls les réglages (cfg_*) sont lisibles.
alter table profiles enable row level security;
alter table games enable row level security;
alter table duels enable row level security;
alter table duel_secrets enable row level security;
alter table duel_players enable row level security;
alter table duel_queue enable row level security;
alter table blocked_names enable row level security;
alter table name_history enable row level security;
alter table cfg_levels enable row level security;
alter table cfg_rarities enable row level security;
alter table cfg_pets enable row level security;
alter table cfg_eggs enable row level security;
alter table cfg_settings enable row level security;
alter table cfg_daily enable row level security;
alter table cfg_missions enable row level security;
do $$
declare t text;
begin
  foreach t in array array['cfg_levels','cfg_rarities','cfg_pets','cfg_eggs','cfg_settings','cfg_daily','cfg_missions'] loop
    execute format('drop policy if exists "lecture publique" on %I', t);
    execute format('create policy "lecture publique" on %I for select using (true)', t);
  end loop;
end $$;
revoke all on profiles, games, duels, duel_secrets, duel_players, duel_queue, blocked_names, name_history from anon, authenticated;
revoke insert, update, delete on cfg_levels, cfg_rarities, cfg_pets, cfg_eggs, cfg_settings, cfg_daily, cfg_missions from anon, authenticated;

-- =====================================================================
-- Fonctions internes (préfixe _ : jamais appelables depuis le téléphone)
-- =====================================================================
create or replace function _setting(p_key text) returns numeric language sql stable
set search_path = public as $$ select value from cfg_settings where key = p_key $$;

create or replace function _today() returns date language sql stable
as $$ select (now() at time zone 'Europe/Paris')::date $$;

create or replace function _profile_json(p_uid uuid) returns jsonb language sql stable
set search_path = public as $$
  select jsonb_build_object(
    'name', name, 'best', best, 'bestLvl', best_lvl,
    'b_easy', b_easy, 'b_normal', b_normal, 'b_hard', b_hard, 'b_nightmare', b_nightmare,
    'games', games, 'coins', coins, 'hatched', hatched, 'trophies', trophies, 'duelWins', duel_wins, 'duelLosses', duel_losses, 'inv', inv, 'team', team,
    'pet', coalesce(team ->> 0, ''),
    'daily', jsonb_build_object('day', coalesce(daily_day::text, ''), 'streak', daily_streak),
    'mp', mp, 'mc', mc, 'today', _today()::text)
  from profiles where id = p_uid
$$;

-- Vérifie la connexion ET que cet appareil est bien le dernier connecté.
create or replace function _me(p_sid text) returns uuid language plpgsql stable
set search_path = public as $$
declare v_uid uuid := auth.uid(); v_sid text;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  select sid into v_sid from profiles where id = v_uid;
  if not found then raise exception 'no_profile'; end if;
  if v_sid is null or p_sid is null or v_sid <> p_sid then raise exception 'session_replaced'; end if;
  return v_uid;
end $$;

create or replace function _new_secret(p_lvl text) returns bigint language plpgsql volatile
set search_path = public as $$
declare v_max bigint;
begin
  select max_n into v_max from cfg_levels where id = p_lvl;
  if not found then raise exception 'bad_level'; end if;
  if v_max is null then return greatest(1, floor(power(10, 2 + random() * 7))::bigint); end if;
  return 1 + floor(random() * v_max)::bigint;
end $$;

-- Bonus de l'équipe : {coin, score} en pourcent. Les pets brillants (_s) ont pct x shiny_mult.
create or replace function _team_bonus(p_uid uuid, out b_coin int, out b_score int) language plpgsql stable
set search_path = public as $$
declare v_team jsonb; v_id text; v_base text; v_p cfg_pets; v_pct int; v_mult numeric := _setting('shiny_mult');
begin
  b_coin := 0; b_score := 0;
  select team into v_team from profiles where id = p_uid;
  for v_id in select jsonb_array_elements_text(v_team) loop
    v_base := regexp_replace(v_id, '_s$', '');
    select * into v_p from cfg_pets where id = v_base;
    if not found then continue; end if;
    v_pct := v_p.pct;
    if v_id like '%\_s' then v_pct := greatest(1, round(v_p.pct * v_mult)::int); end if;
    if v_p.kind = 'coin' then b_coin := b_coin + v_pct; else b_score := b_score + v_pct; end if;
  end loop;
end $$;

-- Tire un pet dans un œuf (rareté, puis pet avec bonus d'univers, puis chance de brillant).
create or replace function _roll_egg(p_egg text) returns text language plpgsql volatile
set search_path = public as $$
declare e cfg_eggs; x numeric; acc numeric := 0; ri int := 0; i int; w numeric; tot numeric := 0; y numeric; pid text; rec record;
begin
  select * into e from cfg_eggs where id = p_egg;
  if not found then raise exception 'bad_egg'; end if;
  for i in reverse array_length(e.odds, 1)..1 loop
    if e.odds[i] > 0 then ri := i - 1; exit; end if;
  end loop;
  x := random() * 100;
  for i in 1..array_length(e.odds, 1) loop
    acc := acc + e.odds[i];
    if x < acc then ri := i - 1; exit; end if;
  end loop;
  for rec in select id, uni from cfg_pets where r = ri loop
    tot := tot + case when rec.uni = e.uni then _setting('uni_weight') else 1 end;
  end loop;
  y := random() * tot;
  for rec in select id, uni from cfg_pets where r = ri order by id loop
    pid := rec.id;
    y := y - case when rec.uni = e.uni then _setting('uni_weight') else 1 end;
    if y < 0 then exit; end if;
  end loop;
  if random() * 100 < _setting('shiny_chance') then pid := pid || '_s'; end if;
  return pid;
end $$;

create or replace function _add_pet(p_uid uuid, p_pet text) returns int language plpgsql volatile
set search_path = public as $$
declare v_n int;
begin
  update profiles set inv = jsonb_set(inv, array[p_pet], to_jsonb(coalesce((inv ->> p_pet)::int, 0) + 1), true)
    where id = p_uid returning (inv ->> p_pet)::int into v_n;
  return v_n;
end $$;

create or replace function _team_count(p_team jsonb, p_pet text) returns int language sql immutable
as $$ select count(*)::int from jsonb_array_elements_text(p_team) t where t = p_pet $$;

-- =====================================================================
-- Fonctions appelées par le jeu
-- =====================================================================

-- Réglages publics (aussi pour les joueurs sans compte)
create or replace function get_config() returns jsonb language sql stable security definer
set search_path = public as $$
  select jsonb_build_object(
    'levels', (select coalesce(jsonb_agg(to_jsonb(l)), '[]') from cfg_levels l),
    'rar', (select coalesce(jsonb_agg(jsonb_build_object('r', r, 'sell', sell) order by r), '[]') from cfg_rarities),
    'pets', (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'pct', pct)), '[]') from cfg_pets),
    'eggs', (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'price', price, 'odds', odds)), '[]') from cfg_eggs),
    'settings', (select coalesce(jsonb_object_agg(key, value), '{}') from cfg_settings),
    'daily', (select coalesce(jsonb_agg(jsonb_build_object('coins', coins, 'egg', egg) order by day_idx), '[]') from cfg_daily),
    'missions', (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'title', title, 'desc', descr, 'type', type,
        'level', level, 'target', target, 'reward', reward, 'order', ord) order by ord, title), '[]')
      from cfg_missions where active))
$$;

-- ---------- Pseudos : règles, liste noire, changement réel ----------
-- Forme "comparable" d'un pseudo : minuscules, sans accents, sans espaces ni ponctuation,
-- chiffres/symboles courants remplacés par des lettres, lettres répétées réduites.
create or replace function _name_norm(p text) returns text language sql immutable
set search_path = public as $$
  select regexp_replace(
           regexp_replace(
             translate(lower(coalesce(p, '')),
               'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ0134578@$!',
               'aaaaaaceeeeiiiinooooouuuuyyoieastbasi'),
             '[^a-z0-9]', '', 'g'),
           '(.)\1+', '\1', 'g')
$$;

create or replace function _name_blocked(p text) returns boolean language plpgsql stable security definer
set search_path = public as $$
declare n text := _name_norm(p);
begin
  if n = '' then return false; end if;
  return exists (
    select 1 from blocked_names b
    where length(_name_norm(b.word)) > 0
      and ((b.mode = 'exact' and _name_norm(b.word) = n)
        or (b.mode = 'contains' and position(_name_norm(b.word) in n) > 0)));
end $$;

-- Règles d'un pseudo. Renvoie le pseudo nettoyé, ou lève : bad_name | forbidden_name | name_taken.
create or replace function _check_name(p_name text, p_uid uuid) returns text language plpgsql stable security definer
set search_path = public as $$
declare v text := btrim(regexp_replace(coalesce(p_name, ''), '[[:space:]]+', ' ', 'g'));
begin
  if char_length(v) < 2 or char_length(v) > 14 then raise exception 'bad_name'; end if;
  if v !~ '^[[:alnum:] _.''-]+$' or v !~ '[[:alnum:]]' then raise exception 'bad_name'; end if;   -- lettres, chiffres, espace _ . ' -
  if _name_blocked(v) then raise exception 'forbidden_name'; end if;
  if exists (select 1 from profiles where name_lower = lower(v) and id is distinct from p_uid) then raise exception 'name_taken'; end if;
  return v;
end $$;

-- Garde-fou sur la table elle-même : TOUT changement de pseudo (même fait à la main dans Table Editor)
-- est vérifié, met à jour l'identifiant de connexion "name_lower" et garde une trace.
create or replace function _profiles_name_guard() returns trigger language plpgsql security definer
set search_path = public, auth as $$
begin
  if tg_op = 'INSERT' or new.name is distinct from old.name then
    new.name := _check_name(new.name, new.id);
  end if;
  new.name_lower := lower(new.name);
  if tg_op = 'INSERT' then
    if new.login_email is null then select email into new.login_email from auth.users where id = new.id; end if;
  else
    new.login_email := coalesce(old.login_email, new.login_email);   -- l'identifiant permanent ne change jamais
    if new.name is distinct from old.name then
      insert into name_history (uid, old_name, new_name) values (new.id, old.name, new.name);
      update duel_players set name = new.name where uid = new.id;
      update duels set winner_name = new.name where winner = new.id;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists profiles_name_guard on profiles;
create trigger profiles_name_guard before insert or update of name, name_lower on profiles
  for each row execute function _profiles_name_guard();

-- Comptes déjà existants : on fige leur identifiant de connexion actuel.
update profiles p set login_email = u.email from auth.users u where u.id = p.id and p.login_email is null;
create unique index if not exists profiles_login_email on profiles (login_email);

-- Appelées par le jeu AVANT la connexion (donc ouvertes à tous) :
-- pseudo -> identifiant de connexion permanent (null si aucun joueur ne porte ce pseudo)
create or replace function resolve_login(p_name text) returns text language sql stable security definer
set search_path = public as $$
  select login_email from profiles where name_lower = lower(btrim(regexp_replace(coalesce(p_name, ''), '[[:space:]]+', ' ', 'g')))
$$;
-- vérification d'un pseudo avant création : ok | bad_name | forbidden_name | name_taken
create or replace function check_name(p_name text) returns text language plpgsql stable security definer
set search_path = public as $$
begin
  perform _check_name(p_name, null);
  return 'ok';
exception when others then
  return case when sqlerrm in ('bad_name', 'forbidden_name', 'name_taken') then sqlerrm else 'bad_name' end;
end $$;
-- Création de compte refusée après coup (pseudo pris entre-temps...) : on supprime le compte vide.
create or replace function cancel_signup() returns boolean language plpgsql volatile security definer
set search_path = public, auth as $$
declare v uuid := auth.uid();
begin
  if v is null or exists (select 1 from profiles where id = v) then return false; end if;
  delete from auth.users where id = v;
  return true;
end $$;

-- ---------- Outils administrateur (à lancer dans Supabase > SQL Editor ; JAMAIS appelables depuis le jeu) ----------
--   select admin_rename_player('AncienPseudo', 'NouveauPseudo');
--   select admin_block_name('motinterdit');            -- ou admin_block_name('admin', 'exact', 'réservé')
--   select admin_unblock_name('motinterdit');
--   select * from admin_blocked_players();             -- joueurs dont le pseudo actuel est interdit
create or replace function admin_rename_player(p_current text, p_new text) returns jsonb language plpgsql volatile
set search_path = public as $$
declare v_id uuid; v_old text;
begin
  select id, name into v_id, v_old from profiles
    where name_lower = lower(btrim(regexp_replace(coalesce(p_current, ''), '[[:space:]]+', ' ', 'g')));
  if not found then raise exception 'unknown_player'; end if;
  update profiles set name = p_new where id = v_id;       -- le garde-fou vérifie tout et met à jour la connexion
  return jsonb_build_object('id', v_id, 'old', v_old, 'new', (select name from profiles where id = v_id));
end $$;
create or replace function admin_rename_player_id(p_id uuid, p_new text) returns jsonb language plpgsql volatile
set search_path = public as $$
declare v_old text;
begin
  select name into v_old from profiles where id = p_id;
  if not found then raise exception 'unknown_player'; end if;
  update profiles set name = p_new where id = p_id;
  return jsonb_build_object('id', p_id, 'old', v_old, 'new', (select name from profiles where id = p_id));
end $$;
create or replace function admin_block_name(p_word text, p_mode text default 'contains', p_note text default null) returns text
language plpgsql volatile set search_path = public as $$
begin
  if length(_name_norm(p_word)) = 0 then raise exception 'bad_word'; end if;
  insert into blocked_names (word, mode, note) values (btrim(p_word), p_mode, p_note)
    on conflict (word) do update set mode = excluded.mode, note = coalesce(excluded.note, blocked_names.note);
  return 'ok';
end $$;
create or replace function admin_unblock_name(p_word text) returns text language plpgsql volatile
set search_path = public as $$
begin delete from blocked_names where lower(word) = lower(btrim(p_word)); return 'ok'; end $$;
create or replace function admin_blocked_players() returns table (id uuid, name text) language sql stable security definer
set search_path = public as $$ select id, name from profiles where _name_blocked(name) order by name $$;

-- Connexion / création du profil. Chaque appel ouvre une NOUVELLE session :
-- l'ancien appareil connecté au même compte est éjecté à son prochain appel.
create or replace function login_session(p_name text default null) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := auth.uid(); v_name text; v_sid text := gen_random_uuid()::text;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  if not exists (select 1 from profiles where id = v_uid) then
    v_name := btrim(regexp_replace(coalesce(p_name, ''), '\s+', ' ', 'g'));
    if p_name is null then raise exception 'no_profile'; end if;
    begin
      insert into profiles (id, name, name_lower) values (v_uid, v_name, lower(v_name));   -- pseudo vérifié par le garde-fou
    exception when unique_violation then
      raise exception 'name_taken';
    end;
  end if;
  update profiles set sid = v_sid where id = v_uid;
  return jsonb_build_object('sid', v_sid, 'profile', _profile_json(v_uid));
end $$;

create or replace function check_session(p_sid text) returns boolean language plpgsql stable security definer
set search_path = public as $$
begin perform _me(p_sid); return true; end $$;

create or replace function delete_account(p_sid text) returns boolean language plpgsql volatile security definer
set search_path = public, auth as $$
declare v_uid uuid := _me(p_sid);
begin
  delete from profiles where id = v_uid;
  delete from auth.users where id = v_uid;
  return true;
end $$;

-- ---------- Parties solo ----------
create or replace function start_game(p_sid text, p_lvl text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); v_gid uuid;
begin
  delete from games where uid = v_uid and (duel_code is null or started_at < now() - interval '1 day');
  insert into games (uid, lvl, secret) values (v_uid, p_lvl, _new_secret(p_lvl)) returning id into v_gid;
  return jsonb_build_object('gid', v_gid);
end $$;

-- Fin d'un duel pour un joueur : on clôt sa partie et on révèle le nombre (le duel est forcément terminé).
create or replace function _duel_end(p_game games) returns jsonb language plpgsql volatile
set search_path = public as $$
declare d duels; v_dir text;
begin
  select * into d from duels where code = p_game.duel_code;
  v_dir := case when d.status = 'closed' then 'closed' when d.winner = p_game.uid then 'won' else 'lost' end;
  update games set status = case when v_dir = 'won' then 'won' else 'lost' end where id = p_game.id and status = 'playing';
  return jsonb_build_object('dir', v_dir, 'secret', p_game.secret, 'mode', d.mode, 'reason', d.reason,
    'winner', case when d.winner is null then null else
      jsonb_build_object('uid', d.winner, 'name', d.winner_name, 'tries', d.winner_tries, 'time', d.winner_time) end,
    'trophies', case when d.mode <> 'ranked' or v_dir = 'closed' then 0
                     when v_dir = 'won' then d.delta_w else -d.delta_l end,
    'profile', _profile_json(p_game.uid));
end $$;

create or replace function guess(p_sid text, p_gid uuid, p_n text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare
  v_uid uuid := _me(p_sid); g games; L cfg_levels; d duels; n numeric; v_tries int; v_el numeric;
  v_a int; v_t int; v_base int; bc int; bs int; v_total bigint; v_coins int; v_duel boolean; v_won boolean := true;
  v_rec boolean := false; v_mp jsonb; m cfg_missions; v_name text; v_best bigint; v_lvl_best bigint; v_newmp boolean := false;
begin
  select * into g from games where id = p_gid and uid = v_uid for update;
  if not found then raise exception 'no_game'; end if;
  if g.status <> 'playing' then
    if g.duel_code is not null and g.status = 'lost' then return _duel_end(g); end if;   -- duel perdu entre-temps
    raise exception 'no_game';
  end if;
  if p_n is null or p_n !~ '^[0-9]{1,30}$' then raise exception 'bad_number'; end if;
  n := p_n::numeric;
  select * into L from cfg_levels where id = g.lvl;
  if n < 1 or (L.max_n is not null and n > L.max_n) then raise exception 'out_of_range'; end if;
  if n < g.low or (g.high is not null and n > g.high) then raise exception 'excluded'; end if;
  v_duel := g.duel_code is not null;
  if v_duel then
    select * into d from duels where code = g.duel_code for update;
    update duel_players set last_seen = now() where code = g.duel_code and uid = v_uid;
    perform _duel_sweep(g.duel_code);
    select * into d from duels where code = g.duel_code;
    if d.status <> 'playing' then return _duel_end(g); end if;      -- duel déjà fini (adversaire gagnant, parti ou temps écoulé)
    if d.started_at > now() then raise exception 'not_started'; end if;
  end if;
  v_tries := g.tries + 1;
  if n < g.secret then
    update games set low = n + 1, tries = v_tries where id = g.id;
    return jsonb_build_object('dir', 'plus', 'tries', v_tries);
  elsif n > g.secret then
    update games set high = n - 1, tries = v_tries where id = g.id;
    return jsonb_build_object('dir', 'moins', 'tries', v_tries);
  end if;

  -- Trouvé !
  v_el := extract(epoch from (now() - case when v_duel then d.started_at else g.started_at end));
  if v_duel then
    if not _finish_duel(g.duel_code, v_uid, 'found', v_tries, round(v_el, 1)) then
      update games set tries = v_tries where id = g.id;
      select * into g from games where id = g.id;
      return _duel_end(g);
    end if;
  end if;
  v_a := round(700 * greatest(0.15, least(1, L.par::numeric / v_tries)))::int;
  v_t := round(300 * greatest(0, 1 - v_el / L.time_s))::int;
  v_base := (v_a + v_t) * L.mult;
  if v_duel then bc := 0; bs := 0; else select b_coin, b_score into bc, bs from _team_bonus(v_uid); end if;
  v_total := round(v_base * (1 + bs / 100.0));
  v_coins := case when v_duel then 0 else greatest(1, round((v_total / _setting('coin_div')) * (1 + bc / 100.0)))::int end;
  update games set status = 'won', tries = v_tries where id = g.id;
  select best, case g.lvl when 'easy' then b_easy when 'normal' then b_normal when 'hard' then b_hard else b_nightmare end
    into v_best, v_lvl_best from profiles where id = v_uid;
  if not v_duel then
    v_rec := v_total > v_lvl_best;
    update profiles set
      games = games + 1, coins = coins + v_coins,
      best = case when v_total > v_best then v_total else best end,
      best_lvl = case when v_total > v_best then g.lvl else best_lvl end,
      b_easy = case when g.lvl = 'easy' and v_total > b_easy then v_total else b_easy end,
      b_normal = case when g.lvl = 'normal' and v_total > b_normal then v_total else b_normal end,
      b_hard = case when g.lvl = 'hard' and v_total > b_hard then v_total else b_hard end,
      b_nightmare = case when g.lvl = 'nightmare' and v_total > b_nightmare then v_total else b_nightmare end
      where id = v_uid;
    -- défis "score" et "tries"
    select mp into v_mp from profiles where id = v_uid;
    for m in select * from cfg_missions where active and type in ('score', 'tries') loop
      if (v_mp ? m.id) or (m.level <> '' and m.level <> g.lvl) then continue; end if;
      if (m.type = 'score' and v_total >= m.target) or (m.type = 'tries' and v_tries <= m.target) then
        v_mp := v_mp || jsonb_build_object(m.id, 1); v_newmp := true;
      end if;
    end loop;
    if v_newmp then update profiles set mp = v_mp where id = v_uid; end if;
  end if;
  return jsonb_build_object('dir', 'hit', 'secret', g.secret, 'tries', v_tries, 'elapsed', round(v_el, 1),
    'a', v_a, 't', v_t, 'base', v_base, 'total', v_total, 'coins', v_coins, 'bcoin', bc, 'bscore', bs,
    'record', v_rec, 'mission', v_newmp, 'duel', v_duel,
    'trophies', case when v_duel then (select case when mode = 'ranked' then delta_w else 0 end from duels where code = g.duel_code) else 0 end,
    'dmode', case when v_duel then (select mode from duels where code = g.duel_code) else null end,
    'profile', _profile_json(v_uid));
end $$;

-- Le client appelle ceci quand il apprend que le duel est fini (adversaire gagnant, parti, annulé...).
create or replace function finish_lost(p_sid text, p_gid uuid) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); g games; d duels;
begin
  select * into g from games where id = p_gid and uid = v_uid for update;
  if not found or g.duel_code is null then raise exception 'no_game'; end if;
  perform _duel_sweep(g.duel_code);
  select * into d from duels where code = g.duel_code;
  if d.status = 'playing' then raise exception 'no_winner'; end if;
  return _duel_end(g);
end $$;

-- ---------- Pets, œufs, revente ----------
create or replace function set_team(p_sid text, p_team jsonb) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); v_inv jsonb; v_id text;
begin
  if jsonb_typeof(p_team) <> 'array' or jsonb_array_length(p_team) > 3 then raise exception 'bad_team'; end if;
  select inv into v_inv from profiles where id = v_uid;
  for v_id in select jsonb_array_elements_text(p_team) loop
    if not exists (select 1 from cfg_pets where id = regexp_replace(v_id, '_s$', '')) then raise exception 'bad_team'; end if;
    if _team_count(p_team, v_id) > coalesce((v_inv ->> v_id)::int, 0) then raise exception 'bad_team'; end if;
  end loop;
  update profiles set team = p_team where id = v_uid;
  return _profile_json(v_uid);
end $$;

create or replace function open_egg(p_sid text, p_egg text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); e cfg_eggs; v_pet text; v_n int;
begin
  select * into e from cfg_eggs where id = p_egg;
  if not found then raise exception 'bad_egg'; end if;
  update profiles set coins = coins - e.price, hatched = hatched + 1 where id = v_uid and coins >= e.price;
  if not found then raise exception 'not_enough_coins'; end if;
  v_pet := _roll_egg(p_egg);
  v_n := _add_pet(v_uid, v_pet);
  return jsonb_build_object('pet', v_pet, 'count', v_n, 'profile', _profile_json(v_uid));
end $$;

create or replace function sell_dup(p_sid text, p_pet text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); v_inv jsonb; v_team jsonb; v_n int; v_p cfg_pets; v_sell int; v_gain int;
begin
  select * into v_p from cfg_pets where id = regexp_replace(p_pet, '_s$', '');
  if not found then raise exception 'bad_pet'; end if;
  select inv, team into v_inv, v_team from profiles where id = v_uid for update;
  v_n := coalesce((v_inv ->> p_pet)::int, 0);
  if v_n < 2 or v_n - _team_count(v_team, p_pet) < 1 then raise exception 'no_duplicate'; end if;
  select sell into v_sell from cfg_rarities where r = v_p.r;
  v_gain := v_sell * case when p_pet like '%\_s' then _setting('shiny_sell_mult')::int else 1 end;
  update profiles set inv = jsonb_set(inv, array[p_pet], to_jsonb(v_n - 1)), coins = coins + v_gain where id = v_uid;
  return jsonb_build_object('gain', v_gain, 'profile', _profile_json(v_uid));
end $$;

-- ---------- Cadeau du jour et défis ----------
create or replace function claim_daily(p_sid text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare
  v_uid uuid := _me(p_sid); p profiles; v_today date := _today(); v_streak int; r cfg_daily; v_pet text; v_n int;
begin
  select * into p from profiles where id = v_uid for update;
  if p.daily_day is not null and p.daily_day >= v_today then raise exception 'already_claimed'; end if;
  v_streak := case when p.daily_day = v_today - 1 then p.daily_streak + 1 else 1 end;
  select * into r from cfg_daily where day_idx = (v_streak - 1) % 7;
  update profiles set daily_day = v_today, daily_streak = v_streak where id = v_uid;
  if r.coins is not null then
    update profiles set coins = coins + r.coins where id = v_uid;
    return jsonb_build_object('coins', r.coins, 'profile', _profile_json(v_uid));
  end if;
  v_pet := _roll_egg(r.egg);
  v_n := _add_pet(v_uid, v_pet);
  update profiles set hatched = hatched + 1 where id = v_uid;
  return jsonb_build_object('egg', r.egg, 'pet', v_pet, 'count', v_n, 'profile', _profile_json(v_uid));
end $$;

create or replace function claim_mission(p_sid text, p_id text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); m cfg_missions; p profiles; v_ok boolean;
begin
  select * into m from cfg_missions where id = p_id and active;
  if not found then raise exception 'bad_mission'; end if;
  select * into p from profiles where id = v_uid for update;
  if p.mc ? m.id then raise exception 'already_claimed'; end if;
  v_ok := case m.type when 'games' then p.games >= m.target when 'hatch' then p.hatched >= m.target else p.mp ? m.id end;
  if not v_ok then raise exception 'not_done'; end if;
  update profiles set coins = coins + m.reward, mc = mc || jsonb_build_object(m.id, true) where id = v_uid;
  return _profile_json(v_uid);
end $$;

-- ---------- Classement (top 50 par niveau) ----------
create or replace function get_board(p_sid text, p_lvl text) returns jsonb language plpgsql stable security definer
set search_path = public as $$
declare v_col text; v_res jsonb; v_uid uuid := _me(p_sid);
begin
  v_col := case p_lvl when 'easy' then 'b_easy' when 'normal' then 'b_normal' when 'hard' then 'b_hard'
                      when 'nightmare' then 'b_nightmare' else null end;
  if v_col is null then raise exception 'bad_level'; end if;
  execute format($q$
    select coalesce(jsonb_agg(jsonb_build_object('rank', rk, 'name', name, 'pet', pet, 'score', sc, 'me', id = $1) order by rk), '[]')
    from (select id, name, coalesce(team ->> 0, '') as pet, %1$I as sc, row_number() over (order by %1$I desc, created_at) as rk
          from profiles where %1$I > 0 order by %1$I desc, created_at limit 50) x
  $q$, v_col) into v_res using v_uid;
  return v_res;
end $$;

-- ---------- Duels : matchmaking automatique ----------
-- Anciennes fonctions à code : supprimées.
drop function if exists create_duel(text, text);
drop function if exists join_duel(text, text);
drop function if exists leave_duel(text, text);
drop function if exists start_duel(text, text);
drop function if exists _duel_state(text);

create or replace function _duel_state(p_code text) returns jsonb language sql stable
set search_path = public as $$
  select jsonb_build_object('code', d.code, 'lvl', d.lvl, 'mode', d.mode, 'status', d.status, 'reason', d.reason,
    'start_in', greatest(0, round(extract(epoch from (d.started_at - now())) * 1000))::int,
    'winner', case when d.winner is null then null else
       jsonb_build_object('uid', d.winner, 'name', d.winner_name, 'tries', d.winner_tries, 'time', d.winner_time) end,
    'dw', d.delta_w, 'dl', d.delta_l,
    'players', coalesce((select jsonb_agg(jsonb_build_object('uid', dp.uid, 'name', dp.name,
        'trophies', coalesce((select trophies from profiles where id = dp.uid), 0)) order by dp.joined_at, dp.uid)
        from duel_players dp where dp.code = d.code), '[]'))
  from duels d where d.code = p_code
$$;

-- Le duel en cours d'un joueur (s'il y en a un).
create or replace function _duel_active(p_uid uuid) returns text language sql stable
set search_path = public as $$
  select d.code from duels d join duel_players dp on dp.code = d.code
  where dp.uid = p_uid and d.status = 'playing' order by d.created_at desc limit 1
$$;

-- Termine un duel UNE seule fois. Gère les trophées (duel classé seulement).
-- Ne donne ni pièces ni trophées en duel occasionnel.
create or replace function _finish_duel(p_code text, p_winner uuid, p_reason text, p_tries int, p_time numeric) returns boolean
language plpgsql volatile set search_path = public as $$
declare d duels; v_loser uuid; wt int; lt int; v_e numeric; v_dw int := 0; v_dl int := 0; v_k numeric := _setting('duel_k');
begin
  select * into d from duels where code = p_code for update;
  if not found or d.status <> 'playing' or d.winner is not null then return false; end if;
  v_loser := case when d.p1 = p_winner then d.p2 else d.p1 end;
  -- on verrouille les deux profils dans un ordre fixe (pas de blocage croisé)
  perform 1 from profiles where id in (d.p1, d.p2) order by id for update;
  if d.mode = 'ranked' then
    select trophies into wt from profiles where id = p_winner;
    select trophies into lt from profiles where id = v_loser;
    v_e := 1 / (1 + power(10, (lt - wt) / 200.0));          -- chance de gagner du vainqueur
    v_dw := greatest(8, least(v_k, round(v_k * (1 - v_e))))::int;
    v_dl := least(v_dw, lt);                                  -- jamais en dessous de 0
    update profiles set trophies = trophies + v_dw, duel_wins = duel_wins + 1 where id = p_winner;
    update profiles set trophies = trophies - v_dl, duel_losses = duel_losses + 1 where id = v_loser;
  end if;
  update profiles set games = games + 1 where id in (p_winner, v_loser);
  update duels set status = 'done', winner = p_winner, reason = p_reason, winner_tries = p_tries, winner_time = p_time,
    winner_name = (select name from profiles where id = p_winner), delta_w = v_dw, delta_l = v_dl
    where code = p_code;
  update games set status = 'won' where duel_code = p_code and uid = p_winner and status = 'playing';
  update games set status = 'lost' where duel_code = p_code and uid = v_loser and status = 'playing';
  return true;
end $$;

-- Détecte les abandons / déconnexions. Un joueur silencieux depuis trop longtemps perd par forfait ;
-- si les deux sont partis, ou si le duel dure trop longtemps, il est annulé sans changer les trophées.
create or replace function _duel_sweep(p_code text) returns void language plpgsql volatile set search_path = public as $$
declare d duels; v_idle interval := make_interval(secs => _setting('duel_idle_s')::int);
        s1 boolean; s2 boolean;
begin
  select * into d from duels where code = p_code for update;
  if not found or d.status <> 'playing' then return; end if;
  if d.started_at < now() - make_interval(mins => _setting('duel_max_min')::int) then
    update duels set status = 'closed', reason = 'timeout' where code = p_code;
    update games set status = 'lost' where duel_code = p_code and status = 'playing';
    return;
  end if;
  select coalesce(bool_or(last_seen < now() - v_idle) filter (where uid = d.p1), true),
         coalesce(bool_or(last_seen < now() - v_idle) filter (where uid = d.p2), true)
    into s1, s2 from duel_players where code = p_code;
  if s1 and s2 then
    update duels set status = 'closed', reason = 'abandoned' where code = p_code;
    update games set status = 'lost' where duel_code = p_code and status = 'playing';
  elsif s1 then perform _finish_duel(p_code, d.p2, 'forfeit', null, null);
  elsif s2 then perform _finish_duel(p_code, d.p1, 'forfeit', null, null);
  end if;
end $$;

create or replace function _duel_matched(p_uid uuid, p_code text) returns jsonb language plpgsql volatile set search_path = public as $$
begin
  delete from duel_queue where uid = p_uid;
  update duel_players set last_seen = now() where code = p_code and uid = p_uid;
  return jsonb_build_object('status', 'matched', 'duel', _duel_state(p_code));
end $$;

-- Recherche d'adversaire. Le client rappelle cette fonction toutes les ~1,5 s tant qu'il cherche :
-- c'est à la fois le "je suis toujours là" et une nouvelle tentative de rencontre (la tolérance de
-- trophées s'élargit avec l'attente en mode classé).
create or replace function matchmake(p_sid text, p_mode text, p_lvl text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare
  v_uid uuid := _me(p_sid); v_code text; v_tr int; v_name text; q duel_queue; o duel_queue; v_n int;
  v_win numeric; v_cd interval := make_interval(mins => _setting('ranked_cooldown_min')::int);
begin
  if p_mode not in ('casual', 'ranked') then raise exception 'bad_mode'; end if;
  if not exists (select 1 from cfg_levels where id = p_lvl) then raise exception 'bad_level'; end if;
  -- un seul matchmaking à la fois pour tout le monde : pas de doublons ni de double rencontre
  perform pg_advisory_xact_lock(hashtext('pom_matchmaking'));
  delete from duel_queue where (matched_code is null and last_seen < now() - interval '10 seconds')
                            or (matched_code is not null and last_seen < now() - interval '90 seconds');

  -- déjà dans un duel en cours ? on le reprend (jamais deux duels en même temps)
  v_code := _duel_active(v_uid);
  if v_code is not null then
    perform _duel_sweep(v_code);
    v_code := _duel_active(v_uid);
    if v_code is not null then return _duel_matched(v_uid, v_code); end if;
  end if;

  select * into q from duel_queue where uid = v_uid;
  if found and q.matched_code is not null then
    if exists (select 1 from duels where code = q.matched_code and status = 'playing') then
      return _duel_matched(v_uid, q.matched_code);
    end if;
    delete from duel_queue where uid = v_uid;
  end if;

  select trophies, name into v_tr, v_name from profiles where id = v_uid;
  insert into duel_queue (uid, mode, lvl, trophies) values (v_uid, p_mode, p_lvl, v_tr)
  on conflict (uid) do update set
    joined_at = case when duel_queue.mode = excluded.mode and duel_queue.lvl = excluded.lvl and duel_queue.matched_code is null
                     then duel_queue.joined_at else now() end,
    mode = excluded.mode, lvl = excluded.lvl, trophies = excluded.trophies, last_seen = now(), matched_code = null;
  select * into q from duel_queue where uid = v_uid;

  -- candidat : même mode, même niveau, présent récemment, pas déjà en duel ; en classé : trophées proches
  select oo.* into o from duel_queue oo
  where oo.uid <> v_uid and oo.mode = p_mode and oo.lvl = p_lvl and oo.matched_code is null
    and oo.last_seen > now() - interval '8 seconds'
    and not exists (select 1 from duel_players dp join duels dd on dd.code = dp.code where dp.uid = oo.uid and dd.status = 'playing')
    and (p_mode = 'casual' or (
          abs(oo.trophies - q.trophies) <= _setting('mm_window')
              + _setting('mm_window_step') * floor(extract(epoch from (now() - least(oo.joined_at, q.joined_at))))
          and not exists (select 1 from duels x where x.mode = 'ranked' and x.created_at > now() - v_cd
                          and ((x.p1 = v_uid and x.p2 = oo.uid) or (x.p1 = oo.uid and x.p2 = v_uid)))))
  order by abs(oo.trophies - q.trophies), oo.joined_at
  limit 1;

  if found then
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
    insert into duels (code, lvl, mode, status, started_at, p1, p2) values (v_code, p_lvl, p_mode, 'playing', now() + interval '4 seconds', o.uid, v_uid);
    insert into duel_secrets (code, secret) values (v_code, _new_secret(p_lvl));
    insert into duel_players (code, uid, name) select v_code, id, name from profiles where id in (o.uid, v_uid);
    update duel_queue set matched_code = v_code where uid = o.uid;
    return _duel_matched(v_uid, v_code);
  end if;

  select count(*) into v_n from duel_queue where mode = p_mode and lvl = p_lvl and matched_code is null and last_seen > now() - interval '8 seconds';
  return jsonb_build_object('status', 'searching', 'waited', round(extract(epoch from (now() - q.joined_at)))::int, 'searching', v_n);
end $$;

-- Annuler la recherche. Si un adversaire vient d'être trouvé entre-temps, on ne peut plus annuler
-- (sinon on pourrait fuir un duel classé que l'on sent perdu d'avance).
create or replace function cancel_match(p_sid text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); q duel_queue; v_code text;
begin
  perform pg_advisory_xact_lock(hashtext('pom_matchmaking'));
  v_code := _duel_active(v_uid);
  if v_code is not null then return _duel_matched(v_uid, v_code); end if;
  select * into q from duel_queue where uid = v_uid;
  if found and q.matched_code is not null and exists (select 1 from duels where code = q.matched_code and status = 'playing') then
    return _duel_matched(v_uid, q.matched_code);
  end if;
  delete from duel_queue where uid = v_uid;
  return jsonb_build_object('status', 'cancelled');
end $$;

-- Sondage d'un duel (aussi le "je suis toujours connecté" : sans nouvelles pendant 30 s = forfait).
create or replace function duel_state(p_sid text, p_code text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); v_state jsonb;
begin
  if not exists (select 1 from duel_players where code = p_code and uid = v_uid) then raise exception 'no_room'; end if;
  update duel_players set last_seen = now() where code = p_code and uid = v_uid;
  perform _duel_sweep(p_code);
  v_state := _duel_state(p_code);
  if v_state ->> 'status' <> 'playing' then v_state := v_state || jsonb_build_object('profile', _profile_json(v_uid)); end if;
  return v_state;
end $$;

-- Abandon volontaire : défaite immédiate (en classé, les trophées sont perdus).
create or replace function forfeit_duel(p_sid text, p_code text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); d duels;
begin
  select * into d from duels where code = p_code for update;
  if not found or not exists (select 1 from duel_players where code = p_code and uid = v_uid) then raise exception 'no_room'; end if;
  if d.status = 'playing' then
    perform _finish_duel(p_code, case when d.p1 = v_uid then d.p2 else d.p1 end, 'forfeit', null, null);
  end if;
  return _duel_state(p_code) || jsonb_build_object('profile', _profile_json(v_uid));
end $$;

-- Chaque joueur crée sa propre partie (même nombre secret) ; elle démarre pour les deux à la même seconde.
create or replace function duel_game(p_sid text, p_code text) returns jsonb language plpgsql volatile security definer
set search_path = public as $$
declare v_uid uuid := _me(p_sid); d duels; v_gid uuid; v_secret bigint;
begin
  select * into d from duels where code = p_code;
  if not found or d.status <> 'playing' then raise exception 'no_room'; end if;
  if not exists (select 1 from duel_players where code = p_code and uid = v_uid) then raise exception 'no_room'; end if;
  select id into v_gid from games where uid = v_uid and duel_code = p_code and status = 'playing' limit 1;
  if v_gid is null then
    select secret into v_secret from duel_secrets where code = p_code;
    insert into games (uid, lvl, secret, duel_code, started_at) values (v_uid, d.lvl, v_secret, p_code, d.started_at) returning id into v_gid;
  end if;
  return jsonb_build_object('gid', v_gid, 'lvl', d.lvl,
    'start_in', greatest(0, round(extract(epoch from (d.started_at - now())) * 1000))::int);
end $$;

-- ---------- Droits : seules les fonctions publiques sont appelables ----------
do $$
declare r record;
begin
  for r in select p.oid::regprocedure as sig, p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.prokind = 'f' loop
    execute format('revoke all on function %s from public, anon, authenticated', r.sig);
    if left(r.proname, 1) <> '_' and left(r.proname, 6) <> 'admin_' then
      execute format('grant execute on function %s to authenticated', r.sig);
    end if;
  end loop;
  grant execute on function get_config() to anon;
  grant execute on function resolve_login(text) to anon;
  grant execute on function check_name(text) to anon;
end $$;
grant select on cfg_levels, cfg_rarities, cfg_pets, cfg_eggs, cfg_settings, cfg_daily, cfg_missions to anon, authenticated;
