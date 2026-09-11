defmodule TemplateAppWeb.FrontendControllerTest do
  use ExUnit.Case, async: true

  alias TemplateAppWeb.FrontendController

  test "hashes inline bootstrap scripts without allowing unsafe inline code" do
    html = "<script>window.__boot__ = true;</script>"
    policy = FrontendController.content_security_policy(html)

    assert policy =~ "script-src 'self' 'sha256-"
    assert policy =~ "style-src 'self'"
    refute policy =~ "unsafe-inline"
  end
end
