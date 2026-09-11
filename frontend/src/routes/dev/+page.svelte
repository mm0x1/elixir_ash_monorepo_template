<script lang="ts">
	import { resolve } from '$app/paths';

	// /dev — component development index.
	//
	// Convention: each subroute under /dev mounts a single component in isolation
	// against hand-written mock data (no network, no auth) so it can be developed
	// and visually checked on its own. Add a new entry here when you add a sandbox.
	const sandboxes = [{ path: '/dev/notifications', label: 'Notifications (toasts)' }] as const;
</script>

<svelte:head>
	<title>Component dev | Template App</title>
</svelte:head>

<div class="mx-auto max-w-2xl p-8">
	<h1 class="mb-2 text-2xl font-bold">Component Dev</h1>
	<p class="mb-6 text-sm text-gray-600">
		Isolated component sandboxes. Each renders one component against mock data.
	</p>

	<ul class="flex flex-col gap-2">
		{#each sandboxes as sandbox (sandbox.path)}
			<li>
				<a class="text-blue-600 hover:underline" href={resolve(sandbox.path)}>
					{sandbox.label}
				</a>
			</li>
		{/each}
	</ul>
</div>
