import { useTypedPage, type BasePageProps } from "@/lib/inertia";

/**
 * Hook to access application configuration from Inertia props.
 * Configuration comes from the backend as the single source of truth.
 *
 * @example
 * const config = useAppConfig();
 * console.log(config.name); // "My App"
 */
export function useAppConfig() {
  const page = useTypedPage<BasePageProps>();
  return page.props.app_config;
}

/**
 * Generate page title with app name suffix.
 *
 * @example
 * getPageTitle("Dashboard") // "Dashboard - My App"
 * getPageTitle() // "My App"
 */
export function getPageTitle(pageTitle?: string, appName?: string): string {
  const suffix = appName || "App";
  return pageTitle ? `${pageTitle} - ${suffix}` : suffix;
}

/**
 * Get current year for copyright notices.
 */
export function getCurrentYear(): number {
  return new Date().getFullYear();
}

/**
 * Default meta tags (used in layouts).
 * Note: Actual values come from backend via Inertia props.
 */
export const defaultMeta = {
  keywords: "saas, application, phoenix, ash, react, typescript, inertia",
} as const;
