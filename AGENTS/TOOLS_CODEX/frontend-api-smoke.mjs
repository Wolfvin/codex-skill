#!/usr/bin/env node
/* eslint-disable no-console */

const BASE_URL = process.env.SMOKE_BASE_URL || process.argv[2] || "http://127.0.0.1:3000";
const CLEANUP = process.env.SMOKE_CLEANUP !== "0";
const TIMEOUT_MS = Number(process.env.SMOKE_TIMEOUT_MS || 10000);
const NETWORK_RETRIES = Number(process.env.SMOKE_NETWORK_RETRIES || 5);

const runId = `smoke_${Date.now()}`;
const marker = `[${runId}]`;

function fail(message) {
  throw new Error(message);
}

async function http(path, options = {}) {
  const url = `${BASE_URL}${path}`;
  const headers = { "Content-Type": "application/json", ...(options.headers || {}) };
  let lastErr = null;

  for (let attempt = 0; attempt < NETWORK_RETRIES; attempt += 1) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    try {
      const resp = await fetch(url, { ...options, headers, signal: controller.signal });
      let body = null;
      const text = await resp.text();
      if (text) {
        try {
          body = JSON.parse(text);
        } catch {
          body = text;
        }
      }
      return { ok: resp.ok, status: resp.status, body };
    } catch (err) {
      lastErr = err;
      if (attempt + 1 >= NETWORK_RETRIES) {
        break;
      }
      await new Promise((r) => setTimeout(r, 800));
    } finally {
      clearTimeout(timer);
    }
  }

  throw lastErr || new Error(`request failed: ${path}`);
}

function assertStatus(res, expected, label) {
  if (Array.isArray(expected)) {
    if (!expected.includes(res.status)) {
      fail(`${label} expected status ${expected.join("/")} but got ${res.status}`);
    }
    return;
  }
  if (res.status !== expected) {
    fail(`${label} expected status ${expected} but got ${res.status}`);
  }
}

function findAnnouncement(items, titleNeedle) {
  return (items || []).find((x) => String(x?.title || "").includes(titleNeedle));
}

function findAnggota(items, nomorAnggota) {
  return (items || []).find((x) => String(x?.nomor_anggota || "") === nomorAnggota);
}

function extractList(body) {
  if (Array.isArray(body)) return body;
  if (body && typeof body === "object") {
    const direct = body.items ?? body.data ?? body.rows ?? body.value ?? body.results ?? body.devices ?? [];
    if (Array.isArray(direct)) return direct;
  }
  return [];
}

async function main() {
  console.log(`\n[SMOKE] Base URL: ${BASE_URL}`);
  console.log(`[SMOKE] Run ID  : ${runId}\n`);

  const created = {
    announcementId: null,
    anggotaId: null,
  };

  try {
    console.log("1) Health check...");
    const health = await http("/", { method: "GET", headers: {} });
    assertStatus(health, 200, "GET /");

    console.log("2) GET stats...");
    const stats = await http("/api/stats", { method: "GET" });
    assertStatus(stats, 200, "GET /api/stats");

    console.log("3) GET announcements (baseline)...");
    const beforeAnnouncements = await http("/api/announcements", { method: "GET" });
    assertStatus(beforeAnnouncements, 200, "GET /api/announcements");
    if (!Array.isArray(beforeAnnouncements.body)) {
      fail("GET /api/announcements should return array");
    }

    console.log("4) POST announcement...");
    const annPayload = {
      title: `Smoke Announcement ${marker}`,
      body: `Body ${marker}`,
      category: "umum",
      is_pinned: false,
      author: "smoke-test",
    };
    const annPost = await http("/api/announcements", {
      method: "POST",
      body: JSON.stringify(annPayload),
    });
    assertStatus(annPost, 201, "POST /api/announcements");

    console.log("5) GET announcements (verify created)...");
    const afterAnnouncements = await http("/api/announcements", { method: "GET" });
    assertStatus(afterAnnouncements, 200, "GET /api/announcements after create");
    const annFound = findAnnouncement(afterAnnouncements.body, marker);
    if (!annFound) {
      fail("Announcement created but not found in GET /api/announcements");
    }
    created.announcementId = annFound.id;

    console.log("6) POST anggota...");
    const nomorAnggota = `SMOKE-${Date.now()}`;
    const angPayload = {
      nama: `User ${marker}`,
      nomor_anggota: nomorAnggota,
      role: "anggota",
      brevet: "a",
      quotes: `Quote ${marker}`,
      warna_card: "linear-gradient(135deg,#0d4a2f,#2d8a55)",
      joined_at: "2026-04-03",
    };
    const angPost = await http("/api/anggota", {
      method: "POST",
      body: JSON.stringify(angPayload),
    });
    assertStatus(angPost, 201, "POST /api/anggota");

    console.log("7) GET anggota (verify created)...");
    const angList = await http("/api/anggota", { method: "GET" });
    assertStatus(angList, 200, "GET /api/anggota");
    const angFound = findAnggota(extractList(angList.body), nomorAnggota);
    if (!angFound) {
      fail("Anggota created but not found in GET /api/anggota");
    }
    created.anggotaId = angFound.id;

    console.log("8) POST document log...");
    const docPost = await http("/api/documents", {
      method: "POST",
      body: JSON.stringify({
        device_id: "smoke-device",
        doc_type: "efaktur",
        count: 1,
        nama_dokumen: `doc-${runId}.pdf`,
        klien: "Smoke Client",
        status: "selesai",
      }),
    });
    assertStatus(docPost, 201, "POST /api/documents");

    console.log("9) POST files count...");
    const filesPost = await http("/api/files/count", {
      method: "POST",
      body: JSON.stringify({
        hardware_id: "smoke-device",
        jenis_file: "efaktur",
        jumlah_file: 1,
        tanggal: "2026-04-03",
      }),
    });
    assertStatus(filesPost, 201, "POST /api/files/count");

    console.log("\n[SMOKE] SUCCESS: endpoint GET/POST frontend-facing berjalan.");
    console.log(`[SMOKE] Created announcement id: ${created.announcementId || "-"}`);
    console.log(`[SMOKE] Created anggota id     : ${created.anggotaId || "-"}`);
  } finally {
    if (CLEANUP) {
      console.log("\n[SMOKE] Cleanup...");
      if (created.announcementId) {
        try {
          const delAnn = await http(`/api/announcements/${created.announcementId}`, { method: "DELETE" });
          if (![200, 404].includes(delAnn.status)) {
            console.warn(`[WARN] DELETE /api/announcements/${created.announcementId} -> ${delAnn.status}`);
          }
        } catch (err) {
          console.warn(`[WARN] Cleanup announcement gagal: ${err.message}`);
        }
      }
      if (created.anggotaId) {
        try {
          const delAng = await http(`/api/anggota/${created.anggotaId}`, { method: "DELETE" });
          if (![200, 404].includes(delAng.status)) {
            console.warn(`[WARN] DELETE /api/anggota/${created.anggotaId} -> ${delAng.status}`);
          }
        } catch (err) {
          console.warn(`[WARN] Cleanup anggota gagal: ${err.message}`);
        }
      }
    } else {
      console.log("\n[SMOKE] Cleanup dilewati (SMOKE_CLEANUP=0).");
    }
  }
}

main().catch((err) => {
  console.error(`\n[SMOKE] FAILED: ${err.message}`);
  process.exit(1);
});
