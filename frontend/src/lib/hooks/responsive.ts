import { useMediaQuery } from 'usehooks-ts';
import { breakpoints } from './breakpoints';

export function useIsMobile(): boolean {
  return !useMediaQuery(breakpoints.md);
}

export function useIsDesktop(): boolean {
  return useMediaQuery(breakpoints.lg);
}
