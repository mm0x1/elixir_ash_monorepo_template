import { createContext } from "react";
import type { AppAbility } from "./defineAbility";

/**
 * React context for providing CASL ability throughout the app.
 */
export const AbilityContext = createContext<AppAbility | null>(null);
