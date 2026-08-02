import { expect, test } from '@playwright/test';

test('navigating to a non-existent route shows the error page', async ({ page }) => {
	await page.route('**/auth/refresh', (route) =>
		route.fulfill({
			status: 401,
			contentType: 'application/json',
			body: JSON.stringify({ error: 'no_refresh_token', message: 'No refresh token found' })
		})
	);

	await page.goto('/this-page-does-not-exist');

	await expect(page.getByText('Page not found')).toBeVisible();
	await expect(page.getByRole('link', { name: 'Go home' })).toBeVisible();
});
