# Monorepo Refactor Plan

**Repo:** Svelte + Elixir + Ash monorepo template (not deployed, no production data).
**End state:** An Elixir REST API backend with username/password auth and password-reset codes (no emails), a Svelte frontend consuming the REST API (no Inertia, **no ash_typescript RPC layer** — plain hand-written REST/JSON endpoints only), clean domain-based file structure, functional tests only.

## How to use this with a coding agent

Work **one phase at a time**. Do not start a phase until the previous one ends in a compiling, working state. After each phase, report what changed and stop for review before continuing. If a step is ambiguous, propose options rather than guessing. Never delete something you cannot confirm is unused — propose it for approval instead.

## Decisions already made (do not re-litigate)

- **Reset codes:** generated, returned to the user in the API response, AND stored in the database hashed with Argon2 so they can be validated on use. The plaintext code is shown once (in the response); only the Argon2 hash is persisted. Codes expire and are single-use.
- **Package updates:** aggressive — update to the latest version of everything, frontend and backend.
- **File structure:** the agent proposes a domain-based structure (see Phase 3) for approval before applying it.
- **No RPC layer:** remove `ash_typescript` and its generated client (`ash_rpc.ts`), the `/rpc/*` routes, the `RpcController`, the `typescript_rpc` DSL, and the `AshTypescript.*` extensions. The frontend talks to hand-written REST/JSON endpoints, not a generated RPC client. The user data operations currently exposed via RPC (`get_user`, `change_username`, `generate_recovery_codes`, `convert_to_registered`, `current_user`) must be re-expressed as plain REST endpoints (see Phase 5).
- **No emails, no Inertia, no RPC — plain REST only.**

---

## Phase 0 — Audit (CHANGE NOTHING)

**Objective:** Produce a complete picture of the repo before touching anything. This phase outputs a report only.

1. Inventory the whole repo structure and describe what each top-level directory and significant file does.
2. List every backend dependency (mix.exs) with current version vs latest available, flagging every major-version jump.
3. List every frontend dependency (package.json) with current version vs latest available, flagging every major-version jump.
4. Identify apparently-unused packages, frontend and backend, with explicit reasoning for each. Be conservative — flag anything that might be referenced dynamically (Ash extensions, build tooling, test helpers) as "uncertain" rather than "unused."
5. Identify Inertia-related code and dependencies and everything that exists only to serve the non-REST rendering path.
6. Identify existing tests and categorize them: which test real user-facing behavior vs which are low-value (testing framework internals, trivial getters, over-mocked unit tests).
7. Note anything that looks like dead code, duplicated logic, or leftover scaffolding.

**Output:** a written report covering all of the above. **Make zero code changes.**

**Stop and review before Phase 1.**

---

## Phase 1 — Remove Inertia, the RPC Layer, and the Non-REST Path

**Objective:** Strip out Inertia, the ash_typescript RPC layer, and anything tied to server-rendered/non-REST delivery, leaving a clean plain-REST-API-plus-separate-frontend shape.

> **Audit note (Phase 0):** No Inertia *code* remains in `backend/lib`, `frontend/src`, or either manifest — only orphaned `inertia`/`nodejs` entries in `mix.lock`. The substantive work in this phase is removing the **RPC layer**.

1. Remove the orphaned Inertia entries from `mix.lock` (and confirm no Inertia code/deps remain, backend or frontend).
2. **Remove the ash_typescript RPC layer:**
   - Backend: delete `RpcController`, the `/rpc/run` and `/rpc/validate` routes, the `typescript_rpc do … end` block in `accounts.ex`, the `AshTypescript.Rpc` domain extension and `AshTypescript.Resource` resource extension (on `user.ex`), and the `config :ash_typescript` block. (The `ash_typescript` dependency itself is removed in Phase 2.)
   - Frontend: delete the generated `src/lib/generated/ash_rpc.ts` and the RPC-specific wrappers (`src/lib/api/rpc.ts` and the parts of `api/client.ts`/`api/accounts.ts` that depend on the generated client).
