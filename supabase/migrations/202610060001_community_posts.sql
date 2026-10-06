-- Hayyina V2 community posts
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(trim(content)) between 1 and 5000),
  image_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(trim(content)) between 1 and 1000),
  created_at timestamptz not null default now()
);

alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;

drop policy if exists "posts read authenticated" on public.posts;
create policy "posts read authenticated" on public.posts for select to authenticated using (true);
drop policy if exists "posts insert own" on public.posts;
create policy "posts insert own" on public.posts for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "posts update own" on public.posts;
create policy "posts update own" on public.posts for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "posts delete own" on public.posts;
create policy "posts delete own" on public.posts for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "post likes read authenticated" on public.post_likes;
create policy "post likes read authenticated" on public.post_likes for select to authenticated using (true);
drop policy if exists "post likes insert own" on public.post_likes;
create policy "post likes insert own" on public.post_likes for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "post likes delete own" on public.post_likes;
create policy "post likes delete own" on public.post_likes for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "post comments read authenticated" on public.post_comments;
create policy "post comments read authenticated" on public.post_comments for select to authenticated using (true);
drop policy if exists "post comments insert own" on public.post_comments;
create policy "post comments insert own" on public.post_comments for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "post comments update own" on public.post_comments;
create policy "post comments update own" on public.post_comments for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "post comments delete own" on public.post_comments;
create policy "post comments delete own" on public.post_comments for delete to authenticated using ((select auth.uid()) = user_id);

create index if not exists idx_posts_created_at on public.posts(created_at desc);
create index if not exists idx_posts_user_id on public.posts(user_id);
create index if not exists idx_post_likes_post_id on public.post_likes(post_id);
create index if not exists idx_post_comments_post_id_created_at on public.post_comments(post_id, created_at desc);

notify pgrst, 'reload schema';
