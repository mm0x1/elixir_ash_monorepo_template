import { AbilityContext } from "./AbilityContext";
import { defineAbilityFor, AppAbility } from "./defineAbility";
import { useTypedPage } from "@/lib/inertia";
import type { BasePageProps } from "@/lib/inertia";

/**
 * Provides CASL ability to the entire application.
 * Wraps the app and automatically updates when current_user changes.
 */
export function AbilityProvider({ children }: { children: React.ReactNode }) {
  const page = useTypedPage<BasePageProps>();
  const current_user = page.props.current_user;

  const ability = new AppAbility(defineAbilityFor(current_user || null));

  return (
    <AbilityContext.Provider value={ability}>
      {children}
    </AbilityContext.Provider>
  );
}
