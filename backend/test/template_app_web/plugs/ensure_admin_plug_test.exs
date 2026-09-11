defmodule TemplateAppWeb.Plugs.EnsureAdminPlugTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Phoenix.ConnTest

  alias TemplateAppWeb.Plugs.EnsureAdminPlug

  for role <- [:admin, :superadmin] do
    test "#{role} may enter the local admin surface" do
      conn =
        build_conn()
        |> assign(:current_user, %{role: unquote(role)})
        |> EnsureAdminPlug.call([])

      refute conn.halted
      assert conn.status == nil
    end
  end

  test "ordinary users receive a JSON forbidden response" do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> assign(:current_user, %{role: :user})
      |> EnsureAdminPlug.call([])

    assert conn.halted
    assert conn.status == 403
    assert Jason.decode!(conn.resp_body) == %{"error" => "Forbidden"}
  end
end
