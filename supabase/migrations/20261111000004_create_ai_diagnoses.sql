-- 20261111000004_create_ai_diagnoses.sql
-- Tabel ai_diagnoses: riwayat tanya jawab diagnosis AI.
-- `health_check_id` boleh kosong bila pertanyaan diajukan tanpa
-- terikat pada satu hasil pemeriksaan tertentu. Bila terisi, baris
-- diagnosis ikut terhapus saat hasil pemeriksaan induk dihapus.

create table if not exists public.ai_diagnoses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  health_check_id uuid references public.health_checks (id) on delete cascade,
  pertanyaan text not null,
  jawaban text not null,
  dibuat_pada timestamptz not null default now()
);

create index if not exists ai_diagnoses_user_id_idx
  on public.ai_diagnoses (user_id);

create index if not exists ai_diagnoses_health_check_id_idx
  on public.ai_diagnoses (health_check_id);

create index if not exists ai_diagnoses_dibuat_pada_idx
  on public.ai_diagnoses (dibuat_pada desc);

-- Row Level Security wajib aktif pada migrasi yang sama dengan pembuatan tabel.
alter table public.ai_diagnoses enable row level security;

-- Pengguna hanya dapat membaca diagnosis milik sendiri.
create policy "Pengguna membaca diagnosis milik sendiri"
  on public.ai_diagnoses
  for select
  using (auth.uid() = user_id);

-- Pengguna hanya dapat membuat diagnosis untuk dirinya sendiri.
create policy "Pengguna membuat diagnosis milik sendiri"
  on public.ai_diagnoses
  for insert
  with check (auth.uid() = user_id);

-- Pengguna hanya dapat mengubah diagnosis milik sendiri.
create policy "Pengguna mengubah diagnosis milik sendiri"
  on public.ai_diagnoses
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Pengguna hanya dapat menghapus diagnosis milik sendiri.
create policy "Pengguna menghapus diagnosis milik sendiri"
  on public.ai_diagnoses
  for delete
  using (auth.uid() = user_id);
