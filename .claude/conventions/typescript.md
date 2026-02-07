# TypeScript/Svelte Conventions

**Apply these conventions to all TypeScript and Svelte code in this project.**

---

## TypeScript Fundamentals

### Strict Typing (No `any`)

**Principle**: TypeScript's value is in its types. `any` defeats the purpose.

```typescript
// 🔴 CRITICAL: No any
// 🔴 NO
function process(data: any) { ... }
const result: any = fetchData();

// 🟢 YES: Use proper types
function process(data: UserData) { ... }
const result: ApiResponse<User> = await fetchData();

// 🟢 YES: Use unknown for truly unknown data, then narrow
function handleResponse(data: unknown) {
  if (isUserData(data)) {
    // data is now UserData
    return processUser(data);
  }
  throw new Error('Invalid data format');
}

// Type guard
function isUserData(data: unknown): data is UserData {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'email' in data
  );
}
```

### Interfaces vs Types

**Principle**: Use `interface` for object shapes, `type` for unions/primitives/utilities.

```typescript
// 🟢 YES: Interface for object shapes
interface User {
  id: string;
  email: string;
  username: string;
}

interface UserCardProps {
  user: User;
  onEdit: () => void;
}

// 🟢 YES: Type for unions and derived types
type Status = 'pending' | 'active' | 'suspended';
type UserId = string;  // Branded type
type UserWithRoles = User & { roles: Role[] };

// 🟢 YES: Type for utility types
type PartialUser = Partial<User>;
type UserKeys = keyof User;
```

### Discriminated Unions for State

**Principle**: Make invalid states unrepresentable with discriminated unions.

```typescript
// 🟢 YES: Discriminated union for fetch state
type FetchState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

// Usage in Svelte
let state = $state<FetchState<User>>({ status: 'idle' });

{#if state.status === 'loading'}
  <Loading />
{:else if state.status === 'success'}
  <UserCard user={state.data} />
{:else if state.status === 'error'}
  <ErrorMessage error={state.error} />
{/if}

// 🔴 NO: Separate booleans allow invalid states
interface BadState {
  isLoading: boolean;  // Can be true while data exists
  data: User | null;
  error: Error | null;  // Can have both data and error
}
```

### Const Assertions

**Principle**: Use `as const` for literal types and readonly data.

```typescript
// 🟢 YES: Const assertion for literal types
const STATUSES = ['draft', 'published', 'archived'] as const;
type Status = typeof STATUSES[number];  // 'draft' | 'published' | 'archived'

// 🟢 YES: Config objects
const config = {
  apiUrl: '/api',
  timeout: 5000,
} as const;
```

---

## Svelte 5 Patterns

### Runes (CRITICAL)

**Principle**: Use Svelte 5 runes, not legacy reactive statements.

```svelte
<!-- 🔴 NO: Svelte 4 legacy syntax -->
<script>
  let count = 0;
  $: doubled = count * 2;
  $: console.log('count changed', count);
</script>

<!-- 🟢 YES: Svelte 5 runes -->
<script lang="ts">
  let count = $state(0);
  let doubled = $derived(count * 2);

  $effect(() => {
    console.log('count changed', count);
  });
</script>
```

### Component Props

**Principle**: Use `$props()` with TypeScript interface.

```svelte
<script lang="ts">
  interface Props {
    userId: string;
    userName: string;
    onSave?: (id: string) => void;
    children?: import('svelte').Snippet;
  }

  let { userId, userName, onSave, children }: Props = $props();
</script>

<div>
  <h1>{userName}</h1>
  {#if children}
    {@render children()}
  {/if}
  {#if onSave}
    <button onclick={() => onSave(userId)}>Save</button>
  {/if}
</div>
```

### State Management

**Principle**: Use `$state` for reactive state, `$derived` for computed values.

```svelte
<script lang="ts">
  // 🟢 YES: $state for mutable values
  let count = $state(0);
  let user = $state<User | null>(null);
  let items = $state<Item[]>([]);

  // 🟢 YES: $derived for computed values
  let doubled = $derived(count * 2);
  let isLoggedIn = $derived(user !== null);
  let itemCount = $derived(items.length);

  // 🟢 YES: $derived.by for complex computations
  let sortedItems = $derived.by(() => {
    return [...items].sort((a, b) => a.name.localeCompare(b.name));
  });
</script>
```

### Effects

**Principle**: Use `$effect` for side effects that depend on reactive values.

```svelte
<script lang="ts">
  let userId = $props().userId;
  let user = $state<User | null>(null);

  // 🟢 YES: Effect for data fetching
  $effect(() => {
    fetchUser(userId).then((u) => (user = u));
  });

  // 🟢 YES: Effect with cleanup
  $effect(() => {
    const interval = setInterval(() => console.log('tick'), 1000);
    return () => clearInterval(interval);
  });

  // 🔴 NO: Side effects in $derived
  let data = $derived({
    fetch('/api/data'); // Don't do this!
    return count * 2;
  });
</script>
```

### Event Handlers

**Principle**: Use inline handlers or named functions. No `on:` directive in Svelte 5.

