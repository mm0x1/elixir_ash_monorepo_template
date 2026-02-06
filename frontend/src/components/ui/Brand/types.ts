export interface BrandProps {
  brandName?: string;
  size?: 'small' | 'normal' | 'large';
  onClick?: () => void;
  className?: string;
}
