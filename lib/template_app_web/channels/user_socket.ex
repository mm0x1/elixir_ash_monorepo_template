defmodule TemplateAppWeb.UserSocket do
  @moduledoc """
  Socket for authenticated user connections.

  Authenticates users via JWT token passed during socket connection.
  The token should be obtained from the session and passed to the socket
  during JavaScript initialization.

  ## Frontend Usage

  ```javascript
  import { Socket } from "phoenix";

  // Token should be passed from the page props or fetched from session
  const socket = new Socket("/socket", {
    params: { token: window.userToken }
  });

  socket.connect();

  const channel = socket.channel("notifications:" + userId, {});
  channel.join()
    .receive("ok", resp => console.log("Joined", resp))
    .receive("error", resp => console.log("Failed to join", resp));
  ```
  """

  use Phoenix.Socket

  alias TemplateApp.Domains.Accounts

  # Channels
  channel "notifications:*", TemplateAppWeb.NotificationChannel

  @doc """
  Authenticates the socket connection using a Phoenix.Token.

  The token is validated and the user is loaded from the database.
  """
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) when is_binary(token) do
    case verify_socket_token(token) do
      {:ok, user} ->
        {:ok, assign(socket, :current_user, user)}

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"

  @doc """
  Generates a socket token for a user.

  This should be called when rendering pages to provide the token
  for WebSocket authentication.

  Uses Phoenix.Token for socket authentication (separate from AshAuthentication JWTs).

  ## Example

      def show(conn, _params) do
        token = TemplateAppWeb.UserSocket.generate_token(conn.assigns.current_user)
        render_inertia(conn, "Dashboard", %{socket_token: token})
      end
  """
  def generate_token(nil), do: nil

  def generate_token(user) do
    # Use Phoenix.Token for socket auth - valid for 2 weeks
    Phoenix.Token.sign(
      TemplateAppWeb.Endpoint,
      "user socket",
      user.id
    )
  end

  @doc """
  Verifies a Phoenix.Token for socket authentication.
  """
  def verify_socket_token(token) do
    # Token valid for 2 weeks (in seconds)
    max_age = 14 * 24 * 60 * 60

    case Phoenix.Token.verify(TemplateAppWeb.Endpoint, "user socket", token, max_age: max_age) do
      {:ok, user_id} ->
        # Load the user by ID
        case Accounts.get_user_by_id(user_id) do
          {:ok, user} -> {:ok, user}
          _ -> {:error, :user_not_found}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