```svelte
<script lang="ts">
  let count = $state(0);

  function handleClick() {
    count += 1;
  }

  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Enter') {
      handleClick();
    }
  }
</script>

<!-- 🟢 YES: Svelte 5 syntax -->
<button onclick={handleClick}>Click me</button>
<button onclick={() => count += 1}>Inline</button>
<input onkeydown={handleKeydown} />

<!-- 🔴 NO: Svelte 4 syntax -->
<button on:click={handleClick}>Click me</button>
```

### Control Flow

**Principle**: Use Svelte's built-in control flow blocks.

```svelte
<!-- 🟢 YES: If blocks -->
{#if loading}
  <Loading />
{:else if error}
  <ErrorMessage {error} />
{:else}
  <Content {data} />
{/if}

<!-- 🟢 YES: Each blocks with key -->
{#each items as item (item.id)}
  <ItemCard {item} />
{/each}

<!-- 🟢 YES: Await blocks for promises -->
{#await promise}
  <Loading />
{:then data}
  <Content {data} />
{:catch error}
  <ErrorMessage {error} />
{/await}
```

### Bindings

**Principle**: Use `bind:` for two-way data binding.

```svelte
<script lang="ts">
  let name = $state('');
  let checked = $state(false);
  let selected = $state('');
</script>

<input bind:value={name} />
<input type="checkbox" bind:checked />
<select bind:value={selected}>
  <option value="a">A</option>
  <option value="b">B</option>
</select>
```

---

## API Boundary Pattern

### Never Import Generated Directly

**Principle**: Components import from `$lib/api/`, never from `$lib/generated/`.

```typescript
// 🔴 NO: Direct import of generated types
import { get_user, UserSchema } from "$lib/generated/ash_rpc";

// 🟢 YES: Import from api boundary
import { fetchUser } from "$lib/api/accounts";
import type { User } from "$lib/types/user";
```

### API Wrapper Structure

**Principle**: API wrappers transform DTOs to UI types and inject auth.

```typescript
// frontend/src/lib/api/accounts.ts
import { get_user, change_username } from "$lib/generated/ash_rpc";
import { getAuthHeaders, ApiError } from "$lib/api/client";
import type { User } from "$lib/types/user";

function toUser(dto: Record<string, unknown>): User {
  return {
    id: dto.id as string,
    displayName: dto.username as string,
    isGuest: dto.is_anonymous as boolean,
    role: dto.role as User["role"],
  };
}

export async function fetchUser(userId: string): Promise<User> {
  const result = await get_user({
    input: { id: userId },
    headers: getAuthHeaders(),
  });

  if (!result.success) {
    throw new ApiError(result.errors);
  }

  return toUser(result.data);
}
```

---

## SvelteKit Patterns

### Load Functions

**Principle**: Use load functions for data fetching, not effects in components.

```typescript
// 🟢 YES: Load function in +page.ts
// frontend/src/routes/users/[id]/+page.ts
import { fetchUser } from '$lib/api/accounts';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params }) => {
  const user = await fetchUser(params.id);
  return { user };
};
```

```svelte
<!-- 🟢 YES: Component receives data from load -->
<script lang="ts">
  import type { PageData } from './$types';

  let { data }: { data: PageData } = $props();
</script>

<h1>{data.user.displayName}</h1>
```

### Layout Data

**Principle**: Share data across routes using layout load functions.

```typescript
// frontend/src/routes/+layout.ts
import { get } from 'svelte/store';
import { currentUser } from '$lib/auth/store';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async () => {
  const user = get(currentUser);
  return { user };
};
```

### Navigation

**Principle**: Use `goto` for programmatic navigation, links for declarative.

```svelte
<script lang="ts">
  import { goto } from '$app/navigation';

  async function handleSave() {
    await saveData();
    goto('/dashboard');
  }
</script>

<!-- Declarative navigation -->
<a href="/dashboard">Dashboard</a>

<!-- Programmatic navigation -->
<button onclick={handleSave}>Save and Continue</button>
```

---

## Type Safety Patterns

### Zod for Input Validation

**Principle**: Use generated Zod schemas for form validation.

```typescript
// Generated schemas are in ash_rpc.ts, re-export through api/
import { validateChangeUsername } from "$lib/api/accounts";

async function handleSubmit() {
  const validation = validateChangeUsername({ username });
  if (!validation.success) {
    errors = validation.errors;
    return;
  }
  // Submit...
}
```

### Type Guards

**Principle**: Use type guards for runtime type narrowing.

```typescript
// 🟢 YES: Type guard function
function isApiError(error: unknown): error is ApiError {
  return (
    typeof error === 'object' &&
    error !== null &&
    'message' in error &&
    'code' in error
  );
}

// Usage
try {
  await fetchData();
} catch (error) {
  if (isApiError(error)) {
    showError(error.message);  // TypeScript knows error.message exists
  } else {
    showError('Unknown error');
  }
}
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `any` | Use proper type or `unknown` with guards |
| Using `$:` reactive statements | Use `$derived` or `$effect` |
| Using `on:click` | Use `onclick` (Svelte 5) |
| Importing from `$lib/generated/` in components | Import from `$lib/api/` |
| Fetching data in `$effect` | Use SvelteKit load functions when possible |
| Using legacy Svelte stores in components | Use `$state` and `$derived` runes |
| Missing cleanup in effects | Return cleanup function from `$effect` |
| Complex inline handlers | Extract to named functions |
