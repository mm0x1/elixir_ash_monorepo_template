/**
 * Access token store - isolated so both client.ts and store.ts can import it
 * without creating a circular dependency between those two modules.
 */

import { writable } from 'svelte/store';

export const accessToken = writable<string | null>(null);
