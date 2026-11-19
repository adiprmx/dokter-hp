// functions/ai-diagnose/index.ts
//
// Edge Function: diagnosis masalah HP dengan bantuan Gemini.
//
// Cara pakai:
//   POST /functions/v1/ai-diagnose
//   Header: Authorization: Bearer <token pengguna>
//   Body JSON:
//     {
//       "gejala": "WiFi sering putus dan baterai cepat habis",
//       "hasil_pemeriksaan": { "skor": 62, "baterai": "kesehatan 78%" }
//     }
//
//   Respons sukses (200):
//     { "diagnosis": "...jawaban berbahasa Indonesia..." }
//
// Catatan penting:
//   - Hanya JWT PENGGUNA LOGIN (role 'authenticated') yang diterima —
//     anon key sebagai Bearer DITOLAK 401 di dalam function, karena
//     gateway verify_jwt saja tidak membedakan anon dari pengguna.
//   - Kunci API dibaca dari secret lingkungan GEMINI_API_KEY
//     (Deno.env.get). Jangan pernah menulis kunci asli di file ini.
//   - Endpoint Gemini di bawah memakai model gemini-3.5-flash-lite
//     (utama) dengan cadangan gemini-3.1-flash-lite, melalui pola
//     fetch POST ke generativelanguage.googleapis.com dengan header
//     x-goog-api-key. Endpoint dan nama model ini WAJIB diverifikasi
//     pada dokumentasi resmi Google AI saat setup, karena Google dapat
//     mengubah nama model dan versi API. Bila model tidak tersedia,
//     ganti nama model pada konstanta GEMINI_MODELS dengan model
//     yang tercantum di dokumentasi resmi saat itu.
//   - Riwayat model (19 Nov 2026): gemini-2.0-flash SUDAH PENSIUN —
//     API live mengembalikan 404 "no longer available" dan menyarankan
//     gemini-3.8-flash; dokumentasi resmi (aistudio.google.com/docs/models)
//     mencantumkan Gemini 3.8 Flash sebagai Stable; tes generateContent
//     langsung dengan kunci proyek ini mengembalikan 200. Endpoint v1beta
//     tetap berlaku (semua tes live memakai v1beta).
//   - Riwayat model (20 Nov 2026): gemini-3.8-flash TERBUKTI OVERLOAD —
//     503 "high demand" + panggilan menggantung sampai batas worker 546;
//     model diganti ke gemini-3.5-flash-lite (utama, Stable) dengan
//     cadangan gemini-3.1-flash-lite (Stable); keduanya terverifikasi
//     live dengan payload persis function ini (HTTP 200 + diagnosis
//     nyata berbahasa Indonesia). Fetch kini memakai timeout 60 dtk
//     (AbortController) + maksimal 1 retry untuk 5xx.
//   - Function ini mengembalikan jawaban teks sederhana berbahasa
//     Indonesia. Jawaban AI bersifat saran umum, bukan pengganti
//     pemeriksaan teknisi.
//
// Jalankan lokal:
//   supabase functions serve ai-diagnose --env-file ./supabase/.env.local
// Deploy:
//   supabase functions deploy ai-diagnose
// Atur secret:
//   supabase secrets set GEMINI_API_KEY=<kunci>

const GEMINI_MODELS = [
  // Utama: Gemini 3.5 Flash-Lite (Stable, rekomendasi Google untuk
  // proyek baru; terverifikasi live 20 Nov 2026 dengan payload persis
  // function ini: HTTP 200 + diagnosis 1542 karakter).
  "gemini-3.5-flash-lite",
  // Cadangan: Gemini 3.1 Flash-Lite (Stable; terverifikasi live
  // 20 Nov 2026 dengan payload persis: HTTP 200 + diagnosis
  // 2225 karakter dalam 18 dtk).
  "gemini-3.1-flash-lite",
] as const;

const GEMINI_API_BASE =
  "https://generativelanguage.googleapis.com/v1beta/models";

// Batas waktu per panggilan ke Gemini. Tanpa timeout eksplisit, fetch
// yang menggantung menabrak batas resource worker Supabase (546
// WORKER_RESOURCE_LIMIT setelah ~140 dtk — terbukti live 20 Nov 2026).
const GEMINI_TIMEOUT_MS = 60_000;
// Jeda sebelum satu-satunya retry (hanya untuk respons 5xx Gemini).
const RETRY_BACKOFF_MS = 2_000;

function geminiEndpoint(model: string): string {
  return `${GEMINI_API_BASE}/${model}:generateContent`;
}

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

