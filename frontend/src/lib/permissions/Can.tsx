import { useAppAbility } from "./useAppAbility";
import type { AppAbility } from "./defineAbility";

interface CanProps {
  /**
   * The method name on AppAbility to call (e.g., "canAccessAdminPanel", "canDeleteUser")
   */
  I: keyof AppAbility;
  /**
   * Optional subject to pass to the permission check method
   */
  this?: unknown;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

/**
 * Conditional rendering component based on permissions.
 *
 * @example
 * <Can I="canAccessAdminPanel">
 *   <AdminDashboard />
 * </Can>
 *
 * @example
 * <Can I="canDeleteUser" this={user}>
 *   <button onClick={deleteUser}>Delete</button>
 * </Can>
 */
export function Can({ I, this: subject, children, fallback = null }: CanProps) {
  const ability = useAppAbility();

  // Call the method on ability (e.g., ability.canAccessAdminPanel())
  const allowed =
    typeof ability[I] === "function"
      ? (ability[I] as (subject?: unknown) => boolean)(subject)
      : false;

  return allowed ? <>{children}</> : <>{fallback}</>;
}
