-- 20261119000005_handle_new_user.sql
-- Trigger auto-create baris profiles saat pengguna baru mendaftar
-- lewat Supabase Auth (menutup temuan validasi runbook §8 butir 3:
-- sebelumnya aplikasi wajib insert baris profil sendiri setelah signup).
-- Nama diambil dari metadata OAuth (full_name / name), lalu dari bagian
-- lokal email, terakhir fallback 'Pengguna' — kolom `nama` NOT NULL
-- jadi fallback wajib non-null.
-- Function SECURITY DEFINER agar bisa insert ke public.profiles
-- melewati RLS (trigger berjalan di konteks auth.users, bukan JWT user).

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nama)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(new.email, '@', 1),
      'Pengguna'
    )
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
