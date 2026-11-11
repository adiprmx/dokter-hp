// functions/fcm-notify/index.ts
//
// Edge Function (template): kirim notifikasi push lewat Firebase
// Cloud Messaging (FCM) HTTP v1 API.
//
// Cara pakai:
//   POST /functions/v1/fcm-notify
//   Header: Authorization: Bearer <token pengguna>
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
// Catatan setup (baca sebelum memakai):
//   1. Buat proyek Firebase dan aktifkan Cloud Messaging.
//   2. Function ini memakai FCM HTTP v1 API, yang membutuhkan token
//      akses OAuth 2.0 berumur pendek, BUKAN kunci server lama.
//      Token akses diperoleh dari akun layanan (service account)
//      Firebase dengan cakupan:
//        https://www.googleapis.com/auth/firebase.messaging
//      Cara resmi memperolehnya tercantum di dokumentasi Firebase
//      Cloud Messaging. Token harus diperbarui secara berkala.
//   3. Atur dua secret di proyek Supabase sebelum deploy:
//        supabase secrets set FCM_PROJECT_ID=<id proyek Firebase>
//        supabase secrets set FCM_ACCESS_TOKEN=<token akses OAuth 2.0>
//   4. Untuk pemakaian produksi, ganti langkah manual di atas dengan
//      penukaran token otomatis dari akun layanan (misalnya memakai
//      pustaka auth Google di dalam function), agar token selalu baru.
//   5. Bila secret belum diatur, function mengembalikan galat 500
//      dengan pesan setup, dan tidak mengirim apa pun.
//   6. Jangan pernah menulis kunci akun layanan atau token asli di
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
