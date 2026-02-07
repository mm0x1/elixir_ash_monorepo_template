# Test Environment Setup
#
# This file is automatically loaded before all tests. It:
# - Starts ExUnit for test execution
# - Configures Ecto.Adapters.SQL.Sandbox for concurrent database access
# - Sets up Mox to mock external HTTP clients (prevents real API calls during tests)
#
# System users are created in DataCase setup for each test's sandbox
#
# See: https://hexdocs.pm/ex_unit/ExUnit.html

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(TemplateApp.Repo, :manual)

# Configure application to use mock in tests
Application.put_env(:template_app, :http_client, ReqMock)