// Decode payload JWT dari header Authorization (tanpa verifikasi
// tanda tangan — tanda tangan SUDAH diverifikasi gateway Supabase
// (verify_jwt) sebelum request sampai ke function ini; di sini hanya
// dibaca role/sub-nya). Mengembalikan null bila header/token tidak
// berbentuk JWT yang valid.
function getJwtPayload(req: Request): Record<string, unknown> | null {
  const auth = req.headers.get("authorization");
  if (!auth || !auth.toLowerCase().startsWith("bearer ")) return null;
  const token = auth.slice(7).trim();
  const parts = token.split(".");
  if (parts.length !== 3 || !parts[1]) return null;
  try {
    const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const bin = atob(base64);
    const bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
    const payloadJson = new TextDecoder().decode(bytes);
    return JSON.parse(payloadJson) as Record<string, unknown>;
  } catch {
    return null;
  }
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

  // Cek pengguna terautentikasi (20 Nov 2026): gateway Supabase
  // (verify_jwt) menerima SEMUA JWT bertanda tangan proyek — termasuk
  // anon key — sehingga anon key sebagai Bearer lolos sampai ke function
  // ini (terbukti: function menjawab 400, bukan 401). Hanya JWT pengguna
  // login (role 'authenticated' + sub terisi) yang boleh memakai
  // diagnosis AI; anon/service_role ditolak 401 di sini.
  const payload = getJwtPayload(req);
  const role = typeof payload?.role === "string" ? payload.role : "";
  const sub = typeof payload?.sub === "string" ? payload.sub : "";
  if (role !== "authenticated" || !sub) {
    return jsonResponse(
      {
        error:
          "Diperlukan login pengguna. Masuk dulu sebelum memakai diagnosis AI.",
      },
      401,
    );
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return jsonResponse(
      {
        error:
          "GEMINI_API_KEY belum diatur. Atur secret di proyek Supabase sebelum memakai function ini.",
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

  const gejala = typeof body.gejala === "string" ? body.gejala.trim() : "";
  if (!gejala) {
    return jsonResponse(
      { error: "Kolom 'gejala' wajib diisi dengan teks keluhan." },
      400,
    );
  }

  const hasilPemeriksaan = body.hasil_pemeriksaan ?? null;
  const hasilTeks = hasilPemeriksaan === null
    ? "Tidak ada hasil pemeriksaan terlampir."
    : JSON.stringify(hasilPemeriksaan);

  const prompt =
    "Anda adalah asisten diagnosis HP berbahasa Indonesia. " +
    "Berikan analisis singkat dan langkah perbaikan yang praktis, " +
    "dengan bahasa sehari-hari yang mudah dipahami. " +
    "Tutup dengan catatan bila masalah berlanjut, sebaiknya periksa ke teknisi.\n\n" +
    `Gejala yang dilaporkan pengguna:\n${gejala}\n\n` +
    `Hasil pemeriksaan aplikasi:\n${hasilTeks}`;

  const geminiBody = JSON.stringify({
    contents: [{ parts: [{ text: prompt }] }],
  });

  // Panggil Gemini dengan timeout eksplisit + MAKSIMAL 1 retry.
  // Percobaan 1: model utama. Bila Gemini mengembalikan 5xx (mis.
  // 503 "high demand" — terbukti live 20 Nov 2026 pada model Flash),
  // 1 retry ke model cadangan setelah backoff singkat. Bila fetch
  // menggantung sampai timeout / gagal jaringan, GAGAL CEPAT tanpa
  // retry — retry di situ hanya menumpuk waktu menuju batas 546.
  let geminiResponse: Response | null = null;
  let lastStatus = 0;
  let timedOut = false;
  for (let attempt = 0; attempt < GEMINI_MODELS.length; attempt++) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);
    try {
      geminiResponse = await fetch(geminiEndpoint(GEMINI_MODELS[attempt]), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: geminiBody,
        signal: controller.signal,
      });
    } catch (err) {
      timedOut = err instanceof Error && err.name === "AbortError";
      geminiResponse = null;
      break;
    } finally {
      clearTimeout(timer);
    }
    if (geminiResponse.ok) break;
    lastStatus = geminiResponse.status;
    // Hanya 5xx yang boleh retry (sekali, ke model cadangan).
    // Status lain (4xx = kunci/model/payload salah) langsung gagal.
    if (geminiResponse.status < 500 || attempt + 1 >= GEMINI_MODELS.length) {
      break;
    }
    await new Promise((resolve) => setTimeout(resolve, RETRY_BACKOFF_MS));
  }

  if (!geminiResponse) {
    return jsonResponse(
      {
        error: timedOut
          ? "Layanan Gemini tidak merespons tepat waktu. Coba lagi nanti."
          : "Tidak dapat menghubungi layanan Gemini. Coba lagi nanti.",
      },
      502,
    );
  }

  if (!geminiResponse.ok) {
    return jsonResponse(
      {
        error:
          `Layanan Gemini mengembalikan status ${lastStatus}. Periksa kunci API dan nama model pada dokumentasi resmi Google AI.`,
      },
      502,
    );
  }

  let data: {
    candidates?: Array<{
      content?: { parts?: Array<{ text?: string }> };
    }>;
  };
  try {
    data = await geminiResponse.json() as typeof data;
  } catch {
    return jsonResponse(
      { error: "Layanan Gemini mengembalikan respons yang tidak valid." },
      502,
    );
  }
  const diagnosis =
    data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";

  if (!diagnosis) {
    return jsonResponse(
      { error: "Layanan Gemini tidak mengembalikan jawaban." },
      502,
    );
  }

  return jsonResponse({ diagnosis }, 200);
});
