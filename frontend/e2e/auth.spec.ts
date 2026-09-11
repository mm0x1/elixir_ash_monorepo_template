import { expect, test } from '@playwright/test';
import { userDto } from '../tests/support/fixtures';

test('auth pages expose one main landmark and keyboard-visible form navigation', async ({
	page
}) => {
	await page.route('**/auth/refresh', (route) =>
		route.fulfill({
			status: 401,
			contentType: 'application/json',
			body: JSON.stringify({ error: 'no_refresh_token', message: 'No refresh token found' })
		})
	);

	await page.goto('/auth/login');

	await expect(
		page.getByRole('heading', { level: 1, name: 'Sign in to your account' })
	).toBeVisible();
	await expect(page.getByRole('main')).toHaveCount(1);
	await expect(page).toHaveTitle('Sign in | Template App');

	const username = page.getByLabel('Username');
	const password = page.getByLabel('Password');
	await username.focus();
	await page.keyboard.press('Tab');
	await expect(password).toBeFocused();
});

test('signing in lands on the authenticated home page', async ({ page }) => {
	// No existing session on load.
	await page.route('**/auth/refresh', (route) =>
		route.fulfill({
			status: 401,
			contentType: 'application/json',
			body: JSON.stringify({ error: 'no_refresh_token', message: 'No refresh token found' })
		})
	);

	// Valid login.
	await page.route('**/auth/login', (route) =>
		route.fulfill({
			status: 200,
			contentType: 'application/json',
			body: JSON.stringify({ access_token: 'e2e-access-token', expires_in: 900, user: userDto })
		})
	);

	// Start at home and client-route to login through the UI. (Navigating
	// directly to /auth/login would collide with the mocked POST /auth/login.)
	await page.goto('/');
	await page.getByRole('link', { name: 'Sign In' }).click();

	await page.getByLabel('Username').fill('alice');
	await page.getByLabel('Password').fill('password123');
	await page.getByRole('button', { name: 'Sign in' }).click();

	// Landed on the home page, signed in as alice.
	await expect(page.getByRole('heading', { name: 'Welcome to the App' })).toBeVisible();
	await expect(page.getByText('Hello,')).toContainText('alice');
});
