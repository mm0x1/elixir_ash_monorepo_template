import { createServer } from 'node:http';
import { resolve } from 'node:path';
import sirv from 'sirv';

const host = process.env.HOST ?? '127.0.0.1';
const port = Number(process.env.PREVIEW_PORT ?? 4173);
const serve = sirv(resolve('build'), { dev: false, single: true });

createServer((request, response) => serve(request, response)).listen(port, host, () => {
	console.log(`SPA preview ready at http://${host}:${port}`);
});
