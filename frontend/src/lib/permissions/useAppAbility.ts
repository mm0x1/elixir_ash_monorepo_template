import { useContext } from "react";
import { AbilityContext } from "./AbilityContext";

/**
 * Hook to access the CASL ability instance.
 * Provides type-safe permission checking with autocomplete.
 *
 * @example
 * const ability = useAppAbility();
 * if (ability.canAccessAdminPanel()) {
 *   // Show admin button
 * }
 */
export function useAppAbility() {
  const ability = useContext(AbilityContext);

  if (!ability) {
    throw new Error("useAppAbility must be used within AbilityProvider");
  }

  return ability;
}
