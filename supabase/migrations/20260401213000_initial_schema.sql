create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'My Household',
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.household_memberships (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner', 'adult', 'guest')),
  created_at timestamptz not null default timezone('utc', now()),
  unique (household_id, user_id),
  unique (user_id)
);

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  household_id uuid references public.households(id) on delete set null,
  display_name text not null default '',
  preferred_name text not null default '',
  assistant_tone text not null default 'Warm, direct, and observant.',
  support_style text not null default 'Coach me gently, but do not sugarcoat the truth.',
  life_focuses text[] not null default '{}',
  likes text[] not null default '{}',
  dislikes text[] not null default '{}',
  boundaries text[] not null default '{}',
  onboarding_answers jsonb not null default '{}'::jsonb,
  summary text not null default '',
  is_onboarding_complete boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  last_message_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('system', 'user', 'assistant', 'tool')),
  content text not null default '',
  reasoning text,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.memory_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_conversation_id uuid references public.conversations(id) on delete set null,
  kind text not null check (kind in ('identity', 'preference', 'goal', 'routine', 'context')),
  title text not null,
  summary text not null,
  status text not null default 'active' check (status in ('active', 'archived', 'rejected')),
  confidence numeric(4, 2) not null default 0.50,
  evidence jsonb not null default '{}'::jsonb,
  last_reinforced_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.media_assets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid references public.conversations(id) on delete set null,
  message_id uuid references public.messages(id) on delete set null,
  bucket text not null default 'media-assets',
  storage_path text not null unique,
  content_type text not null,
  byte_size integer not null check (byte_size > 0),
  prompt text not null default '',
  analysis_summary text not null default '',
  analysis_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.memory_feedback_events (
  id uuid primary key default gen_random_uuid(),
  memory_id uuid not null references public.memory_entries(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  feedback text not null check (feedback in ('accepted', 'rejected', 'reinforced')),
  note text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists conversations_user_last_message_idx
  on public.conversations (user_id, last_message_at desc);

create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at asc);

create index if not exists memory_entries_user_status_idx
  on public.memory_entries (user_id, status, updated_at desc);

create index if not exists media_assets_user_created_idx
  on public.media_assets (user_id, created_at desc);

create trigger households_set_updated_at
before update on public.households
for each row execute function public.set_updated_at();

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger conversations_set_updated_at
before update on public.conversations
for each row execute function public.set_updated_at();

create trigger memory_entries_set_updated_at
before update on public.memory_entries
for each row execute function public.set_updated_at();

create or replace function public.bootstrap_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_household_id uuid;
  v_display_name text;
begin
  v_display_name := coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), '');

  insert into public.households (name, created_by)
  values (
    case
      when v_display_name = '' then 'My Household'
      else v_display_name || '''s Household'
    end,
    new.id
  )
  returning id into v_household_id;

  insert into public.household_memberships (household_id, user_id, role)
  values (v_household_id, new.id, 'owner');

  insert into public.profiles (
    user_id,
    household_id,
    display_name,
    preferred_name
  )
  values (
    new.id,
    v_household_id,
    v_display_name,
    v_display_name
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.bootstrap_new_user();

alter table public.households enable row level security;
alter table public.household_memberships enable row level security;
alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.memory_entries enable row level security;
alter table public.media_assets enable row level security;
alter table public.memory_feedback_events enable row level security;

create policy "Household members can read their household"
on public.households
for select
to authenticated
using (
  exists (
    select 1
    from public.household_memberships memberships
    where memberships.household_id = households.id
      and memberships.user_id = auth.uid()
  )
);

create policy "Household members can update their household"
on public.households
for update
to authenticated
using (
  exists (
    select 1
    from public.household_memberships memberships
    where memberships.household_id = households.id
      and memberships.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.household_memberships memberships
    where memberships.household_id = households.id
      and memberships.user_id = auth.uid()
  )
);

create policy "Users can read household memberships they belong to"
on public.household_memberships
for select
to authenticated
using (
  user_id = auth.uid()
  or household_id in (
    select household_id
    from public.household_memberships
    where user_id = auth.uid()
  )
);

create policy "Users can read their profile"
on public.profiles
for select
to authenticated
using (user_id = auth.uid());

create policy "Users can update their profile"
on public.profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can insert their profile"
on public.profiles
for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can manage their conversations"
on public.conversations
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can manage their messages"
on public.messages
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can manage their memories"
on public.memory_entries
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can manage their media assets"
on public.media_assets
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can manage their memory feedback"
on public.memory_feedback_events
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'media-assets',
  'media-assets',
  false,
  10485760,
  array['image/jpeg', 'image/png']
)
on conflict (id) do nothing;

create policy "Users can read their own stored images"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'media-assets'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can write their own stored images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'media-assets'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update their own stored images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'media-assets'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'media-assets'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete their own stored images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'media-assets'
  and (storage.foldername(name))[1] = auth.uid()::text
);
