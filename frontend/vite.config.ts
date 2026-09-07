import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { svelteTesting } from '@testing-library/svelte/vite';
import { loadEnv, type Plugin } from 'vite';
import { defineConfig } from 'vitest/config';

const frontendAuthPaths = new Set(['/auth/login', '/auth/register', '/auth/reset']);

const spaAuthNavigation: Plugin = {
	name: 'spa-auth-navigation',
	configureServer(server) {
		server.middlewares.use((request, _response, next) => {
			const path = request.url?.split('?')[0]?.replace(/\/+$/, '');
			const isAuthDocument =
				request.method === 'GET' &&
				request.headers.accept?.includes('text/html') &&
				path !== undefined &&
				frontendAuthPaths.has(path);

			if (isAuthDocument) request.url = '/';
			next();
		});
	}
};

export default defineConfig(({ mode }) => {
	const env = loadEnv(mode, '..', ['PORT']);
	const backendTarget = `http://127.0.0.1:${env.PORT ?? '4000'}`;

	return {
		envDir: '..',
		plugins: [tailwindcss(), spaAuthNavigation, sveltekit()],
		server: {
			host: '127.0.0.1',
			port: 5173,
			strictPort: true,
			proxy: {
				'/auth': { target: backendTarget },
				'/account': { target: backendTarget },
				'/health': { target: backendTarget }
			}
		},
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
	};
});
