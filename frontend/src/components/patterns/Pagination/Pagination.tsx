import { cn } from '@/utils/cn';
import { Button } from '@/components/ui';
import type { PaginationProps } from './types';

export function Pagination({
  meta,
  onPageChange,
  disabled = false,
  showPageInfo = true,
  className,
}: PaginationProps) {
  const { offset, limit, count, has_more } = meta;
  const totalPages = Math.ceil(count / limit);
  const hasPrev = offset > 0;
  const hasNext = has_more;

  const handlePrev = () => {
    if (hasPrev) {
      onPageChange(Math.max(0, offset - limit));
    }
  };

  const handleNext = () => {
    if (hasNext) {
      onPageChange(offset + limit);
    }
  };

  if (totalPages <= 1) {
    return null;
  }

  return (
    <nav
      className={cn(className)}
      aria-label="Pagination"
    >
      {showPageInfo && (
        <div>
          Showing <span>{offset + 1}</span> to{' '}
          <span>{Math.min(offset + limit, count)}</span>{' '}
          of <span>{count}</span> results
        </div>
      )}
      <div>
        <Button
          variant="secondary"
          size="sm"
          onClick={handlePrev}
          disabled={disabled || !hasPrev}
          aria-label="Previous page"
        >
          Previous
        </Button>
        <Button
          variant="secondary"
          size="sm"
          onClick={handleNext}
          disabled={disabled || !hasNext}
          aria-label="Next page"
        >
          Next
        </Button>
      </div>
    </nav>
  );
}
