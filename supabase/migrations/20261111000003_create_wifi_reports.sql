-- 20261111000003_create_wifi_reports.sql
-- Tabel wifi_reports: laporan hasil pemeriksaan jaringan WiFi pengguna.
-- `kekuatan_sinyal` berisi label kekuatan sinyal (misalnya lemah, sedang,
-- atau kuat). `channel` adalah kanal WiFi yang dipakai. `dns` menyimpan
-- alamat server DNS yang terdeteksi. `rekomendasi` berisi saran perbaikan
-- jaringan dalam bentuk teks.

create table if not exists public.wifi_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  ssid text,
  kecepatan_koneksi_mbps numeric,
  kekuatan_sinyal text,
  channel integer,
  dns text,
  ping_ms integer,
  rekomendasi text,
  dibuat_pada timestamptz not null default now()
);

create index if not exists wifi_reports_user_id_idx
  on public.wifi_reports (user_id);

create index if not exists wifi_reports_dibuat_pada_idx
  on public.wifi_reports (dibuat_pada desc);

-- Row Level Security wajib aktif pada migrasi yang sama dengan pembuatan tabel.
alter table public.wifi_reports enable row level security;

-- Pengguna hanya dapat membaca laporan WiFi milik sendiri.
create policy "Pengguna membaca laporan WiFi milik sendiri"
  on public.wifi_reports
  for select
  using (auth.uid() = user_id);

-- Pengguna hanya dapat membuat laporan WiFi untuk dirinya sendiri.
create policy "Pengguna membuat laporan WiFi milik sendiri"
  on public.wifi_reports
  for insert
  with check (auth.uid() = user_id);

-- Pengguna hanya dapat mengubah laporan WiFi milik sendiri.
create policy "Pengguna mengubah laporan WiFi milik sendiri"
  on public.wifi_reports
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Pengguna hanya dapat menghapus laporan WiFi milik sendiri.
create policy "Pengguna menghapus laporan WiFi milik sendiri"
  on public.wifi_reports
  for delete
  using (auth.uid() = user_id);
