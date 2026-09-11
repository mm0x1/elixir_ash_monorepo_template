import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

function apiOrigin() {
	const value = process.env.VITE_API_URL?.trim() ?? '';

	if (value === '') return null;

	let parsed;

	try {
		parsed = new URL(value);
	} catch {
		throw new Error('VITE_API_URL must be an absolute HTTPS origin');
	}

	if (
		parsed.protocol !== 'https:' ||
		parsed.username !== '' ||
		parsed.password !== '' ||
		parsed.search !== '' ||
		parsed.hash !== '' ||
		!['', '/'].includes(parsed.pathname)
	) {
		throw new Error('VITE_API_URL must be an absolute HTTPS origin without a path');
	}

	return parsed.origin;
}

const externalApiOrigin = apiOrigin();
const self = "'self'";

/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: vitePreprocess(),
	kit: {
		csp: {
			mode: 'hash',
			directives: {
				'default-src': [self],
				'script-src': [self],
				'style-src': [self],
				'img-src': [self, 'data:', 'https:'],
				'font-src': [self, 'data:'],
				'connect-src': [self, ...(externalApiOrigin ? [externalApiOrigin] : [])],
				'object-src': ["'none'"],
				'base-uri': [self],
				'form-action': [self],
				'frame-ancestors': ["'none'"]
			}
		},
		adapter: adapter({
			pages: 'build',
			assets: 'build',
			fallback: 'index.html',
			strict: false
		}),
		alias: {
			$lib: './src/lib'
		}
	}
};

export default config;
