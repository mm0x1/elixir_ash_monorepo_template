defmodule TemplateAppWeb.Router.Routes do
  use TemplateAppWeb, :verified_routes

  def sign_in_path do
    ~p"/auth/sign-in"
  end

  def sign_out_path do
    ~p"/auth/session/sign-out"
  end

  def registration_path do
    ~p"/auth/registration/new"
  end

  def home_path do
    ~p"/"
  end

  def profile_path do
    ~p"/profile"
  end

  def auth_complete_path do
    ~p"/auth/complete"
  end
end
