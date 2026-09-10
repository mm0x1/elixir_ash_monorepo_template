# Backend Agent Guide

Applies to `backend/` and its descendants. Shared monorepo rules live in `../AGENTS.md`; read that file before backend work. `CLAUDE.md` in this directory is a symlink to this file.

Phoenix 1.8 + Ash 3.x REST/JSON API (no RPC layer), with PostgreSQL through AshPostgres.

## Commands

Run these from `backend/`:

```bash
mix setup                         # local dependencies, database setup, and development seeds
mix phx.server                    # API on 127.0.0.1:4000
mix quality                       # format check, Credo, and warnings-as-errors compilation
mix codegen.dev                   # iterate on Ash changes with development migration artifacts
mix ash.codegen add_descriptive_name
mix codegen.check                 # verify resources, migrations, and snapshots are synchronized
mix ash.migrate                   # apply reviewed migrations
mix sobelow --skip                # security scan; review findings rather than ignoring them
mix test                          # database-backed tests; PostgreSQL must be running
```

After changing Ash resources, use `mix codegen.dev` during iteration. Review the generated migration and resource snapshot, apply reviewed development migrations with `mix ash.migrate`, and finish with a named `mix ash.codegen add_descriptive_name` plus `mix codegen.check`.

## Package Usage Rules

The generated section below is maintained by `usage_rules` and must not be edited manually. The configuration in `mix.exs` is the source of truth:

```bash
mix usage_rules.sync
mix usage_rules.sync --check
```

The generated rules are package reference material. Project-specific rules in this prelude and `../AGENTS.md` take precedence over generic package examples. Follow linked package references when an Ash or extension API is relevant.

## Authentication Contract

- The REST API authenticates with username/password actions and custom short-lived Joken bearer access tokens; the identity field is username, not email.
- Access tokens last 15 minutes, contain the user id and token version, and are checked against current database state on authenticated requests.
- Refresh tokens last seven days, are database-backed, live in an HttpOnly cookie, rotate during refresh, and are removed by logout. Logout-all increments the user token version.
- Device logout is cookie-based and remains available when the short-lived access token has expired. Logout-all still requires an authenticated access token.
- Recovery codes are one-time credentials for password reset. They are stored hashed and are revealed only by the explicit recovery-code generation response.
- Recovery codes are generated only by an authenticated account action. There is no username-only reset request, email delivery, or self-service recovery path after all stored codes are lost.
- The development `/dev` and `/admin` browser surface uses a separate AshAuthentication browser session. Do not treat it as the bearer-token REST API.

## Ash and Web Rules

- Every Ash operation must have the correct actor. `ValidateAccessToken` must call `Ash.PlugHelpers.set_actor(conn, user)`, not merely assign the user to the connection.
- Ash policies are deny-by-default. Allow each action explicitly; use `action_type(:read)` when named read actions must be covered.
- Never derive `authorize?: false` from request input or use it to repair a policy failure. Reserve bypasses for documented AshAuthentication internals, narrowly scoped internal operations, seeds, or tests.
- Prefer named Ash actions and domain code interfaces over generic CRUD calls from web modules.
- Never put raw Ash structs in JSON responses. Use explicit serializers.
- REST controller success and domain-error responses use `TemplateAppWeb.Helpers.ApiResponse`. Health checks, authentication/rate-limit plugs, browser routes, and development/admin routes are intentional direct-response exceptions.
- Review both `priv/repo/migrations/` and `priv/resource_snapshots/` after code generation before applying or committing changes.

## Local-Only Operations

- `mix setup` runs dependency setup, creates/migrates the configured database, and executes development seeds with predictable credentials. Verify the environment and database target first; never run it against production or a shared database.
- Tidewave at `/tidewave/mcp` provides privileged IEx and SQL access to the running development app. It must remain local-development-only and must never be pointed at production or sensitive shared data.
- Do not commit `.env`, generated secrets, database dumps, or seed credentials intended only for local development.

## Testing

- Exercise real Ash actions and controllers against the Ecto sandbox; do not mock the code under test.
- `TemplateApp.DataCase` uses a shared sandbox for non-async tests. Controller tests that spawn Ash processes or exercise bulk updates or relationship management use `async: false` when required by the sandbox setup.
- Use globally unique identity values in concurrent tests to avoid database identity deadlocks.
- Run focused tests during iteration and `mix test` before completing backend changes. Do not run watch-mode tests as agent verification.

## Documentation

| File | Purpose |
|------|---------|
| `../AGENTS.md` | Shared monorepo and cross-stack contract |
| `AGENTS.md` (`CLAUDE.md -> AGENTS.md`) | Backend commands, security boundaries, and project-specific rules |
| `mix.exs` | Dependency, alias, and usage-rules configuration |
| `priv/repo/migrations/` | Reviewed database migrations |
| `priv/resource_snapshots/` | Ash resource snapshots synchronized by code generation |

