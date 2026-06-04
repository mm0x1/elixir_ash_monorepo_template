/**
 * MSW node server used by the integration tier. Lifecycle is wired in
 * `setup-client.ts`; individual tests append per-case handlers with
 * `server.use(...)`.
 */

import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
