# TypeScript/React Conventions

**Apply these conventions to all TypeScript and React code in this project.**

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

function UserDisplay({ state }: { state: FetchState<User> }) {
  switch (state.status) {
    case 'idle':
      return null;
    case 'loading':
      return <Loading />;
    case 'success':
      return <UserCard user={state.data} />;  // TypeScript knows data exists
    case 'error':
      return <ErrorMessage error={state.error} />;
  }
}

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

## React Patterns

### Functional Components Only

**Principle**: No class components except for Error Boundaries (React limitation).

```typescript
// 🟢 YES: Functional component
function UserProfile({ user }: UserProfileProps) {
  const [editing, setEditing] = useState(false);

  return (
    <div>
      {editing ? <EditForm user={user} /> : <DisplayCard user={user} />}
    </div>
  );
}

// 🔴 NO: Class component (except ErrorBoundary)
class UserProfile extends React.Component { ... }
```

### Hook Rules

**Principle**: Follow React's rules of hooks strictly.

```typescript
// 🔴 CRITICAL: Hooks at top level, not in conditionals
// 🔴 NO
function Component({ show }: Props) {
  if (show) {
    const [value, setValue] = useState('');  // Violates hook rules
  }
}

// 🟢 YES: Always call hooks at top level
function Component({ show }: Props) {
  const [value, setValue] = useState('');

  if (!show) return null;

  return <Input value={value} onChange={setValue} />;
}
```

### Dependency Arrays

**Principle**: Include all dependencies. Use `useCallback`/`useMemo` strategically.

```typescript
// 🟢 YES: All dependencies listed
useEffect(() => {
  fetchUser(userId);
}, [userId, fetchUser]);

// 🟢 YES: useCallback for stable references
const handleSubmit = useCallback((data: FormData) => {
  submitForm(data, userId);
}, [userId, submitForm]);

// 🟡 Recommended: useMemo for expensive computations
const sortedItems = useMemo(
  () => items.sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);

// 🔴 NO: Missing dependencies
useEffect(() => {
  fetchUser(userId);  // userId missing from deps
}, []);
```

### Early Returns

**Principle**: Handle edge cases first, then render main content.

```typescript
// 🟢 YES: Early returns for clarity
function UserList({ users, isLoading, error }: Props) {
  if (isLoading) return <Loading />;
  if (error) return <ErrorState error={error} />;
  if (users.length === 0) return <EmptyState />;

  return (
    <ul>
      {users.map(user => <UserItem key={user.id} user={user} />)}
    </ul>
  );
}

// 🔴 NO: Nested conditionals in JSX
function UserList({ users, isLoading, error }: Props) {
  return (
    <div>
      {isLoading ? (
        <Loading />
      ) : error ? (
        <ErrorState error={error} />
      ) : users.length === 0 ? (
        <EmptyState />
      ) : (
        <ul>{users.map(...)}</ul>
      )}
    </div>
  );
}
```

### Named Handler Functions

**Principle**: Extract handlers for readability and debugging.

```typescript
// 🟢 YES: Named handlers
function LoginForm() {
  const { data, setData, post, processing } = useForm({
    email: '',
    password: '',
  });

  function handleEmailChange(e: ChangeEvent<HTMLInputElement>) {
    setData('email', e.target.value);
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post('/sign-in');
  }

  return (
    <form onSubmit={handleSubmit}>
      <input value={data.email} onChange={handleEmailChange} />
      <button disabled={processing}>Sign In</button>
    </form>
  );
}

// 🔴 NO: Complex inline handlers
<button onClick={(e) => {
  e.preventDefault();
  validateForm();
  if (isValid) {
    submitData();
    trackEvent('form_submit');
  }
}}>
```

### Component Composition

**Principle**: Prefer composition and props over prop drilling.

```typescript
// 🟢 YES: Composition with children
function Card({ children, title }: CardProps) {
  return (
    <div className="card">
      <h2>{title}</h2>
      {children}
    </div>
  );
}

function UserCard({ user }: { user: User }) {
  return (
    <Card title={user.name}>
      <p>{user.email}</p>
      <UserActions user={user} />
    </Card>
  );
}

// 🟢 YES: Context for deeply shared state
const UserContext = createContext<User | null>(null);

function useUser() {
  const user = useContext(UserContext);
  if (!user) throw new Error('useUser must be within UserProvider');
  return user;
}
```

