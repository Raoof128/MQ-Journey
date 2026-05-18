-- Migration: Create favorite_buildings table
-- Description: Stores user's favourite campus buildings with RLS

create table favorite_buildings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  building_id text not null,
  building_name text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, building_id)
);

alter table favorite_buildings enable row level security;

create policy "Users can read own favourites"
  on favorite_buildings for select
  using (auth.uid() = user_id);

create policy "Users can create own favourites"
  on favorite_buildings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own favourites"
  on favorite_buildings for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own favourites"
  on favorite_buildings for delete
  using (auth.uid() = user_id);

-- Auto-update updated_at on row modification
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_favorite_buildings_updated_at
  before update on favorite_buildings
  for each row
  execute function set_updated_at();
