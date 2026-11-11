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
//   - Kunci API dibaca dari secret lingkungan GEMINI_API_KEY
//     (Deno.env.get). Jangan pernah menulis kunci asli di file ini.
//   - Endpoint Gemini di bawah memakai model gemini-2.0-flash melalui
//     pola fetch POST ke generativelanguage.googleapis.com dengan header
//     x-goog-api-key. Endpoint dan nama model ini WAJIB diverifikasi
//     pada dokumentasi resmi Google AI saat setup, karena Google dapat
//     mengubah nama model dan versi API. Bila model tidak tersedia,
//     ganti nama model pada konstanta GEMINI_ENDPOINT dengan model
//     yang tercantum di dokumentasi resmi saat itu.
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

const GEMINI_ENDPOINT =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

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

  let geminiResponse: Response;
  try {
    geminiResponse = await fetch(GEMINI_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
      }),
    });
  } catch {
    return jsonResponse(
      { error: "Tidak dapat menghubungi layanan Gemini. Coba lagi nanti." },
      502,
    );
  }

  if (!geminiResponse.ok) {
    return jsonResponse(
      {
        error:
          `Layanan Gemini mengembalikan status ${geminiResponse.status}. Periksa kunci API dan nama model pada dokumentasi resmi Google AI.`,
      },
      502,
    );
  }

  const data = await geminiResponse.json() as {
    candidates?: Array<{
      content?: { parts?: Array<{ text?: string }> };
    }>;
  };
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
