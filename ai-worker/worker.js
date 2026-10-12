// Koffee AI proxy. Holds the OpenRouter key so no key ever ships inside dist/koffee.lua
// or inside a shared config, and caps what the account can possibly spend.
//
// Deploy:
//   wrangler kv namespace create KOFFEE_AI     (paste the id into wrangler.toml)
//   wrangler deploy
//   wrangler secret put OPENROUTER_KEY
//   wrangler secret put KOFFEE_TOKEN           (optional: gate who may use it)
//
// Then paste the deployed URL into Koffee: AI tab > gear > Worker URL.

const UPSTREAM = "https://openrouter.ai/api/v1";

// Three independent ceilings. Free models bill $0, so the spend ceiling should never be
// reached: it exists so a mistake cannot become a bill.
const DAY_CAP = 1000;        // requests per day across everyone on this worker
const MAX_SPEND_USD = 0.001; // hard lifetime-per-day cost ceiling
const MAX_TOKENS = 4000;     // clamp, so one request cannot run away. A config with a
                             // dozen changes truncates below about 3000 and the JSON
                             // arrives unparseable, so this has headroom over the client.

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Koffee-Token",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const json = (body, status = 200, extra = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS, ...extra },
  });

const today = () => new Date().toISOString().slice(0, 10);

async function counters(env) {
  if (!env.KOFFEE_AI) return { used: 0, spend: 0, tracked: false };
  const day = today();
  const [u, c] = await Promise.all([
    env.KOFFEE_AI.get(`used:${day}`),
    env.KOFFEE_AI.get(`spend:${day}`),
  ]);
  return { used: parseInt(u || "0", 10), spend: parseFloat(c || "0"), tracked: true };
}

// 36h ttl so each day's keys fall off on their own
const put = (env, k, v) => env.KOFFEE_AI.put(k, String(v), { expirationTtl: 129600 });

// Only the fields Koffee's picker reads, so the client decodes ~2KB instead of the
// ~770KB full catalog. Free models only; the client never sees a paid id.
async function models(env) {
  const r = await fetch(`${UPSTREAM}/models`, {
    headers: { Authorization: `Bearer ${env.OPENROUTER_KEY}` },
  });
  if (!r.ok) return json({ error: `upstream ${r.status}` }, 502);
  const all = await r.json();
  const free = (all.data || []).filter(
    (m) => typeof m.id === "string" && m.id.endsWith(":free")
  );
  return json({
    data: free.map((m) => ({
      id: m.id,
      name: m.name,
      context_length: m.context_length,
      supported_parameters: m.supported_parameters || [],
    })),
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return new Response(null, { headers: CORS });
    if (!env.OPENROUTER_KEY) return json({ error: "worker has no OPENROUTER_KEY set" }, 500);

    const path = new URL(request.url).pathname.replace(/\/+$/, "") || "/";

    // Optional shared token, so strangers cannot spend the budget.
    if (env.KOFFEE_TOKEN) {
      const sent =
        request.headers.get("X-Koffee-Token") ||
        (request.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
      if (sent !== env.KOFFEE_TOKEN) return json({ error: "bad or missing token" }, 403);
    }

    if (path === "/health") return json({ ok: true });
    if (path === "/models") return models(env);

    if (path === "/chat/completions" && request.method === "POST") {
      const { used, spend, tracked } = await counters(env);
      if (tracked && used >= DAY_CAP) return json({ error: "shared daily request cap reached" }, 429);
      if (tracked && spend >= MAX_SPEND_USD) {
        return json({ error: "spend ceiling reached, nothing further will be sent" }, 429);
      }

      let body;
      try {
        body = await request.json();
      } catch {
        return json({ error: "body was not json" }, 400);
      }

      // The ceiling that actually matters: a paid id here would bill real credits.
      if (typeof body.model !== "string" || !body.model.endsWith(":free")) {
        return json({ error: "this worker only forwards :free models" }, 400);
      }
      body.max_tokens = Math.min(body.max_tokens || MAX_TOKENS, MAX_TOKENS);
      // ask OpenRouter to report cost back so the ceiling is measured, not assumed
      body.usage = { include: true };

      const r = await fetch(`${UPSTREAM}/chat/completions`, {
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

      let cost = 0;
      try {
        cost = Number(JSON.parse(text)?.usage?.cost) || 0;
      } catch {
        cost = 0;
      }
      if (tracked) {
        await Promise.all([
          put(env, `used:${today()}`, used + 1),
          put(env, `spend:${today()}`, (spend + cost).toFixed(8)),
        ]);
      }

      return new Response(text, {
        status: r.status,
        headers: {
          "Content-Type": "application/json",
          "X-Koffee-Day-Left": String(tracked ? DAY_CAP - used - 1 : -1),
          "X-Koffee-Spend": String(tracked ? (spend + cost).toFixed(8) : -1),
          ...CORS,
        },
      });
    }

    return json({ error: "not found" }, 404);
  },
};
