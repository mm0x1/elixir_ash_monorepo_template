import { Button } from '@/components/ui/Button';

interface LoadMoreButtonProps {
  onClick: () => void;
  isLoading: boolean;
  children?: string;
}

export function LoadMoreButton({
  onClick,
  isLoading,
  children = 'Load More'
}: LoadMoreButtonProps) {
  return (
    <div className="flex justify-center py-4">
      <Button
        variant="ghost"
        onClick={onClick}
        loading={isLoading}
      >
        {children}
      </Button>
    </div>
  );
}
