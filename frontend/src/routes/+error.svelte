<script lang="ts">
	import { page } from '$app/state';
	import { resolve } from '$app/paths';
</script>

<div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4">
	<div class="text-center">
		<p class="text-6xl font-bold text-gray-300">{page.status}</p>
		<h1 class="mt-4 text-2xl font-semibold text-gray-900">
			{page.status === 404 ? 'Page not found' : 'Something went wrong'}
		</h1>
		<p class="mt-2 text-gray-600">
			{page.error?.message ?? 'The page you are looking for does not exist.'}
		</p>
		<a
			href={resolve('/')}
			class="mt-6 inline-block px-6 py-3 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
		>
			Go home
		</a>
	</div>
</div>