3. **Decision (approved):** keep the `/admin` (ash_admin) and `/dev` (live_dashboard, swoosh mailbox) routes and exactly the supporting code they need (`:browser` pipeline, `phoenix_html`/LiveView helpers, `error_html`, LiveView socket, swoosh `Mailer`). Remove server-rendered/scaffolding code that does **not** help `/admin` or `/dev` work (e.g. unused `web.ex` macros for app-level LiveViews/components/channels we don't have).
4. Leave the app in a state where the backend is a plain Phoenix REST API (auth endpoints `login`/`register`/`refresh`/`logout`/`logout_all`/`me` already exist as plain REST and stay) and the frontend is a standalone Svelte app. Frontend data features that depended on RPC (profile, recovery codes, change-username, convert) may be **temporarily stubbed**; they get wired to real REST endpoints in Phase 5.

**Verify:** backend compiles (`mix compile`), frontend builds, no references to removed Inertia **or RPC** code remain (`grep -ri "ash_typescript\|/rpc/\|RpcController\|ash_rpc"`).

**Stop and review before Phase 2.**

---

## Phase 2 — Remove Confirmed-Unused Packages

**Objective:** Delete only what was confirmed unused in the Phase 0 audit and approved during review.

**Decisions are finalized** (below) — do not re-litigate. The detailed execution prompt is in `phase-2-prompt.md`.

### Remove (backend), one logical group at a time

| Group | Packages / code to remove | Reason |
| --- | --- | --- |
| RPC | `ash_typescript` | wiring removed in Phase 1; dep now unused |
| Encryption-at-rest | `cloak`, `ash_cloak` | never wired up — no vault, no `AshCloak` extension, no encrypted attributes. (Passwords/recovery codes use Argon2 *hashing*, which is one-way and unrelated to Cloak's reversible encryption.) |
| Email | `swoosh` + `TemplateApp.Mailer` module + all `Swoosh`/`Mailer` config (`config.exs`, `dev.exs`, `test.exs`, `prod.exs`, commented block in `runtime.exs`) + the `/dev/mailbox` (`Plug.Swoosh.MailboxPreview`) route | "no emails" decision (approved) |
| Rate limiting | `ash_rate_limiter` | unused; **not** reintroduced for Phase 5 (approved) |
| Test/dev unused | `faker`, `mox` (+ the dead `ReqMock`/`:http_client` lines in `test/test_helper.exs`) | zero references; `ReqMock` is referenced but never even defined |
| Icons | `heroicons` | unused (was for server-rendered UI) |

### Change, don't remove

- ~~`stream_data`: keep it but scope to tests — change `{:stream_data, "~> 1.1"}` to `{:stream_data, "~> 1.1", only: [:test]}` (approved).~~ **Revised during execution:** scoping to `only: [:test]` breaks dependency resolution because `ash` declares `stream_data` as a non-optional, unrestricted dependency. **Resolution (approved):** dropped our explicit top-level `stream_data` declaration entirely; it now resolves transitively via `ash` and remains in `mix.lock`. Still available for tests.

### Keep — do NOT touch (serve `/admin` + `/dev`, or are core tooling)

`phoenix_html`, `phoenix_live_view`, `phoenix_live_dashboard`, `ash_admin`, backend `tailwind`, `gettext`, and all Ash/dev/build tooling (`igniter`, `sourceror`, `usage_rules`, `tidewave`, `ash_ops`, `dialyxir`, `credo`, `sobelow`, `picosat_elixir`).

### Frontend

No package removals — the Phase 0 audit found nothing unused (the RPC client was a generated *file*, already deleted in Phase 1, not an npm package). Leave `package.json`/`package-lock.json` as-is.

### Steps

1. Remove the mailer **wiring first** (module + config + `/dev/mailbox` route), then drop the `swoosh` dep — so the build never references a missing module mid-change.
2. Remove the other backend deps from `mix.exs` one group at a time, running `mix compile` between groups so any breakage is attributable.
3. Move `stream_data` to `only: [:test]`.
4. Prune the lockfile: `mix deps.unlock --unused` (and `mix deps.get`).
5. Confirm no leftovers: `grep -rin "Swoosh\|Mailer\|Cloak\|ash_rate_limiter\|Faker\|Mox\|ReqMock\|heroicons\|ash_typescript" backend/lib backend/config backend/test backend/mix.exs`.

**Verify:** `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix test` (42 tests green), frontend `npm run build` still works.

**Status: ✅ DONE.** All six backend dep groups removed, mailer wiring/config/route removed, dead Mox lines removed from `test/test_helper.exs`, lockfile pruned (`mix deps.unlock --unused`). `stream_data` handled per the revised note above. Verified: compile clean (`--warnings-as-errors`), format clean, **42 tests / 0 failures**, frontend builds. Reviewed.

**Stop and review before Phase 3.**

---

## Phase 3 — Propose and Apply Domain-Based Structure

**Objective:** Reorganize into a domain-based structure. Propose first, apply after approval. The detailed execution prompt is in `phase-3-prompt.md` (drives a propose → **hard stop for approval** → apply flow).

1. **Propose** a domain-based file structure for both backend and frontend. For the backend, group by domain (e.g. accounts/auth as one domain) with Ash resources, actions, and their domain module together. For the frontend, a thin routing layer over a `features/` (domain) directory, with genuinely-shared UI/util in a separate shared location. Include a `/dev` route convention for isolated component development. Present this as a directory tree with a one-line rationale per top-level grouping.
2. **Stop for approval of the proposed structure.**
3. Apply the structure: move files, update imports/module names/aliases, update any path config.
4. Keep behavior identical — this phase is pure reorganization, no logic changes.

**Verify:** backend compiles, frontend builds, app behaves exactly as before the move.

**Status: ✅ DONE.** Approved choices applied: dropped the non-idiomatic `Domains.` namespace (`TemplateApp.Domains.Accounts.*` → `TemplateApp.Accounts.*`), folded auth into the accounts domain (`TemplateApp.Auth.JWT` → `TemplateApp.Accounts.JWT`), flattened app-wide infra (`core/`, `config/`) to the app root, and kept `template_app_web/` as the shared web layer. Frontend reorganized into `lib/features/accounts/` (auth/session, account API, user types) + `lib/shared/` (HTTP client, access-token store, notifications, components, assets) over a thin `routes/` layer; the old `client ↔ auth` import cycle was broken by moving the access-token store into `shared/`, making the dependency direction one-way (`features → shared`), enforced by a new ESLint `no-restricted-imports` boundary. Added a `/dev` route convention (`routes/dev/` index + a `Notifications` sandbox). Tests moved in lockstep. Verified: compile clean (`--warnings-as-errors`), format clean, **42 tests / 0 failures**, frontend `build`/`check`/`lint` green, `/admin` + `/dev/dashboard` + `/auth/*` routes unchanged. Reviewed.

**Stop and review before Phase 4.**

---

## Phase 4 — Aggressive Package Updates

**Objective:** Update everything to latest. This is the highest-risk phase, so it is the most incremental. The detailed execution prompt is in `phase-4-prompt.md` (minor/patch first, then majors strictly one-at-a-time with a full verify gate between each).

1. Update all minor/patch versions first (low risk), backend and frontend. Verify compile/build.
2. Then update major versions **one package at a time**, starting with foundational ones (Elixir/Phoenix/Ash on the backend; Svelte/SvelteKit/Vite on the frontend). For each major bump:
   - Read that package's migration/changelog notes for the version jump.
   - Apply the bump and any required migration changes.
   - Compile/build and run tests.
   - Report what changed before moving to the next major.
3. Do not batch multiple major bumps together — if something breaks, it must be obvious which bump caused it.
4. Update Ash extensions in step with the Ash core version, since they track it.

**Verify after each major bump:** backend compiles, frontend builds, existing tests pass.

**Status: ✅ DONE.** Detailed prompt was in `phase-4-prompt.md`. **Stage A** (minor/patch, batched): backend Ash unit `ash` 3.13→3.27.7, `ash_postgres` 2.6→2.9.1, `ash_phoenix`→2.3.22, `ash_authentication_phoenix`→2.16.0 (`ash_authentication` already latest), plus `phoenix`→1.8.7, `phoenix_live_view`→1.1.31, `ecto_sql`→3.14.0, `postgrex`→0.22.2, `bandit`→1.11.1, `igniter`→0.8.1, `sourceror`→1.12.0, `jason`→1.4.5, `lazy_html`→0.1.11, `credo`→1.7.18, `tidewave`→0.5.6; frontend `svelte`→5.56.1, `@sveltejs/kit`→2.62.0, `tailwindcss`/`@tailwindcss/vite`→4.3.0, `eslint-plugin-svelte`→3.19, `prettier`→3.8.3, `svelte-check`→4.5.0, `typescript-eslint`→8.60.1, `adapter-auto`→7.0.1. The Ash bump shipped `ash_functions_version` 6 → generated migration `update_ash_functions_v6` (infra, not resource drift). **Stage B** (majors, one unit at a time, full verify gate between each): B1 `ash_admin` 0.13→**1.1.0** (constraint only; UI redesign, no DSL break; `/admin` still resolves), B2 `usage_rules` 0.1→**1.2.6** (dev-only, no refs), B3 `vite` 7→**8.0.16** + `@sveltejs/vite-plugin-svelte` 6→**7.1.2** (clean reinstall needed; minimal config used none of the changed options), B4 `eslint`/`@eslint/js` 9→**10** (clean reinstall re-hoisted transitive `globals`), B5 `typescript` 5→**6.0.3** (no edits; `moduleResolution: bundler`), B6 `prettier-plugin-svelte` 3→**4.1.0** (no edits; removed opts unused). Final: backend compile `--warnings-as-errors` clean, format clean, **42 tests / 0 failures**, no resource drift, `/admin`+`/dev/dashboard`+`/auth/*` resolve; frontend `build`/`check`/`lint` green; `mix hex.outdated`/`npm outdated` both empty.

**Known follow-ups (not blocking, deferred — out of Phase 4 scope "updates only, no add/remove packages"):**
- SvelteKit 2.62 now writes `"types": ["node"]` into its generated tsconfig, so `svelte-check` emits one non-blocking **warning** (`Cannot find type definition file for 'node'`). Fix is adding `@types/node`. 0 errors, gate passes.
- `globals` (imported by `eslint.config.js`) resolves only transitively via `eslint-plugin-svelte` rather than as an explicit devDependency — latent fragility.
- `npm run format:check` flags pre-existing prettier diffs (`README.md` is byte-identical to HEAD yet fails, proving the repo was never prettier-clean); not caused by any bump and not reformatted (behavior change, out of scope).

**Stop and review before Phase 5.**

---

## Phase 5 — Auth Rework: Username/Password + Reset Codes

**Objective:** Implement the target auth: username/password login, plus password-reset codes returned to the user and stored Argon2-hashed. The detailed execution prompt is in `phase-5-prompt.md` (grounded in the current auth code; opens with a short propose → **stop for approval** on the four open design decisions, then build → verify-by-curl flow).

1. Ensure the User resource uses username (not email) as the identity field for the password strategy.
2. Confirm passwords are hashed (Argon2).
3. Build the password-reset-code flow:
   - **Request reset:** generate a random single-use code with an expiry. Persist only its Argon2 hash plus expiry and a used/unused marker. Return the plaintext code in the API response (this is the no-email delivery mechanism, acceptable because this is a learning template).
   - **Validate/consume:** accept username + code + new password. Look up the stored hash, verify the code with Argon2, check it's unexpired and unused, set the new password, mark the code used.
   - Codes are single-use and expire; expired/used codes are rejected.
4. Expose REST endpoints for: login, request-reset, consume-reset, logout, and at least one protected endpoint to prove gating.
5. **Re-express the former RPC user operations as plain REST endpoints** (these were `get_user`, `change_username`, `generate_recovery_codes`, `convert_to_registered`, `current_user`). Back them with the existing Ash code-interface functions (or thin controllers calling Ash actions directly) — no RPC dispatcher. The frontend's `$lib/api/*` modules call these with `fetch`, replacing the deleted generated client.

> **Audit note (Phase 0):** The recovery-code flow is *largely already built* — codes are Argon2-hashed, single-use (removed on consume), and returned once. The real gaps are: (a) no per-code **expiry**, and (b) no **unauthenticated "request reset by username"** path (today `generate_recovery_codes` is an authenticated self-action). Also resolve whether `confirmation_required? true` on the password strategy is wanted given there is no email confirmation.

**Verify with curl:** login works; requesting a reset returns a code; consuming it with the right code changes the password; reusing or using an expired code fails; the DB stores only the hash, never the plaintext code.

> **Verify against current AshAuthentication docs before building this phase.** The exact strategy/option names for username-as-identity and how reset/token flows are modeled is the most likely thing to have changed and the worst place to be wrong. Match this flow to the library's actual current API.

**Status: ✅ DONE.** Detailed prompt was in `phase-5-prompt.md`. The four design decisions:
1. **Reset-code shape — reuse the recovery-code batch.** Added an unauthenticated `request_password_reset` update action (`authorize_if always()`) on `User` that reuses the existing `GenerateRecoveryCodes` change; the authenticated `generate_recovery_codes` self-service action is kept as-is.
2. **Expiry — batch TTL.** New `TemplateApp.Config.recovery_code_ttl_seconds/0` (env `RECOVERY_CODE_TTL_SECONDS`, **default 3600s / 1h**), enforced in `ValidateRecoveryCode` (a `nil` timestamp is treated as expired). No new attribute, **no migration**.
3. **`confirmation_required?` — kept `true` (diverges from the prompt's recommended default, deliberately).** Verified against the installed `ash_authentication` 4.13.7 source (`strategies/password/dsl.ex`): this option governs *"whether a password confirmation field is required when registering or changing passwords"* — it does **not** gate sign-in and is **unrelated** to email/account confirmation (there is no confirmation add-on strategy here). Setting it `false` would silently drop the `password_confirmation` match check the register action already relies on, so it was left `true`. The prompt's "set it false" default rested on conflating it with email confirmation.
4. **Endpoint surface.** Public `POST /auth/request-reset` (username → plaintext codes) and `POST /auth/reset-password` (username + code + new password) added to `AuthController`. Former RPC user ops re-expressed in a new `AccountController` behind `:authenticated_api`: `PATCH /account/username`, `POST /account/recovery-codes`, `POST /account/convert`. `get_user`-by-arbitrary-id was **not** exposed (avoids user enumeration; self-user is covered by `GET /auth/me`).

**Files added/changed:** `accounts/resources/user.ex` (new `request_password_reset` action + public policy), `config.ex` (`recovery_code_ttl_seconds/0`), `validations/validate_recovery_code.ex` (batch-expiry check), `accounts.ex` (domain interface `request_password_reset`), `auth_controller.ex` (`request_reset/2`, `reset_password/2`), **new** `account_controller.ex`, `helpers/user_serializer.ex` (shared `serialize_user/1` + `format_ash_errors/1`), `router/router.ex` (5 new routes). Frontend: `features/accounts/api/accounts.ts` (real `fetch` replacing the Phase 1 `notImplemented` stubs), **new** `routes/auth/reset/+page.svelte` (minimal request-reset → reset UI). Plaintext codes are only ever returned in the intended response body; the `recovery_codes` column stores Argon2 hashes only.

**Tests:** the 42 existing tests stay green **with no test modified** — the password-confirmation resolution introduced no behavior change that any existing test asserted against. New reset-flow coverage is Phase 7. **Verified:** `mix compile --warnings-as-errors` clean, `mix format --check-formatted` clean, `mix ash.codegen --check` clean (no schema drift — batch-TTL needs no migration), **42 tests / 0 failures**; frontend `build`/`check`/`lint` green (only the pre-existing non-blocking `node`-types warning); `mix phx.routes` shows `/admin`, `/dev/dashboard`, all `/auth/*`, and the new endpoints. **curl walkthrough all green:** login ok / wrong-password 401; `request-reset` returns plaintext codes; `reset-password` with a valid code succeeds and the new password logs in (old one 401s); reused code → 422 single-use; aged-batch code → 422 expired; unknown username → 404 (existence is necessarily observable since codes ship in the body — by design, no email); DB `recovery_codes` held only `$argon2id$…` hashes (0 plaintext matches); `/auth/me` rejects missing/invalid tokens and accepts a valid one.

**Known follow-ups for Phase 6 (cleanup):** `backend/priv/repo/seeds.exs` still aliases the pre-Phase-4 `TemplateApp.Domains.Accounts*` module paths (broken — never run since the Phase 3 reorg); the stale `// … stubbed until Phase 5 …` comment atop `frontend/src/lib/features/accounts/api/index.ts`.

**Stop and review before Phase 6.**

---

## Phase 6 — Clean Up Code

**Objective:** Tidy what remains, now that structure and dependencies are settled.

1. Remove dead code, leftover scaffolding, and commented-out blocks identified in the audit.
2. Remove duplicated logic, consolidating into shared functions/modules where it genuinely repeats.
3. Make naming consistent and intention-revealing across domains.
4. Ensure each domain's public interface is clear (code interfaces on the Ash side, a clear API module per feature on the frontend).
5. Do NOT introduce new abstractions speculatively — only clean what exists.

**Verify:** backend compiles, frontend builds, app behaves identically, nothing user-facing changed.

**Status: ✅ DONE.** Detailed prompt was in `phase-6-prompt.md`. Pure cleanup, zero behavior change. **Dead modules removed** (each grep-proven only-self-referenced, deleted one-at-a-time with `--warnings-as-errors` between): `TemplateAppWeb.Helpers.ParamHelpers` and `TemplateAppWeb.Helpers.ErrorFormatter` (the live error path is `UserSerializer.format_ash_errors/1`; the only `ErrorFormatter` reference was a stale `runtime.exs` comment, now fixed), and `TemplateApp.Accounts.Checks.HasRole` (admin gating goes through `EnsureAdminPlug` + the `role` attribute; resource `policies do` blocks grepped to confirm). **`web.ex` trimmed:** removed the unused `channel/0`, `live_view/0`, `live_component/0` macros (zero `use TemplateAppWeb, :channel|:live_view|:live_component` call sites; `/dev` + `/admin` LiveViews come from libraries with their own usage). **Consolidation:** new `TemplateAppWeb.Helpers.ApiResponse` (`bad_request/2`, `validation_error/3`, `forbidden/3`) replaces the 400/422/403 error envelopes that were duplicated/inlined across `AuthController` and `AccountController` — exact JSON shape + status codes preserved (verified live: duplicate-register still returns `{"error":"validation_error","message":"Registration failed",…}`); distinct one-offs (auth's `reset_failed` 422, `internal_error/2`) left in place. **`seeds.exs` fixed:** repointed the broken pre-Phase-4 aliases (`TemplateApp.Domains.Accounts*` → `TemplateApp.Accounts*`); verified by actually running `mix run priv/repo/seeds.exs`. **Naming:** renamed the one misaligned file `validations/username_change_rate_limit_validation.ex` → `username_change_rate_limit.ex` (module name unchanged, no DSL/test refs to update); left the validation *module* names alone (renaming for style parity would be churn). **Frontend:** removed the false `// …stubbed until Phase 5…` comment in `features/accounts/api/index.ts` and reworded the stale "Phase 5 … will reuse it" doc in `auth/refresh.ts`; `features → shared` boundary untouched. Incidentally reordered `import`-before-`alias`/`require` in both controllers (I was editing the headers) to keep credo `StrictModuleLayout` clean. **Verified:** compile `--warnings-as-errors` clean, format clean, **credo `--strict` found no issues**, `ash.codegen --check` clean (no schema change), **42 tests / 0 failures with no test modified**; frontend `build`/`check`/`lint` green (only the pre-existing non-blocking `node`-types warning); `mix phx.routes` shows `/admin`, `/dev/dashboard`, all `/auth/*` + `/account/*` unchanged; smoke test green (server boots, `/health`→ok, `/dev/dashboard`→200, `POST /auth/login`→`GET /auth/me` round-trip succeeds). Nothing left as "suspected unused, pending approval." Reviewed.

**Stop and review before Phase 7.**

---

## Phase 7 — Functional Tests, Remove Useless Ones

**Objective:** End with a test suite that catches regressions and contains no low-value tests.

1. Delete the low-value tests identified in the audit (framework-internal, trivial, over-mocked unit tests). **Note:** the Phase 0 audit found the existing suite is all high-value *except* `rpc_controller_test.exs`, which becomes obsolete when the RPC layer is removed — its behaviors (get_user, change_username, recovery codes, convert) must be re-covered by the new REST endpoint tests.
2. **Backend:** functional tests of the auth behaviors via the API — login success/failure, reset-code request/consume/expiry/reuse, protected-endpoint gating. Test real behavior through real actions against a test database, not mocked internals.
3. **Frontend:** the three-tier strategy —
   - **View tests** for display logic with real branches (mock data from a shared fixtures module).
   - **Integration tests** with the network mocked (MSW), covering user-visible states: login success, login failure, reset flow. This is the main tier.
   - **A handful of E2E** (Playwright, network mocked — not a live backend) for the critical journey only.
4. No test should assert on internal implementation details or mock the code under test.

**Verify:** the suite runs green, every remaining test maps to a user-facing behavior or a real display branch.

**Done:** the template is refreshed — REST-only, latest packages, domain structure, username/password + reset codes, clean code, functional tests.

---

## Phase Summary

| Phase | What                                     | Ends when                         | Status |
| ----- | ---------------------------------------- | --------------------------------- | ------ |
| 0     | Audit, no changes                        | report delivered, reviewed        | ✅ done |
| 1     | Remove Inertia, RPC layer, non-REST path | compiles as plain REST API + SPA  | ✅ done |
| 2     | Remove confirmed-unused packages         | compiles, lockfiles regenerated   | ✅ done |
| 3     | Propose + apply domain structure         | reorganized, behavior unchanged   | ✅ done |
| 4     | Aggressive updates, majors one-at-a-time | latest everything, compiles       | ✅ done |
| 5     | Username/password + reset codes          | full auth cycle works via curl    | ✅ done |
| 6     | Clean up code                            | tidy, behavior unchanged          | ✅ done |
| 7     | Functional tests, drop useless ones      | green suite, all tests meaningful | ▶ next (`phase-7-prompt.md`) |

**The governing rule:** every phase ends in a compiling, working state, and you review before the next begins. Aggressive package updates (Phase 4) are the main risk; one-major-at-a-time with a compile between each is what keeps that risk localizable. The audit (Phase 0) exists so you approve the destructive decisions (what's unused, what structure) before anything is deleted or moved.
