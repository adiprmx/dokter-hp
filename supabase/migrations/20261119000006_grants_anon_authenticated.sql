-- 20261119000006_grants_anon_authenticated.sql
--
-- Memulihkan grant tabel yang HILANG TOTAL di proyek live
-- (terbukti tim verifikasi RLS + tim LIVE-API, 19-20 Nov 2026):
-- anon, authenticated, DAN service_role hanya punya REFERENCES, TRIGGER,
-- TRUNCATE di keempat tabel — tanpa SELECT/INSERT/UPDATE/DELETE sama
-- sekali, sehingga anon-only GET mengembalikan 401 code 42501 dan
-- service_role pun 403 code 42501.
--
-- Peran masing-masing grant:
--   - authenticated: SELECT, INSERT, UPDATE, DELETE — agar sync/insert
--     aplikasi jalan. RLS tetap membatasi tiap pengguna ke barisnya
--     sendiri (policy auth.uid() = user_id).
--   - anon: SELECT saja. Aman: policy RLS auth.uid() = user_id membuat
--     anon — tanpa uid — selalu mendapat [] (bukti RLS aktif, bukan
--     kebocoran). Anon tidak mendapat INSERT/UPDATE/DELETE.
--   - service_role: ALL — grant standar Supabase untuk service_role
--     (bypass RLS; dipakai backend tepercaya / admin).
--
-- RLS tetap AKTIF di keempat tabel (diaktifkan di migrasi 01-04);
-- grant ini hanya membuka pintu izin Postgres, policy RLS yang
-- menentukan baris mana yang terlihat.

grant select, insert, update, delete
  on public.profiles,
     public.health_checks,
     public.wifi_reports,
     public.ai_diagnoses
  to authenticated;

grant select
  on public.profiles,
     public.health_checks,
     public.wifi_reports,
     public.ai_diagnoses
  to anon;

grant all
  on public.profiles,
     public.health_checks,
     public.wifi_reports,
     public.ai_diagnoses
  to service_role;
