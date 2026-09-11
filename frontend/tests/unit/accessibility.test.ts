import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import FormAlert from '../../src/lib/shared/components/FormAlert.svelte';
import ButtonSpinner from '../../src/lib/shared/components/ButtonSpinner.svelte';

describe('shared accessibility components', () => {
	it('renders stable alert IDs and live-region semantics', () => {
		render(FormAlert, {
			props: { id: 'profile-form-error', message: 'Username is invalid' }
		});

		const alert = screen.getByRole('alert');
		expect(alert).toHaveAttribute('id', 'profile-form-error');
		expect(alert).toHaveAttribute('aria-live', 'assertive');
		expect(alert).toHaveAttribute('aria-atomic', 'true');
	});

	it('hides the decorative button spinner from assistive technology', () => {
		render(ButtonSpinner);

		const spinner = document.querySelector('svg');
		expect(spinner).toHaveAttribute('aria-hidden', 'true');
		expect(spinner).toHaveAttribute('focusable', 'false');
	});
});
