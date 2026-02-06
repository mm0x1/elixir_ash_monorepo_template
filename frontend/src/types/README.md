# TypeScript Types

This directory contains TypeScript type definitions for the frontend application.

## Type Strategy

Types in `frontend/src/types/` are manually maintained for:

1. **Inertia page props** - Types matching controller serializers
2. **Common types** - Shared interfaces like `BasePageProps`, `FlashMessages`
3. **Component props** - Types for React components (in `ui.ts`)

## Current Files

### `common.ts`

Contains base types for Inertia pages:

```typescript
// Error types for form validation
export type ErrorValue = string | string[] | { [key: string]: ErrorValue };

// Flash message types
export interface FlashMessages {
  success?: string;
  error?: string;
  info?: string;
  warning?: string;
}

// Base props for all Inertia pages
export interface BasePageProps {
  errors?: Record<string, ErrorValue>;
  flash?: FlashMessages;
}
```

### `ui.ts`

Contains prop types for UI components:

- `ButtonProps` - Button component props
- `LoadingProps` - Loading spinner props
- `BrandProps` - Brand component props
- `ErrorBoundaryProps` - Error boundary props
- `FlashMessagesProps` - Flash messages component props

## When to Update Types

Update types in this directory when:

1. **Changing controller serializers** - Update the corresponding interface
2. **Adding new page props** - Create interfaces for new props
3. **Adding new pages** - Define prop types extending `BasePageProps`
4. **Adding new UI components** - Add prop interfaces to `ui.ts`

## Examples

### Adding a New Page with Custom Props

```typescript
// frontend/src/types/post.ts
import { BasePageProps } from './common';

export interface PostProps extends BasePageProps {
  post: {
    id: string;
    title: string;
    content: string;
    author: {
      id: string;
      username: string;
    };
  };
}
```

```tsx
// frontend/src/pages/Posts/Show.tsx
import type { PostProps } from '@/types/post';

export default function Show({ post }: PostProps) {
  return <div>{post.title}</div>;
}
```

### Matching Controller Serializer

When creating types, match them to your Phoenix controller serializers:

```elixir
# Controller serializer
defp serialize_post(post) do
  %{
    id: post.id,
    title: post.title,
    content: post.content,
    author: %{
      id: post.author.id,
      username: post.author.username
    }
  }
end
```

```typescript
// TypeScript type (must match exactly)
interface SerializedPost {
  id: string;
  title: string;
  content: string;
  author: {
    id: string;
    username: string;
  };
}
```

## Common Guidelines

### Nullable Fields

```typescript
// Match Ash resource nullability (allow_nil?: true)
interface User {
  username_last_changed: string | null;  // Field can be null
  username: string;                       // Required field
}
```

### Snake Case Convention

```typescript
// Serializers use snake_case (matching Elixir)
interface User {
  username_last_changed: string | null;  // Not usernameLastChanged
}
```

## File Structure

```
frontend/src/types/
├── README.md        # This file
├── common.ts        # BasePageProps, FlashMessages, ErrorValue
├── ui.ts            # UI component prop types
└── [domain].ts      # Domain-specific types as needed
```

---

*Update this README when adding new type patterns or guidelines*
