-- =============================================
-- FERROFIX — Supabase SQL Schema
-- Pokrenuti u: Supabase → SQL Editor → New query
-- =============================================

-- PRODUCTS
create table if not exists products (
  id text primary key,
  name text not null,
  category text,
  price numeric default 0,
  unit text default 'kom',
  stock integer default 0,
  description text,
  created_at timestamptz default now()
);

-- ORDERS
create table if not exists orders (
  id text primary key,
  customer jsonb,
  delivery jsonb,
  items jsonb,
  total numeric default 0,
  status text default 'nova',
  created_at timestamptz default now()
);

-- SLOTS
create table if not exists slots (
  id text primary key,
  label text,
  time text,
  active boolean default true
);

-- =============================================
-- DOZVOLE (RLS) — anon može sve što treba
-- =============================================
alter table products enable row level security;
alter table orders enable row level security;
alter table slots enable row level security;

-- Products: svi čitaju, samo admin menja
create policy "Public read products" on products for select using (true);
create policy "Anon insert products" on products for insert with check (true);
create policy "Anon update products" on products for update using (true);
create policy "Anon delete products" on products for delete using (true);

-- Orders: svi mogu da naruče i čitaju
create policy "Public insert orders" on orders for insert with check (true);
create policy "Public read orders" on orders for select using (true);
create policy "Public update orders" on orders for update using (true);
create policy "Public delete orders" on orders for delete using (true);

-- Slots: svi čitaju, admin menja
create policy "Public read slots" on slots for select using (true);
create policy "Anon insert slots" on slots for insert with check (true);
create policy "Anon update slots" on slots for update using (true);
create policy "Anon delete slots" on slots for delete using (true);

-- NOTIFICATION EMAILS
create table if not exists notification_emails (
  id uuid default gen_random_uuid() primary key,
  email text not null unique,
  active boolean default true,
  created_at timestamptz default now()
);
alter table notification_emails enable row level security;
create policy "Anon manage notification emails" on notification_emails for all using (true);

-- =============================================
-- DEFAULT SLOTOVI
-- =============================================
insert into slots (id, label, time, active) values
  ('jutro', '🌅 Pre podne', '08:00 – 13:00', true),
  ('popodne', '🌇 Posle podne', '13:00 – 18:00', true)
on conflict (id) do nothing;

-- =============================================
-- DEMO ARTIKLI (opciono, možeš obrisati)
-- =============================================
insert into products (id, name, category, price, unit, stock, description) values
  ('p1', 'Čekić 500g', 'Alat', 850, 'kom', 20, 'Klasičan drvobradni čekić, pogodan za opštu upotrebu.'),
  ('p2', 'Šrafciger set 6/1', 'Alat', 1200, 'set', 15, 'Komplet odvijača flat i PH u plastičnoj kutiji.'),
  ('p3', 'Šrafovi 4x40 (200 kom)', 'Vijci i ekseri', 320, 'pak', 50, 'Pocinkovani šrafovi za drvo, torx glava.'),
  ('p4', 'Ekseri 80mm (1kg)', 'Vijci i ekseri', 180, 'kg', 30, 'Standardni građevinski ekseri, pocinkovani.'),
  ('p5', 'Boja fasadna bela 5L', 'Boje i lakovi', 2800, 'kan', 12, 'Akrilna fasadna boja, vodoodporna, UV stabilna.'),
  ('p6', 'Lak za drvo bezbojni 1L', 'Boje i lakovi', 950, 'lit', 18, 'Alkidni lak za unutrašnje površine, sjaj.'),
  ('p7', 'Cement 25kg', 'Građevinski materijal', 580, 'vrća', 40, 'Portland cement CEM II 42.5N.'),
  ('p8', 'Cigla puna 25x12x6.5', 'Građevinski materijal', 38, 'kom', 500, 'Puna opeka, klasa A.'),
  ('p9', 'Cev pvc 1/2"', 'Vodoinstalacije', 280, 'm', 80, 'PVC cev za hladnu vodu, presek 15mm.'),
  ('p10', 'Slavina zidna 1/2"', 'Vodoinstalacije', 750, 'kom', 10, 'Hromirana slavina, zidne montaže.'),
  ('p11', 'Kabl 3x1.5mm2', 'Elektro materijal', 95, 'm', 200, 'Trofazni instalacioni kabl NYM-J.'),
  ('p12', 'Osigurač 16A', 'Elektro materijal', 120, 'kom', 35, 'Automatski osigurač, jednopolni, B karakteristika.')
on conflict (id) do nothing;
