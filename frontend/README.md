# Frontend (SvelteKit)

SvelteKit 2 + Svelte 5 frontend for the monorepo template.

## Development

Run the complete local workflow from the repository root:

```bash
mise install
mise run tilt
```

The Tilt workflow installs frontend dependencies, prepares the backend and
database, starts Phoenix and Vite, and provides unified logs and readiness in
the Tilt UI. Use `mise run setup` when you need one-shot preparation without
starting the application servers.

For frontend-only work:

```bash
npm ci
npm run dev
npm run check
npm run lint
npm run format:check
npm run test:unit
npm run test:unit:watch
npm run test:e2e:ui
```

Vite runs on `127.0.0.1:5173` and fails instead of silently selecting another
port. The local server loads the repository-root environment and proxies
`/auth`, `/account`, and `/health` to Phoenix. Leave `VITE_API_URL` empty for
local development; set it for a separately hosted or production frontend.

## Password Recovery

Recovery codes are generated while signed in from the account recovery page and
are shown only once. The password-reset form requires a username, a previously
stored recovery code, and a new password. The application never sends email; if
all recovery codes are lost, there is no self-service password-reset path.

## Project Structure

```text
src/
├── lib/
│   ├── features/             # Domain code: API wrappers, auth, UI types
│   │   └── accounts/
│   ├── shared/               # HTTP client, token store, components, stores
│   └── ...
├── routes/                   # SvelteKit pages
│   ├── +layout.svelte
│   ├── auth/
│   ├── profile/
│   └── dev/                  # Development-only component sandboxes
└── app.html
```

## Key Patterns

### API Boundary

Components use feature API wrappers rather than making raw requests. Wrappers
use the shared REST client and convert backend DTOs into UI types:

```typescript
import { api } from '$lib/shared/api/client';
import { authenticatedFetch } from '$lib/features/accounts/auth/refresh';
import type { UserDto } from '$lib/features/accounts/types/user';
import { toUser } from '$lib/features/accounts/types';

export async function updateUsername(username: string) {
	const data = await api.patch<{ user: UserDto }>(
		'/account/username',
		{ username },
		{ fetchFn: authenticatedFetch }
	);

	return toUser(data.user);
}
```

### Svelte 5 Runes

Use runes for component state and props:

```svelte
<script lang="ts">
	let { userId }: { userId: string } = $props();
	let loading = $state(true);
</script>
```

Keep shared code independent from `features/`; dependencies flow from features
to shared, never in the opposite direction.

## Testing

Unit and integration tests use Vitest with jsdom and MSW. E2E tests use
Playwright against a built SPA and mock the network with `page.route()`.

```bash
npm run test:unit             # One deterministic run
npm run test:unit:watch       # Interactive local feedback
npm run test:unit:related -- src/lib/path/to/file.ts
npm run test:e2e              # Full Playwright run
npm run test:e2e:ui           # Playwright UI mode
npm run build && npm run preview # Preview the SPA with client-side fallback
```

Install the browser used by the E2E project when needed:

```bash
npx playwright install chromium
```

## Environment Variables

| Variable        | Description                                                  |
| --------------- | ------------------------------------------------------------ |
| `VITE_API_URL`  | Optional absolute API URL for hosted/static deployments      |
| `VITE_APP_NAME` | Optional application label; not currently consumed by source |

The root `.env.example` contains the development defaults. Vite only exposes
variables prefixed with `VITE_` to browser code.

The production Docker image accepts `VITE_API_URL` as a build argument when the
frontend is hosted separately from the Phoenix release.
