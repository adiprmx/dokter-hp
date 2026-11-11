-- 20261111000001_create_profiles.sql
-- Tabel profiles: satu baris untuk setiap pengguna terautentikasi.
-- Baris dibuat setelah pengguna mendaftar lewat Supabase Auth.
-- Kolom `id` sama dengan id pengguna di auth.users.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nama text not null,
  dibuat_pada timestamptz not null default now()
);

-- Row Level Security wajib aktif pada migrasi yang sama dengan pembuatan tabel.
alter table public.profiles enable row level security;

-- Pengguna hanya dapat membaca profil milik sendiri.
create policy "Pengguna membaca profil milik sendiri"
  on public.profiles
  for select
  using (auth.uid() = id);

-- Pengguna hanya dapat membuat profil milik sendiri.
create policy "Pengguna membuat profil milik sendiri"
  on public.profiles
  for insert
  with check (auth.uid() = id);

-- Pengguna hanya dapat mengubah profil milik sendiri.
create policy "Pengguna mengubah profil milik sendiri"
  on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Pengguna hanya dapat menghapus profil milik sendiri.
create policy "Pengguna menghapus profil milik sendiri"
  on public.profiles
  for delete
  using (auth.uid() = id);
