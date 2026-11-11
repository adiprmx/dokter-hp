-- 20261111000002_create_health_checks.sql
-- Tabel health_checks: hasil pemeriksaan kesehatan HP pengguna.
-- `skor` bernilai 0 sampai 100. `ringkasan` menyimpan detail hasil
-- pemeriksaan dalam format JSON (misalnya status baterai, penyimpanan,
-- performa, dan keamanan). `deleted_at` dipakai untuk soft-delete:
-- baris yang sudah dihapus ditandai waktunya, bukan dihapus fisik.
-- Aplikasi wajib memfilter `deleted_at is null` saat menampilkan data.
-- `sync_status` menandai status sinkronisasi dari perangkat:
-- 'pending' (menunggu), 'synced' (tersinkron), atau 'failed' (gagal).

create table if not exists public.health_checks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  skor integer not null check (skor >= 0 and skor <= 100),
  ringkasan jsonb not null default '{}'::jsonb,
  dibuat_pada timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_status text not null default 'pending'
    check (sync_status in ('pending', 'synced', 'failed'))
);

create index if not exists health_checks_user_id_idx
  on public.health_checks (user_id);

create index if not exists health_checks_dibuat_pada_idx
  on public.health_checks (dibuat_pada desc);

-- Fungsi pemicu untuk memperbarui `updated_at` setiap kali baris diubah.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists health_checks_set_updated_at on public.health_checks;

create trigger health_checks_set_updated_at
  before update on public.health_checks
  for each row
  execute function public.set_updated_at();

-- Row Level Security wajib aktif pada migrasi yang sama dengan pembuatan tabel.
alter table public.health_checks enable row level security;

-- Pengguna hanya dapat membaca hasil pemeriksaan milik sendiri.
create policy "Pengguna membaca health check milik sendiri"
  on public.health_checks
  for select
  using (auth.uid() = user_id);

-- Pengguna hanya dapat membuat hasil pemeriksaan untuk dirinya sendiri.
create policy "Pengguna membuat health check milik sendiri"
  on public.health_checks
  for insert
  with check (auth.uid() = user_id);

-- Pengguna hanya dapat mengubah hasil pemeriksaan milik sendiri.
create policy "Pengguna mengubah health check milik sendiri"
  on public.health_checks
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Pengguna hanya dapat menghapus hasil pemeriksaan milik sendiri.
create policy "Pengguna menghapus health check milik sendiri"
  on public.health_checks
  for delete
  using (auth.uid() = user_id);
