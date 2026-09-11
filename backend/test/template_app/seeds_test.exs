Code.require_file(Path.expand("../../priv/repo/seeds.exs", __DIR__))

defmodule TemplateApp.SeedsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  test "privileged seeds require both development environment and explicit configuration" do
    assert Seeder.privileged_seeds_allowed?(:dev, true)

    refute Seeder.privileged_seeds_allowed?(:dev, false)
    refute Seeder.privileged_seeds_allowed?(:test, true)
    refute Seeder.privileged_seeds_allowed?(:prod, true)
  end

  test "test configuration skips predictable privileged accounts" do
    log = capture_log(fn -> assert :ok = Seeder.run() end)

    assert log =~ "Privileged development seeds skipped"
    refute log =~ "password123"
    refute log =~ "superadmin"
  end
end
