import { expect, test } from '@playwright/test';

test('development sandbox routes return 404 in the production SPA build', async ({ page }) => {
	await page.route('**/auth/refresh', (route) =>
		route.fulfill({
			status: 401,
			contentType: 'application/json',
			body: JSON.stringify({ error: 'no_refresh_token', message: 'No refresh token found' })
		})
	);

	for (const path of ['/dev', '/dev/notifications']) {
		await page.goto(path);
		await expect(page.getByRole('heading', { name: 'Page not found' })).toBeVisible();
	}
});
