import eslint from '@eslint/js';
import prettier from 'eslint-config-prettier';
import svelte from 'eslint-plugin-svelte';
import ts from 'typescript-eslint';
import globals from 'globals';

export default ts.config(
	eslint.configs.recommended,
	...ts.configs.recommended,
	...svelte.configs.recommended,
	prettier,
	...svelte.configs.prettier,
	{
		languageOptions: {
			globals: {
				...globals.browser,
				...globals.node
			},
			parserOptions: {
				extraFileExtensions: ['.svelte'],
				parser: ts.parser
			}
		}
	},
	{
		files: ['**/*.svelte', '**/*.svelte.ts', '**/*.svelte.js'],
		languageOptions: {
			parserOptions: {
				parser: ts.parser
			}
		}
	},
	// Allow intentionally-unused identifiers when prefixed with an underscore
	// (e.g. placeholder parameters on stubbed API functions).
	{
		files: ['**/*.ts', '**/*.svelte'],
		rules: {
			'@typescript-eslint/no-unused-vars': [
				'error',
				{ argsIgnorePattern: '^_', varsIgnorePattern: '^_' }
			]
		}
	},
	// Layering boundary: shared/ is cross-cutting infrastructure and must never
	// depend on a feature. The dependency direction is features → shared, one way.
	{
		files: ['src/lib/shared/**/*.ts', 'src/lib/shared/**/*.svelte'],
		rules: {
			'no-restricted-imports': [
				'error',
				{
					patterns: [
						{
							group: ['$lib/features/*', '$lib/features/**'],
							message:
								'Shared code must not import from features/ — keep the dependency direction features → shared.'
						}
					]
				}
			]
		}
	},
	{
		ignores: ['build/', '.svelte-kit/', 'dist/', 'node_modules/']
	}
);
