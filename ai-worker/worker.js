// Koffee AI proxy. Holds the OpenRouter key so no key ships inside dist/koffee.lua,
// and keeps one shared daily budget across everyone who uses it.
//
// Deploy:
//   wrangler deploy
//   wrangler secret put OPENROUTER_KEY
//   wrangler secret put KOFFEE_TOKEN      (optional: gate who may use it)
//   wrangler kv namespace create KOFFEE_AI (optional: per-day counting)
//
// Then paste the deployed URL into Koffee's AI tab > gear > proxy url.

const UPSTREAM = "https://openrouter.ai/api/v1";
const DAY_CAP = 1000;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Koffee-Token",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS },
  });
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

// Only the fields Koffee's picker actually reads, so the client decodes 2KB instead of
// the ~770KB full catalog.
async function models(env) {
  const r = await fetch(UPSTREAM + "/models", {
    headers: { Authorization: `Bearer ${env.OPENROUTER_KEY}` },
  });
  if (!r.ok) return json({ error: `upstream ${r.status}` }, 502);
  const all = await r.json();
  const free = (all.data || []).filter((m) => typeof m.id === "string" && m.id.endsWith(":free"));
  return json({
    data: free.map((m) => ({
      id: m.id,
      name: m.name,
      context_length: m.context_length,
      supported_parameters: m.supported_parameters || [],
    })),
  });
}

async function spend(env) {
  if (!env.KOFFEE_AI) return { ok: true, left: -1 };
  const key = `used:${today()}`;
  const used = parseInt((await env.KOFFEE_AI.get(key)) || "0", 10);
  if (used >= DAY_CAP) return { ok: false, left: 0 };
  // 36h ttl so the key falls off on its own after the day rolls over
  await env.KOFFEE_AI.put(key, String(used + 1), { expirationTtl: 129600 });
  return { ok: true, left: DAY_CAP - used - 1 };
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return new Response(null, { headers: CORS });
    if (!env.OPENROUTER_KEY) return json({ error: "worker has no OPENROUTER_KEY set" }, 500);

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    // Optional shared token. Set KOFFEE_TOKEN to stop strangers spending the budget.
    if (env.KOFFEE_TOKEN) {
      const sent =
        request.headers.get("X-Koffee-Token") ||
        (request.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
      if (sent !== env.KOFFEE_TOKEN) return json({ error: "bad token" }, 403);
    }

    if (path === "/health") return json({ ok: true });
    if (path === "/models") return models(env);

    if (path === "/chat/completions" && request.method === "POST") {
      const budget = await spend(env);
      if (!budget.ok) return json({ error: "shared daily budget spent" }, 429);

      let body;
      try {
        body = await request.json();
      } catch {
        return json({ error: "body was not json" }, 400);
      }
      // free models only: a paid id here would bill real credits
      if (typeof body.model !== "string" || !body.model.endsWith(":free")) {
        return json({ error: "this proxy only forwards :free models" }, 400);
      }

      const r = await fetch(UPSTREAM + "/chat/completions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${env.OPENROUTER_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://koffee.local",
          "X-Title": "Koffee",
        },
        body: JSON.stringify(body),
      });
      const text = await r.text();
      return new Response(text, {
        status: r.status,
        headers: {
          "Content-Type": "application/json",
          "X-Koffee-Day-Left": String(budget.left),
          ...CORS,
        },
      });
    }

    return json({ error: "not found" }, 404);
  },
};
