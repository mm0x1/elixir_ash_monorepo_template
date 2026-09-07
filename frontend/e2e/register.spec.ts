import { expect, test } from '@playwright/test';
import { userDto } from '../tests/support/fixtures';

test.beforeEach(async ({ page }) => {
	await page.route('**/auth/refresh', (route) =>
		route.fulfill({
			status: 401,
			contentType: 'application/json',
			body: JSON.stringify({ error: 'no_refresh_token', message: 'No refresh token found' })
		})
	);
});

test('registering a new account lands on the home page', async ({ page }) => {
	await page.route('**/auth/register', (route) => {
		if (route.request().resourceType() === 'document') return route.continue();

		return route.fulfill({
			status: 201,
			contentType: 'application/json',
			body: JSON.stringify({
				access_token: 'e2e-access-token',
				expires_in: 900,
				user: { ...userDto, username: 'newuser' }
			})
		});
	});

	await page.goto('/auth/register');
	await page.getByLabel('Username').fill('newuser');
	await page.getByLabel('Password', { exact: true }).fill('password123');
	await page.getByLabel('Confirm Password').fill('password123');
	await page.getByRole('button', { name: 'Create account' }).click();

	await expect(page.getByRole('heading', { name: 'Welcome to the App' })).toBeVisible();
	await expect(page.getByText('Hello,')).toContainText('newuser');
});

test('registration with a taken username shows an error', async ({ page }) => {
	await page.route('**/auth/register', (route) => {
		if (route.request().resourceType() === 'document') return route.continue();

		return route.fulfill({
			status: 422,
			contentType: 'application/json',
			body: JSON.stringify({
				error: 'validation_error',
				message: 'has already been taken',
				errors: [{ field: 'username', message: 'has already been taken' }]
			})
		});
	});

	await page.goto('/auth/register');
	await page.getByLabel('Username').fill('taken');
	await page.getByLabel('Password', { exact: true }).fill('password123');
	await page.getByLabel('Confirm Password').fill('password123');
	await page.getByRole('button', { name: 'Create account' }).click();

	await expect(page.getByText('has already been taken')).toBeVisible();
});
