-- Japan 2026 trip planner — Supabase schema
-- Run this once in Supabase Dashboard > SQL Editor > New query > Run.
-- Safe to re-run after "drop"-ing the objects below if you need to start over.

create extension if not exists pgcrypto;

-- ---------- profiles (one row per trip member, linked to auth.users) ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text not null,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- auto-create a profile row whenever a new auth user is created
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, display_name, is_admin)
  values (
    new.id,
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'display_name',
    coalesce((new.raw_user_meta_data->>'is_admin')::boolean, false)
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- trip data tables ----------
create table public.days (
  id uuid primary key default gen_random_uuid(),
  day_number int not null,
  date date,
  city text,
  created_at timestamptz not null default now()
);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  day_id uuid not null references public.days(id) on delete cascade,
  time text,
  activity text,
  location_link text,
  notes text,
  created_at timestamptz not null default now()
);

create table public.stays (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  check_in date,
  check_out date,
  location_link text,
  notes text,
  created_at timestamptz not null default now()
);

create table public.suggestions (
  id uuid primary key default gen_random_uuid(),
  place text not null,
  notes text,
  location_link text,
  added_by uuid references public.profiles(id),
  added_by_name text,
  day_label text,
  created_at timestamptz not null default now()
);

create table public.journal (
  id uuid primary key default gen_random_uuid(),
  author uuid references public.profiles(id),
  author_name text,
  date date,
  text text not null,
  created_at timestamptz not null default now()
);

create table public.activity_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id),
  username text,
  action text not null,
  summary text not null,
  created_at timestamptz not null default now()
);

create table public.travel (
  id uuid primary key default gen_random_uuid(),
  name text,
  type text,
  departure_location text,
  departure_at timestamp,
  arrival_location text,
  arrival_at timestamp,
  notes text,
  created_at timestamptz not null default now()
);

-- ---------- row level security ----------
alter table public.profiles enable row level security;
alter table public.days enable row level security;
alter table public.activities enable row level security;
alter table public.stays enable row level security;
alter table public.suggestions enable row level security;
alter table public.journal enable row level security;
alter table public.activity_log enable row level security;
alter table public.travel enable row level security;

-- only the 5 signed-in trip members can read profiles (needed to show display names / admin flag)
create policy "trip members can read profiles" on public.profiles
  for select using (auth.role() = 'authenticated');

-- trip data: any signed-in trip member has full read/write (matches the old shared-passcode behavior)
create policy "trip members full access" on public.days
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "trip members full access" on public.activities
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "trip members full access" on public.stays
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "trip members full access" on public.suggestions
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "trip members full access" on public.journal
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "trip members full access" on public.travel
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- activity_log: anyone signed in can add an entry, but only the admin can read the feed
create policy "trip members can write activity log" on public.activity_log
  for insert with check (auth.role() = 'authenticated');
create policy "admin can read activity log" on public.activity_log
  for select using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  );
