-- 1. Yüklemeler için Storage Bucket Oluşturma (Eğer yoksa panelden Storage kısmından "uploads" adında public bir bucket açabilirsiniz)
-- Supabase SQL editöründen bucket açmak için yetkiniz varsa çalışır, yoksa manuel arayüzden yapın.
insert into storage.buckets (id, name, public) values ('uploads', 'uploads', true) on conflict do nothing;

-- 2. Profiller (Profiles) Tablosu
-- Kullanıcı kayıt olduğunda (auth.users tablosuna düştüğünde) buraya da bir profil açılır.
create table public.profiles (
  id uuid references auth.users not null primary key,
  username text unique,
  full_name text,
  avatar_url text,
  bio text,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Profil okuma herkes için açık
alter table public.profiles enable row level security;
create policy "Public profiles are viewable by everyone." on profiles for select using (true);
create policy "Users can insert their own profile." on profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on profiles for update using (auth.uid() = id);

-- Otomatik Profil Oluşturma (Trigger)
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url)
  values (new.id, split_part(new.email, '@', 1), '', 'https://picsum.photos/200/200');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 3. Gönderiler (Posts & Reels) Tablosu
create table public.posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  content text,
  image_url text, -- Yüklenen resmin/videonun saklama adresi
  type text check (type in ('post', 'reel')) default 'post',
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.posts enable row level security;
create policy "Posts are viewable by everyone." on posts for select using (true);
create policy "Users can insert their own posts." on posts for insert with check (auth.uid() = user_id);
create policy "Users can delete own posts." on posts for delete using (auth.uid() = user_id);

-- Storage (Resim yükleme) İzinleri (Sadece giriş yapmış kullanıcılar uploads bucket'ına yükleyebilir)
create policy "Avatar images are publicly accessible." on storage.objects for select using (bucket_id = 'uploads');
create policy "Anyone can upload an avatar." on storage.objects for insert with check (bucket_id = 'uploads');

-- 4. Mesajlar (Messages) Tablosu
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references public.profiles(id) not null,
  receiver_id uuid references public.profiles(id) not null,
  content text not null,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.messages enable row level security;
create policy "Users can read their own messages" on messages for select using (auth.uid() = sender_id or auth.uid() = receiver_id);
create policy "Users can send messages" on messages for insert with check (auth.uid() = sender_id);
