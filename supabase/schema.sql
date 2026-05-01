-- around — Supabase schema
-- Run this in the Supabase SQL editor.

-- 1) profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique,
  display_name text,
  avatar_url text,
  status_message text,
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_all" on public.profiles
  for select using (true);

create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

-- 2) locations (latest position per user)
create table if not exists public.locations (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  updated_at timestamptz default now()
);

alter table public.locations enable row level security;

-- Friends + self can read each other's locations.
create policy "locations_select_friends" on public.locations
  for select using (
    user_id = auth.uid()
    or exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and ((f.user_id = auth.uid() and f.friend_id = locations.user_id)
          or (f.friend_id = auth.uid() and f.user_id = locations.user_id))
    )
  );

create policy "locations_upsert_own" on public.locations
  for insert with check (auth.uid() = user_id);

create policy "locations_update_own" on public.locations
  for update using (auth.uid() = user_id);

-- 3) friendships
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  friend_id uuid references public.profiles(id) on delete cascade,
  status text default 'pending', -- pending | accepted | blocked
  created_at timestamptz default now(),
  unique (user_id, friend_id)
);

alter table public.friendships enable row level security;

create policy "friendships_select_involved" on public.friendships
  for select using (auth.uid() in (user_id, friend_id));

create policy "friendships_insert_own" on public.friendships
  for insert with check (auth.uid() = user_id);

create policy "friendships_update_involved" on public.friendships
  for update using (auth.uid() in (user_id, friend_id));

-- 4) messages
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references public.profiles(id) on delete cascade,
  receiver_id uuid references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz default now(),
  read_at timestamptz
);

alter table public.messages enable row level security;

create policy "messages_select_involved" on public.messages
  for select using (auth.uid() in (sender_id, receiver_id));

create policy "messages_insert_sender" on public.messages
  for insert with check (auth.uid() = sender_id);

create policy "messages_update_involved" on public.messages
  for update using (auth.uid() in (sender_id, receiver_id));

-- Realtime
alter publication supabase_realtime add table public.locations;
alter publication supabase_realtime add table public.messages;
