-- 1. Önce olası hatalı update profil politikasını siliyoruz
drop policy if exists "Users can update own profile." on public.profiles;
drop policy if exists "Users can insert their own profile." on public.profiles;

-- 2. Profili güncelleme kısıtlamasını eksiksiz formatta (hem USING hem WITH CHECK) yeniden ekliyoruz
create policy "Users can update own profile." 
on public.profiles 
for update 
using (auth.uid() = id) 
with check (auth.uid() = id);

-- 3. Gerekebilecek opsiyonel INSERT politikasını aynı formatla yedekliyoruz
create policy "Users can insert their own profile." 
on public.profiles 
for insert 
with check (auth.uid() = id);

-- (Eğer Select izinlerinde bir sorun olduysa diye garanti olması için bir kez daha drop/create yapalım)
drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
