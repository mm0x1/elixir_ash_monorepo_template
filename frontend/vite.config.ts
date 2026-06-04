import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { svelteTesting } from '@testing-library/svelte/vite';
import { defineConfig } from 'vitest/config';

export default defineConfig({
	plugins: [tailwindcss(), sveltekit()],
	test: {
		// Unit + integration tests run in a jsdom "client" project so Svelte 5
		// components render against a DOM. The `svelteTesting()` plugin enables
		// the `browser` resolve condition and auto-unmounts components after each
		// test. Playwright E2E lives under `e2e/` and is run separately.
		projects: [
			{
				extends: true,
				plugins: [svelteTesting()],
				test: {
					name: 'client',
					environment: 'jsdom',
					clearMocks: true,
					setupFiles: ['./tests/support/setup-client.ts'],
					include: ['tests/unit/**/*.{test,spec}.ts']
				}
			}
		]
	}
});
