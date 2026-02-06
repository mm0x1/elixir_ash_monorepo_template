/**
 * Permission system using CASL for role-based access control.
 *
 * @example Basic usage in a component
 * import { useAppAbility } from "@/lib/permissions";
 *
 * function MyComponent() {
 *   const ability = useAppAbility();
 *
 *   if (!ability.canAccessAdminPanel()) {
 *     return <NotAuthorized />;
 *   }
 *
 *   return <div>Admin content</div>;
 * }
 *
 * @example Using the Can component
 * import { Can } from "@/lib/permissions";
 *
 * <Can I="canAccessAdminPanel">
 *   <AdminButton />
 * </Can>
 */

export { useAppAbility } from "./useAppAbility";
export { Can } from "./Can";
export { AbilityProvider } from "./AbilityProvider";
export type { AppUser, UserRole } from "./defineAbility";
