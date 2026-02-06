import { AbilityBuilder, createMongoAbility } from "@casl/ability";

export type UserRole = "user" | "admin" | "superadmin";

export interface AppUser {
  id: string;
  role: UserRole;
}

/**
 * Define permissions using CASL based on user role.
 * This is the single source of truth for all permissions in the app.
 */
export function defineAbilityFor(user: AppUser | null) {
  const { can, build } = new AbilityBuilder(createMongoAbility);

  if (!user) {
    return build();
  }

  // Base permissions - everyone can manage their own profile
  can("read", "Profile", { userId: user.id });
  can("update", "Profile", { userId: user.id });
  can("regenerate", "RecoveryCodes"); // Own recovery codes

  // Admin permissions
  if (user.role === "admin" || user.role === "superadmin") {
    can("read", "User");
    can("create", "User");
    can("update", "User");
    can("access", "AdminPanel");
    can("view", "UserList");
  }

  // Superadmin only
  if (user.role === "superadmin") {
    can("delete", "User");
    can("manage", "Setting"); // System settings
    can("manage", "all"); // Everything
  }

  return build();
}

/**
 * Typed wrapper with explicit methods for type-safe permission checks.
 * Define permissions once here, use everywhere with autocomplete.
 */
export class AppAbility {
  constructor(private ability: ReturnType<typeof defineAbilityFor>) {}

  // User management
  canReadUser = () => this.ability.can("read", "User");
  canCreateUser = () => this.ability.can("create", "User");
  canUpdateUser = (user?: { id: string }) =>
    this.ability.can("update", "User", user as never);
  canDeleteUser = (user?: { id: string }) =>
    this.ability.can("delete", "User", user as never);

  // Profile management
  canReadProfile = (profile: { userId: string }) =>
    this.ability.can("read", "Profile", profile as never);
  canUpdateProfile = (profile: { userId: string }) =>
    this.ability.can("update", "Profile", profile as never);

  // Admin panel
  canAccessAdminPanel = () => this.ability.can("access", "AdminPanel");
  canViewUserList = () => this.ability.can("view", "UserList");

  // Recovery codes
  canRegenerateRecoveryCodes = () =>
    this.ability.can("regenerate", "RecoveryCodes");

  // Settings
  canManageSettings = () => this.ability.can("manage", "Setting");

  // Role helpers
  isAdmin = () => this.ability.can("access", "AdminPanel");
  isSuperadmin = () => this.ability.can("manage", "all");

  // Generic fallback (use sparingly)
  can = (action: string, subject: string, field?: unknown) =>
    this.ability.can(action, subject, field as never);
}