<!-- usage-rules-start -->
<!-- usage_rules-start -->
## usage_rules usage
_A config-driven dev tool for Elixir projects to manage AGENTS.md files and agent skills from dependencies_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best 
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies
- `%{}` matches ANY map, not just empty maps. Use `map_size(map) == 0` guard to check for truly empty maps

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark.
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, use `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- ash-start -->
## ash usage
_A declarative, extensible framework for building Elixir applications._

# Rules for working with Ash

## Understanding Ash

Ash is an opinionated, composable framework for building applications in Elixir. It provides a declarative approach to modeling your domain with resources at the center. Read documentation  *before* attempting to use its features. Do not assume that you have prior knowledge of the framework or its conventions.


<!-- ash-end -->
<!-- ash:actions-start -->
## ash:actions usage
[ash:actions usage rules](deps/ash/usage-rules/actions.md)
<!-- ash:actions-end -->
<!-- ash:aggregates-start -->
## ash:aggregates usage
[ash:aggregates usage rules](deps/ash/usage-rules/aggregates.md)
<!-- ash:aggregates-end -->
<!-- ash:authorization-start -->
## ash:authorization usage
[ash:authorization usage rules](deps/ash/usage-rules/authorization.md)
<!-- ash:authorization-end -->
<!-- ash:calculations-start -->
## ash:calculations usage
[ash:calculations usage rules](deps/ash/usage-rules/calculations.md)
<!-- ash:calculations-end -->
<!-- ash:code_interfaces-start -->
## ash:code_interfaces usage
[ash:code_interfaces usage rules](deps/ash/usage-rules/code_interfaces.md)
<!-- ash:code_interfaces-end -->
<!-- ash:code_structure-start -->
## ash:code_structure usage
[ash:code_structure usage rules](deps/ash/usage-rules/code_structure.md)
<!-- ash:code_structure-end -->
<!-- ash:data_layers-start -->
## ash:data_layers usage
[ash:data_layers usage rules](deps/ash/usage-rules/data_layers.md)
<!-- ash:data_layers-end -->
<!-- ash:exist_expressions-start -->
## ash:exist_expressions usage
[ash:exist_expressions usage rules](deps/ash/usage-rules/exist_expressions.md)
<!-- ash:exist_expressions-end -->
<!-- ash:generating_code-start -->
## ash:generating_code usage
[ash:generating_code usage rules](deps/ash/usage-rules/generating_code.md)
<!-- ash:generating_code-end -->
<!-- ash:migrations-start -->
## ash:migrations usage
[ash:migrations usage rules](deps/ash/usage-rules/migrations.md)
<!-- ash:migrations-end -->
<!-- ash:query_filter-start -->
## ash:query_filter usage
[ash:query_filter usage rules](deps/ash/usage-rules/query_filter.md)
<!-- ash:query_filter-end -->
<!-- ash:querying_data-start -->
## ash:querying_data usage
[ash:querying_data usage rules](deps/ash/usage-rules/querying_data.md)
<!-- ash:querying_data-end -->
<!-- ash:relationships-start -->
## ash:relationships usage
[ash:relationships usage rules](deps/ash/usage-rules/relationships.md)
<!-- ash:relationships-end -->
<!-- ash:testing-start -->
## ash:testing usage
[ash:testing usage rules](deps/ash/usage-rules/testing.md)
<!-- ash:testing-end -->
<!-- ash_authentication-start -->
## ash_authentication usage
_Authentication extension for the Ash Framework._

[ash_authentication usage rules](deps/ash_authentication/usage-rules.md)
<!-- ash_authentication-end -->
<!-- ash_phoenix-start -->
## ash_phoenix usage
_Utilities for integrating Ash and Phoenix_

[ash_phoenix usage rules](deps/ash_phoenix/usage-rules.md)
<!-- ash_phoenix-end -->
<!-- ash_phoenix:best_practices-start -->
## ash_phoenix:best_practices usage
[ash_phoenix:best_practices usage rules](deps/ash_phoenix/usage-rules/best_practices.md)
<!-- ash_phoenix:best_practices-end -->
<!-- ash_phoenix:debugging_form_submissions-start -->
## ash_phoenix:debugging_form_submissions usage
[ash_phoenix:debugging_form_submissions usage rules](deps/ash_phoenix/usage-rules/debugging_form_submissions.md)
<!-- ash_phoenix:debugging_form_submissions-end -->
<!-- ash_phoenix:error_handling-start -->
## ash_phoenix:error_handling usage
[ash_phoenix:error_handling usage rules](deps/ash_phoenix/usage-rules/error_handling.md)
<!-- ash_phoenix:error_handling-end -->
<!-- ash_phoenix:form_integration-start -->
## ash_phoenix:form_integration usage
[ash_phoenix:form_integration usage rules](deps/ash_phoenix/usage-rules/form_integration.md)
<!-- ash_phoenix:form_integration-end -->
<!-- ash_phoenix:nested_forms-start -->
## ash_phoenix:nested_forms usage
[ash_phoenix:nested_forms usage rules](deps/ash_phoenix/usage-rules/nested_forms.md)
<!-- ash_phoenix:nested_forms-end -->
<!-- ash_phoenix:union_forms-start -->
## ash_phoenix:union_forms usage
[ash_phoenix:union_forms usage rules](deps/ash_phoenix/usage-rules/union_forms.md)
<!-- ash_phoenix:union_forms-end -->
<!-- ash_postgres-start -->
## ash_postgres usage
_The PostgreSQL data layer for Ash Framework_

[ash_postgres usage rules](deps/ash_postgres/usage-rules.md)
<!-- ash_postgres-end -->
<!-- ash_postgres:advanced_features-start -->
## ash_postgres:advanced_features usage
[ash_postgres:advanced_features usage rules](deps/ash_postgres/usage-rules/advanced_features.md)
<!-- ash_postgres:advanced_features-end -->
<!-- ash_postgres:best_practices-start -->
## ash_postgres:best_practices usage
[ash_postgres:best_practices usage rules](deps/ash_postgres/usage-rules/best_practices.md)
<!-- ash_postgres:best_practices-end -->
<!-- ash_postgres:check_constraints-start -->
## ash_postgres:check_constraints usage
[ash_postgres:check_constraints usage rules](deps/ash_postgres/usage-rules/check_constraints.md)
<!-- ash_postgres:check_constraints-end -->
<!-- ash_postgres:configuration-start -->
## ash_postgres:configuration usage
[ash_postgres:configuration usage rules](deps/ash_postgres/usage-rules/configuration.md)
<!-- ash_postgres:configuration-end -->
<!-- ash_postgres:custom_indexes-start -->
## ash_postgres:custom_indexes usage
[ash_postgres:custom_indexes usage rules](deps/ash_postgres/usage-rules/custom_indexes.md)
<!-- ash_postgres:custom_indexes-end -->
<!-- ash_postgres:custom_sql_statements-start -->
## ash_postgres:custom_sql_statements usage
[ash_postgres:custom_sql_statements usage rules](deps/ash_postgres/usage-rules/custom_sql_statements.md)
<!-- ash_postgres:custom_sql_statements-end -->
<!-- ash_postgres:foreign_keys-start -->
## ash_postgres:foreign_keys usage
[ash_postgres:foreign_keys usage rules](deps/ash_postgres/usage-rules/foreign_keys.md)
<!-- ash_postgres:foreign_keys-end -->
<!-- ash_postgres:migrations-start -->
## ash_postgres:migrations usage
[ash_postgres:migrations usage rules](deps/ash_postgres/usage-rules/migrations.md)
<!-- ash_postgres:migrations-end -->
<!-- ash_postgres:multitenancy-start -->
## ash_postgres:multitenancy usage
[ash_postgres:multitenancy usage rules](deps/ash_postgres/usage-rules/multitenancy.md)
<!-- ash_postgres:multitenancy-end -->
<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

# Rules for working with Igniter

## Understanding Igniter

Igniter is a code generation and project patching framework that enables semantic manipulation of Elixir codebases. It provides tools for creating intelligent generators that can both create new files and modify existing ones safely. Igniter works with AST (Abstract Syntax Trees) through Sourceror.Zipper to make precise, context-aware changes to your code.

## Available Modules

### Project-Level Modules (`Igniter.Project.*`)

- **`Igniter.Project.Application`** - Working with Application modules and application configuration
- **`Igniter.Project.Config`** - Modifying Elixir config files (config.exs, runtime.exs, etc.)
- **`Igniter.Project.Deps`** - Managing dependencies declared in mix.exs
- **`Igniter.Project.Formatter`** - Interacting with .formatter.exs files
- **`Igniter.Project.IgniterConfig`** - Managing .igniter.exs configuration files
- **`Igniter.Project.MixProject`** - Updating project configuration in mix.exs
- **`Igniter.Project.Module`** - Creating and managing modules with proper file placement
- **`Igniter.Project.TaskAliases`** - Managing task aliases in mix.exs
- **`Igniter.Project.Test`** - Working with test and test support files

### Code-Level Modules (`Igniter.Code.*`)

- **`Igniter.Code.Common`** - General purpose utilities for working with Sourceror.Zipper
- **`Igniter.Code.Function`** - Working with function definitions and calls
- **`Igniter.Code.Keyword`** - Manipulating keyword lists
- **`Igniter.Code.List`** - Working with lists in AST
- **`Igniter.Code.Map`** - Manipulating maps
- **`Igniter.Code.Module`** - Working with module definitions and usage
- **`Igniter.Code.String`** - Utilities for string literals
- **`Igniter.Code.Tuple`** - Working with tuples

<!-- igniter-end -->
<!-- usage-rules-end -->
