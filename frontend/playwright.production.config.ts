import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
	testDir: './e2e',
	testMatch: /production-smoke\.spec\.ts/,
	fullyParallel: false,
	forbidOnly: true,
	use: {
		baseURL: process.env.PRODUCTION_BASE_URL ?? 'http://127.0.0.1:4000',
		extraHTTPHeaders: {
			'x-forwarded-proto': 'https'
		},
		trace: 'retain-on-failure'
	},
	projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }]
});
