# Test Environment Setup
#
# This file is automatically loaded before all tests. It:
# - Starts ExUnit for test execution
# - Configures Ecto.Adapters.SQL.Sandbox for concurrent database access
#
# System users are created in DataCase setup for each test's sandbox
#
# See: https://hexdocs.pm/ex_unit/ExUnit.html

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(TemplateApp.Repo, :manual)
