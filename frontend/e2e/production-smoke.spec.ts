import { expect, test } from '@playwright/test';

test('production SPA bootstraps under the enforced CSP', async ({ page }) => {
	await page.route('**/auth/refresh', (route) =>
		route.fulfill({
			status: 401,
			contentType: 'application/json',
			body: JSON.stringify({ error: 'no_refresh_token', message: 'No refresh token found' })
		})
	);

	const response = await page.goto('/');

	expect(response).not.toBeNull();
	const csp = response?.headers()['content-security-policy'] ?? '';
	expect(csp).toContain("script-src 'self'");
	expect(csp).not.toContain("'unsafe-inline'");
	expect(response?.headers()['strict-transport-security']).toContain('max-age=31536000');
	await expect(page.getByRole('heading', { name: 'Welcome to the App' })).toBeVisible();

	await page.goto('/auth/login');
	await expect(page.getByRole('heading', { name: 'Sign in to your account' })).toBeVisible();

	await page.goto('/profile');
	await expect(page).toHaveURL(/\/auth\/login$/);
});
