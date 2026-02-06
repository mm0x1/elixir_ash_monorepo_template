export interface PaginationMeta {
  offset: number;
  limit: number;
  count: number;
  has_more: boolean;
}

export interface PaginationProps {
  meta: PaginationMeta;
  onPageChange: (offset: number) => void;
  disabled?: boolean;
  showPageInfo?: boolean;
  className?: string;
}
