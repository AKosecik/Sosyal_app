-- 1. Takip Sistemi Tablosu (follows)
create table if not exists public.follows (
  follower_id uuid references public.profiles(id) not null,
  following_id uuid references public.profiles(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  primary key (follower_id, following_id)
);

alter table public.follows enable row level security;
create policy "Herekese açık olarak takipçi bilgisini okuma." on follows for select using (true);
create policy "Kullanıcı sadece kendisi başkasını takip edebilir." on follows for insert with check (auth.uid() = follower_id);
create policy "Kullanıcı takibi bırakabilir." on follows for delete using (auth.uid() = follower_id);

-- 2. Kaydedilen Gönderiler Tablosu (saved_posts)
create table if not exists public.saved_posts (
  user_id uuid references public.profiles(id) not null,
  post_id uuid references public.posts(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  primary key (user_id, post_id)
);

alter table public.saved_posts enable row level security;
create policy "Kullanıcı sadece kendi kaydettiklerini görebilir." on saved_posts for select using (auth.uid() = user_id);
create policy "Kullanıcı kaydedebilir." on saved_posts for insert with check (auth.uid() = user_id);
create policy "Kullanıcı kaydı kaldırabilir." on saved_posts for delete using (auth.uid() = user_id);

-- 3. Profiles Tablosuna 'points' Sütunu Ekleme
alter table public.profiles add column if not exists points integer default 0;

-- 4. Posts Tablosunun Type constraint'ini 'quote' da alacak Şekilde Değiştirme
-- Önce eski check constraint'i bulup droplayacağız, sonra yenisini ekleyeceğiz.
do $$ 
declare
    rec record;
begin
    -- Tablodaki type sütunundaki check constraint adını buluyor.
    for rec in 
        select tc.constraint_name 
        from information_schema.table_constraints tc 
        where tc.table_name = 'posts' and tc.constraint_type = 'CHECK' and tc.constraint_name not like '%not_null%'
    loop
        execute 'alter table public.posts drop constraint "' || rec.constraint_name || '"';
    end loop;
end $$;

-- Yeni constraint ekliyoruz
alter table public.posts add constraint posts_type_check check (type in ('post', 'reel', 'quote'));
