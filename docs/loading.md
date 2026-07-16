# loading koffee (private-repo dev flow)

koffee lives in a private repo so `game:HttpGet` won't work -- it can't send an `Authorization` header. use the runtime's `request` function with a github personal access token (PAT) instead.

## one-time PAT setup

1. go to https://github.com/settings/personal-access-tokens/new (fine-grained PAT, not classic).
2. **token name:** `koffee-dev` (or whatever).
3. **resource owner:** `lowkeymyself`.
4. **expiration:** 90 days (or custom -- longer = less annoying, shorter = safer).
5. **repository access:** *Only select repositories* -> `KDevelopment`.
6. **permissions -> Repository permissions -> Contents:** `Read-only`.
7. click **Generate token**, copy it (`github_pat_...` or `ghp_...`). you won't see it again.

## loader snippet

paste this into your runtime's editor and save it as `koffee` (or whatever name). replace the token placeholder with the one you just generated.

```lua
local TOKEN = "PASTE_TOKEN_HERE"

local ok, res = pcall(request, {
    Url = "https://raw.githubusercontent.com/lowkeymyself/KDevelopment/main/dist/koffee.lua",
    Method = "GET",
    Headers = { Authorization = "token " .. TOKEN },
})

if not ok then
    warn("[koffee] request threw: " .. tostring(res))
    return
end
if res.StatusCode ~= 200 then
    warn("[koffee] fetch failed: HTTP " .. tostring(res.StatusCode) .. " -- " .. tostring(res.Body))
    return
end

local fn, err = loadstring(res.Body, "=koffee")
if not fn then
    warn("[koffee] parse failed: " .. tostring(err))
    return
end

fn()
```

## iteration loop

1. edit `dist/koffee.lua` locally.
2. `git commit && git push`.
3. re-run the saved loader in the runtime -- fetches the latest `main` and executes.

no cache-busting needed; `raw.githubusercontent.com` respects new commits within ~30s. if you push and don't see the change, wait a few seconds and re-run.

## PAT hygiene

- **never commit the token to the repo.** the loader lives in the runtime's local script storage only.
- if the token leaks, revoke it at https://github.com/settings/personal-access-tokens -- new one, done.
- fine-grained PAT scoped to `KDevelopment` + `Contents: Read-only` means a leaked token can only *read* this one repo, nothing else. worst-case damage is bounded.

## why not `game:HttpGet`

`game:HttpGet` doesn't take custom headers. github's private-repo raw endpoint requires `Authorization`. dead end.

## once koffee ships trusted-only

when we're ready to distribute (still just to trusted people, not public), we swap to one of:

- **flip the repo public**, use the plain `game:HttpGet` one-liner. simplest.
- **keep it private**, ship each trusted user their own PAT-scoped-to-KDevelopment (annoying to manage).
- **build a tiny auth proxy** (cloudflare worker) that holds the PAT server-side and serves the script to whitelisted keys. cleanest for real distribution.

decide when we get there.