---

## Inertia.js Integration

### BasePageProps (CRITICAL)

**Principle**: All page props must extend BasePageProps with index signature.

```typescript
// 🔴 CRITICAL: Index signature required for Inertia compatibility
interface BasePageProps {
  errors?: Record<string, string | string[]>;
  flash?: FlashMessages;
  [key: string]: unknown;  // Required for Inertia
}

// 🟢 YES: Page props extend BasePageProps
interface UserPageProps extends BasePageProps {
  user: User;
  canEdit: boolean;
}

export default function UserPage({ user, canEdit }: UserPageProps) {
  // ...
}
```

### Router Usage (CRITICAL)

**Principle**: Use `router.visit()` with options, not `router.replace()`.

```typescript
// 🔴 CRITICAL: Correct router usage
// 🟢 YES
router.visit('/users', { replace: true });
router.visit('/users', { preserveState: true, preserveScroll: true });

// 🔴 NO: router.replace doesn't exist
router.replace('/users');  // This will fail
```

### Typed Page Hook

**Principle**: Use typed page hook for type-safe prop access.

```typescript
// 🟢 YES: Typed page access
import { useTypedPage } from '@/lib/inertia';

function UserPage() {
  const { props } = useTypedPage<UserPageProps>();
  const { user, canEdit } = props;

  return <UserDisplay user={user} editable={canEdit} />;
}
```

### useForm Pattern

**Principle**: Use Inertia's useForm for form state and submission.

```typescript
// 🟢 YES: useForm for forms
function CreateUserForm() {
  const { data, setData, post, processing, errors } = useForm({
    email: '',
    username: '',
    password: '',
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post('/users');
  }

  return (
    <form onSubmit={handleSubmit}>
      <TextField
        name="email"
        value={data.email}
        onChange={(e) => setData('email', e.target.value)}
        error={errors.email}
      />
      <Button type="submit" loading={processing}>
        Create User
      </Button>
    </form>
  );
}
```

---

## Type Safety Patterns

### Zod for Runtime Validation

**Principle**: Use Zod schemas for runtime validation of external data.

```typescript
// 🟢 YES: Zod schema for API responses
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  username: z.string().min(3),
});

type User = z.infer<typeof UserSchema>;

async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return UserSchema.parse(data);  // Throws if invalid
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

### Branded Types

**Principle**: Use branded types to prevent mixing similar primitives.

```typescript
// 🟢 YES: Branded types for IDs
type UserId = string & { readonly brand: unique symbol };
type PostId = string & { readonly brand: unique symbol };

function getUser(id: UserId): User { ... }
function getPost(id: PostId): Post { ... }

// Now these are type errors:
getUser(postId);  // Error: PostId not assignable to UserId
getPost(userId);  // Error: UserId not assignable to PostId
```

---

## Testing Patterns

### Component Testing

```typescript
// 🟢 YES: Test user-visible behavior
import { render, screen, fireEvent } from '@testing-library/react';

test('displays user name', () => {
  render(<UserCard user={mockUser} />);
  expect(screen.getByText(mockUser.name)).toBeInTheDocument();
});

test('calls onEdit when edit button clicked', () => {
  const onEdit = vi.fn();
  render(<UserCard user={mockUser} onEdit={onEdit} />);

  fireEvent.click(screen.getByRole('button', { name: /edit/i }));

  expect(onEdit).toHaveBeenCalledWith(mockUser.id);
});
```

### Mocking Inertia

```typescript
// 🟢 YES: Mock Inertia's usePage
vi.mock('@inertiajs/react', () => ({
  usePage: () => ({
    props: {
      user: mockUser,
      flash: {},
      errors: {},
    },
  }),
  router: {
    visit: vi.fn(),
    post: vi.fn(),
  },
}));
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `any` | Use proper type or `unknown` with guards |
| Missing `[key: string]: unknown` in BasePageProps | Add index signature |
| Using `router.replace()` | Use `router.visit(url, { replace: true })` |
| Hooks in conditionals | Move hooks to top level |
| Missing dependency array items | Include all dependencies |
| Inline complex handlers | Extract to named functions |
| Not handling loading/error states | Always show appropriate UI states |
| Class components | Use functional components (except ErrorBoundary) |
