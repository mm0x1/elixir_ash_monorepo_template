<script lang="ts">
	type FormAlertProps = {
		readonly message: string;
		readonly variant?: 'error' | 'success';
		readonly id?: string;
		readonly live?: 'polite' | 'assertive';
	};

	let { message, variant = 'error', id = 'form-alert', live }: FormAlertProps = $props();
	let liveMode = $derived(live ?? (variant === 'error' ? 'assertive' : 'polite'));

	const styles = {
		error: 'bg-red-50 border border-red-200 text-red-700',
		success: 'bg-green-50 border border-green-200 text-green-700'
	} as const;
</script>

<div
	{id}
	class="{styles[variant]} px-4 py-3 rounded"
	role={variant === 'error' ? 'alert' : 'status'}
	aria-live={liveMode}
	aria-atomic="true"
>
	{message}
</div>
