defmodule TemplateAppWeb.Helpers.ResourcePreloads do
  @moduledoc """
  Common preload lists for Ash resources.

  Use these to ensure consistent relationship loading before serialization.

  ## Usage

      # In a controller
      user = Ash.load!(user, ResourcePreloads.user_with_permissions())
      UserSerializer.serialize(user)

  ## Adding New Preloads

  Define functions that return lists of atoms (relationship names):

      def post_with_author, do: [:author]
      def post_full, do: [:author, :comments, tags: [:category]]
  """

  @doc "Base user preloads - no relationships needed for basic serialization."
  def user, do: []

  @doc "User with permissions loaded."
  def user_with_permissions, do: [:permissions]
end
