// Re-export from main modules for convenience
// Note: Prefer direct imports for tree-shaking (e.g., import { login } from '$lib/auth')

export * from './types';
export * from './stores';

// Auth is exported separately to avoid circular dependency issues
// Use: import { login, currentUser } from '$lib/auth'

// API is exported separately to encourage explicit imports
// Use: import { fetchUser } from '$lib/api'
