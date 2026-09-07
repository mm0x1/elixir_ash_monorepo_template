import { expect, test, type Page } from '@playwright/test';
import { userDto } from '../tests/support/fixtures';

async function loginViaRoutes(page: Page) {
	await page.route('**/auth/refresh', (route) =>
		route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify({ access_token: 'e2e-access-token', expires_in: 900 })
		})
	);

	await page.route('**/auth/me', (route) =>
		route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify({ user: userDto })
		})
	);
}

test('viewing the profile page shows account info', async ({ page }) => {
	await loginViaRoutes(page);
	await page.goto('/profile');

	await expect(page.getByRole('main').getByText('alice')).toBeVisible();
	await expect(page.getByRole('main').getByText('User', { exact: true })).toBeVisible();
});

test('logging out returns to the home page', async ({ page }) => {
	await loginViaRoutes(page);

	await page.route('**/auth/logout', (route) =>
		route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify({ message: 'Logged out' })
		})
	);

	await page.goto('/');
	await expect(page.getByText('Hello,')).toContainText('alice');

	await page.getByRole('button', { name: 'Logout' }).click();

	await expect(page.getByRole('link', { name: 'Login' })).toBeVisible();
	await expect(page.getByText('Please sign in or create an account')).toBeVisible();
});
