<script lang="ts">
	let {
		message,
		variant = 'error'
	}: { message: string; variant?: 'error' | 'success' } = $props();

	const styles = {
		error: 'bg-red-50 border border-red-200 text-red-700',
		success: 'bg-green-50 border border-green-200 text-green-700'
	} as const;
</script>

<div
	class="{styles[variant]} px-4 py-3 rounded"
	role={variant === 'error' ? 'alert' : 'status'}
>
	{message}
</div>
