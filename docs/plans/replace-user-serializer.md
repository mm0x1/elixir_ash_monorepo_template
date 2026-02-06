# Plan: Replace UserSerializer with Typed Query-Aligned Serialization

## Goal

Replace the manual `UserSerializer` with a helper that derives its field list from the ash_typescript typed query definition, ensuring the Inertia props and RPC responses always produce identical shapes. Then delete the serializer.

## Context

- **UserSerializer** (5 call sites): `CurrentUserPropPlug` (1), `AuthApiController` (4: register, sign_in, create_anonymous, convert_to_registered)
- The typed query `:current_user` defines fields: `[:id, :username, :is_anonymous, :role, :has_recovery_codes, :recovery_codes_count]`
- `has_recovery_codes` and `recovery_codes_count` are Ash calculations that must be **loaded** before access
- `OutputFormatter` from ash_typescript operates on plain maps (not structs) — it's an internal module, so we'll avoid coupling to it. Instead, we'll use the same typed query field list and normalize values ourselves.
- Public attributes: `[:id, :username, :is_anonymous, :role]` — matches exactly
- Public calculations: `[:has_recovery_codes, :recovery_codes_count]` — matches exactly

## Steps

### 1. Create `TemplateAppWeb.Helpers.UserProps`

**File:** `lib/template_app_web/helpers/user_props.ex`

A small module with one public function, `serialize_current_user/1`:

```elixir
  defmodule TemplateAppWeb.Helpers.UserProps do
  @moduledoc """
  Serializes User structs to plain maps matching the ash_typescript
  typed query :current_user shape.
  """

  alias TemplateApp.Domains.Accounts.Resources.User

  @current_user_fields [:id, :username, :is_anonymous, :role, :has_recovery_codes, :recovery_codes_count]
  @calculations [:has_recovery_codes, :recovery_codes_count]

  def serialize_current_user(nil), do: nil

  def serialize_current_user(%User{} = user) do
    user
    |> Ash.load!(@calculations)
    |> Map.take(@current_user_fields)
    |> normalize_values()
  end

  defp normalize_values(map) do
    Map.new(map, fn
      {k, %Ash.CiString{} = v} -> {k, to_string(v)}
      {k, v} when is_atom(v) and not is_boolean(v) and not is_nil(v) -> {k, to_string(v)}
      {k, v} -> {k, v}
    end)
  end
end
```

Key design:
- Field list mirrors the typed query — if fields change in the domain, this list is updated alongside it
- `Ash.load!/2` fetches the calculations (hits DB for `array_length` fragments)
- `normalize_values/1` converts CiString→string and atom→string (role), matching what `ResultProcessor.normalize_primitive` does in the RPC path

### 2. Update `CurrentUserPropPlug`

**File:** `lib/template_app_web/plugs/current_user_prop_plug.ex`

- Replace `alias TemplateAppWeb.Serializers.UserSerializer` with `alias TemplateAppWeb.Helpers.UserProps`
- Change `UserSerializer.serialize(current_user)` → `UserProps.serialize_current_user(current_user)`

### 3. Update `AuthApiController`

**File:** `lib/template_app_web/controllers/auth_api_controller.ex`

- Replace `alias TemplateAppWeb.Serializers.UserSerializer` with `alias TemplateAppWeb.Helpers.UserProps`
- Change all 4 `UserSerializer.serialize(user)` / `UserSerializer.serialize(updated)` calls → `UserProps.serialize_current_user(user)` / `UserProps.serialize_current_user(updated)`
- Call sites: `register/2` (line 26), `sign_in/2` (line 48), `create_anonymous/2` (line 83), `convert_to_registered/2` (line 171)

### 4. Delete `UserSerializer` and its test

**Delete:** `lib/template_app_web/serializers/user_serializer.ex`
**Delete:** `test/template_app_web/serializers/user_serializer_test.exs`

Note: The test file references `is_admin`, `is_superadmin`, `permission_names` fields that don't exist in the current serializer — these tests were written for a future state that never materialized. Deleting is correct.

### 5. Add test for `UserProps.serialize_current_user/1`

**File:** `test/template_app_web/helpers/user_props_test.exs`

Test cases:
- `nil` → `nil`
- Registered user → map with correct 6 fields, `role` as string, `username` as string, no `hashed_password`
- User with recovery codes → `has_recovery_codes: true`, `recovery_codes_count > 0`
- Anonymous user → `is_anonymous: true`

## Files Modified

| File | Action |
|------|--------|
| `lib/template_app_web/helpers/user_props.ex` | **Create** |
| `lib/template_app_web/plugs/current_user_prop_plug.ex` | Edit (swap alias + call) |
| `lib/template_app_web/controllers/auth_api_controller.ex` | Edit (swap alias + 4 calls) |
| `lib/template_app_web/serializers/user_serializer.ex` | **Delete** |
| `test/template_app_web/serializers/user_serializer_test.exs` | **Delete** |
| `test/template_app_web/helpers/user_props_test.exs` | **Create** |

## Verification

1. `mix compile --warnings-as-errors` — no references to deleted serializer
2. `mix test test/template_app_web/helpers/user_props_test.exs` — new tests pass
3. `mix test` — full suite passes (no other consumers of UserSerializer)
4. `mix quality` — formatting, credo, lint all pass
5. Manual: start server, sign in → verify `current_user` prop in Inertia page has correct shape with `role` as string
