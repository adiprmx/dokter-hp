// functions/fcm-notify/index.ts
//
// Edge Function: kirim notifikasi push lewat Firebase Cloud
// Messaging (FCM) HTTP v1 API.
//
// KEPUTUSAN KEAMANAN (temuan QA S-3, diperbaiki 11 Nov 2026):
// function ini NONAKTIF secara default. Tanpa allowlist, setiap
// panggilan ditolak dengan 503 dan tidak ada push yang terkirim.
// Alasannya: function ini mengirim push ke token perangkat mana pun
// yang diberikan pemanggil. Bila sembarang pengguna login boleh
// memanggilnya, pengguna mana pun bisa mengirim push ke perangkat
// orang lain dan membakar kuota FCM.
//
// Yang boleh memanggil setelah allowlist diatur: HANYA pengguna yang
// id-nya tercantum di allowlist (biasanya akun admin). Pemeriksaan
// dilakukan di dalam function, bukan hanya di gateway:
//   1. Gateway Supabase (`verify_jwt = true` di config.toml)
//      menolak pemanggil tanpa JWT pengguna yang valid.
//   2. Function membaca klaim `sub` (id pengguna) dari payload JWT
//      dan menolak bila id itu tidak ada di allowlist.
//   Tanda tangan JWT tidak diperiksa ulang di sini karena gateway
//   sudah memverifikasinya sebelum request sampai ke function.
//   Jangan pernah men-deploy function ini dengan `verify_jwt = false`:
//   tanpa itu, siapa pun dengan anon key bisa memanggilnya.
//
// Mengaktifkan (hanya bila push benar-benar dipakai, oleh admin):
//   supabase secrets set FCM_NOTIFY_ALLOWED_USER_IDS=<id-pengguna-admin>
//   (beberapa id dipisah koma, tanpa spasi)
//   supabase secrets set FCM_PROJECT_ID=<id proyek Firebase>
//   supabase secrets set FCM_ACCESS_TOKEN=<token akses OAuth 2.0>
//   supabase functions deploy fcm-notify
// Id pengguna dilihat di dashboard Supabase (Authentication > Users).
// Bila allowlist dikosongkan lagi, function kembali nonaktif.
//
// Catatan: model ini adalah relay khusus admin, BUKAN pengiriman
// push oleh pengguna ke perangkatnya sendiri. Untuk pengiriman
// mandiri per pengguna, dibutuhkan tabel pemetaan token perangkat
// per pengguna di server dan pemeriksaan kepemilikan token — itu
// belum dibangun, dan aplikasi v1.0.0 tidak memakai function ini.
//
// Cara pakai (setelah diaktifkan):
//   POST /functions/v1/fcm-notify
//   Header: Authorization: Bearer <token pengguna yang diizinkan>
//   Body JSON:
//     {
//       "token": "<token perangkat FCM tujuan>",
//       "title": "Pemeriksaan selesai",
//       "body": "Skor kesehatan HP Anda 82 dari 100.",
//       "data": { "jenis": "health_check" }
//     }
//
//   Respons sukses (200):
//     { "sukses": true, "nama_pesan": "projects/.../messages/..." }
//
// Catatan setup:
//   1. Buat proyek Firebase dan aktifkan Cloud Messaging.
//   2. Function ini memakai FCM HTTP v1 API, yang membutuhkan token
//      akses OAuth 2.0 berumur pendek, BUKAN kunci server lama.
//      Token akses diperoleh dari akun layanan (service account)
//      Firebase dengan cakupan:
//        https://www.googleapis.com/auth/firebase.messaging
//      Cara resmi memperolehnya tercantum di dokumentasi Firebase
//      Cloud Messaging. Token harus diperbarui secara berkala.
//   3. Untuk pemakaian produksi, ganti token manual di atas dengan
//      penukaran token otomatis dari akun layanan (misalnya memakai
//      pustaka auth Google di dalam function), agar token selalu baru.
//   4. Bila secret FCM belum diatur, function mengembalikan galat 500
//      dengan pesan setup, dan tidak mengirim apa pun.
//   5. Jangan pernah menulis kunci akun layanan atau token asli di
//      file ini atau di repositori.
//
// Deploy:
//   supabase functions deploy fcm-notify

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(
  body: Record<string, unknown>,
  status: number,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

/// Baca klaim `sub` (id pengguna) dari payload JWT.
///
/// Hanya mendekode, tidak memverifikasi tanda tangan: gateway
/// Supabase sudah memverifikasi JWT sebelum request diteruskan ke
/// function (lihat `verify_jwt = true` di config.toml). Mengembalikan
/// null bila header tidak ada, bukan Bearer, atau payload bukan JSON
/// dengan `sub` berupa string.
function idPenggunaDariJwt(req: Request): string | null {
  const header = req.headers.get("authorization");
  if (!header || !header.toLowerCase().startsWith("bearer ")) {
    return null;
  }
  const token = header.slice("bearer ".length).trim();
  const bagian = token.split(".");
  if (bagian.length !== 3) return null;
  try {
    const payload = bagian[1]
      .replace(/-/g, "+")
      .replace(/_/g, "/");
    const json = atob(payload);
    const data = JSON.parse(json) as { sub?: unknown };
    return typeof data.sub === "string" && data.sub.length > 0
      ? data.sub
      : null;
  } catch {
    return null;
  }
}

/// Daftar id pengguna yang diizinkan, dari secret server.
/// Secret kosong atau tidak diatur berarti function nonaktif.
function bacaAllowlist(): string[] {
  const nilai = Deno.env.get("FCM_NOTIFY_ALLOWED_USER_IDS") ?? "";
  return nilai
    .split(",")
    .map((id) => id.trim())
    .filter((id) => id.length > 0);
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { error: "Metode tidak diizinkan. Gunakan POST." },
      405,
    );
  }

  // Gerbang 1: function nonaktif bila admin belum mengatur allowlist.
  const allowlist = bacaAllowlist();
  if (allowlist.length === 0) {
    return jsonResponse(
      {
        error:
          "Pengiriman push nonaktif. Admin belum mengatur allowlist " +
          "pengguna yang diizinkan (secret " +
          "FCM_NOTIFY_ALLOWED_USER_IDS). Lihat catatan keamanan di " +
          "awal file functions/fcm-notify/index.ts.",
      },
      503,
    );
  }

  // Gerbang 2: hanya pengguna yang id-nya ada di allowlist.
  const userId = idPenggunaDariJwt(req);
  if (userId === null) {
    return jsonResponse(
      { error: "Token pengguna tidak valid atau tidak ada." },
      401,
    );
  }
  if (!allowlist.includes(userId)) {
    return jsonResponse(
      { error: "Pengguna ini tidak diizinkan mengirim notifikasi push." },
      403,
    );
  }

  const projectId = Deno.env.get("FCM_PROJECT_ID");
  const accessToken = Deno.env.get("FCM_ACCESS_TOKEN");
  if (!projectId || !accessToken) {
    return jsonResponse(
      {
        error:
          "FCM belum dikonfigurasi. Atur secret FCM_PROJECT_ID dan FCM_ACCESS_TOKEN di proyek Supabase. Lihat catatan setup di awal file ini.",
      },
      500,
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(
      { error: "Body permintaan bukan JSON yang valid." },
      400,
    );
  }

  const token = typeof body.token === "string" ? body.token.trim() : "";
  const title = typeof body.title === "string" ? body.title.trim() : "";
  const messageBody = typeof body.body === "string" ? body.body.trim() : "";
  if (!token || !title || !messageBody) {
    return jsonResponse(
      {
        error:
          "Kolom 'token', 'title', dan 'body' wajib diisi.",
      },
      400,
    );
  }

  const data: Record<string, string> = {};
  if (body.data !== null && typeof body.data === "object") {
    for (const [key, value] of Object.entries(
      body.data as Record<string, unknown>,
    )) {
      if (typeof value === "string") data[key] = value;
    }
  }

  let fcmResponse: Response;
  try {
    fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body: messageBody },
            data,
          },
        }),
      },
    );
  } catch {
    return jsonResponse(
      { error: "Tidak dapat menghubungi layanan FCM. Coba lagi nanti." },
      502,
    );
  }

  if (!fcmResponse.ok) {
    return jsonResponse(
      {
        error:
          `Layanan FCM mengembalikan status ${fcmResponse.status}. Periksa token akses dan id proyek Firebase.`,
      },
      502,
    );
  }

  const dataJson = await fcmResponse.json() as { name?: string };
  return jsonResponse(
    { sukses: true, nama_pesan: dataJson.name ?? null },
    200,
  );
});
