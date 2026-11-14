-- 1. Hikayeler (Stories) Tablosu
create table public.stories (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  image_url text not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
  -- İleri seviye: expires_at timestamp eklenebilir (24 saat sonra silinmesi için)
);

alter table public.stories enable row level security;
create policy "Stories are viewable by everyone." on stories for select using (true);
create policy "Users can insert their own stories." on stories for insert with check (auth.uid() = user_id);
create policy "Users can delete own stories." on stories for delete using (auth.uid() = user_id);
