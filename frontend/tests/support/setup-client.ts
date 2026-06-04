/**
 * Client test setup: jest-dom matchers, SvelteKit app-module mocks, and the
 * MSW server lifecycle.
 */

import '@testing-library/jest-dom/vitest';
import { afterAll, afterEach, beforeAll, vi } from 'vitest';
import { server } from './server';

// Components import `goto`/`resolve` from SvelteKit's app modules, which only
// work inside a running client router. Mock them so components render in jsdom;
// `goto` is a spy so tests can assert navigation.
vi.mock('$app/navigation', () => ({
	goto: vi.fn(),
	invalidate: vi.fn(),
	invalidateAll: vi.fn()
}));

vi.mock('$app/paths', () => ({
	resolve: (path: string) => path,
	base: '',
	assets: ''
}));

// Network seam: MSW intercepts every fetch. An unhandled request is a test bug.
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
