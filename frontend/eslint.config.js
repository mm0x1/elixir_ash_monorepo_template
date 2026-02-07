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
	// API boundary enforcement: prevent direct imports from $lib/generated/
	// Only $lib/api/ is allowed to import from generated/
	{
		files: ['src/**/*.ts', 'src/**/*.svelte'],
		ignores: ['src/lib/api/**/*', 'src/lib/generated/**/*'],
		rules: {
			'no-restricted-imports': [
				'error',
				{
					patterns: [
						{
							group: ['$lib/generated/*', '**/generated/*'],
							message:
								'Import from $lib/api/ instead. Generated types must not leak outside the API boundary.'
						}
					]
				}
			]
		}
	},
	{
		ignores: ['build/', '.svelte-kit/', 'dist/', 'node_modules/', 'src/lib/generated/']
	}
);
