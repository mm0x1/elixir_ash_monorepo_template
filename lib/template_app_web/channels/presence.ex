defmodule TemplateAppWeb.Presence do
  @moduledoc """
  Provides presence tracking for channels.

  Tracks which users are online and broadcasts presence updates
  to connected clients.

  ## Frontend Usage

  ```javascript
  import { Presence } from "phoenix";

  const channel = socket.channel("notifications:" + userId, {});
  const presence = new Presence(channel);

  // Handle initial presence state
  presence.onSync(() => {
    const users = presence.list();
    console.log("Online users:", users);
  });

  // Handle presence joins
  presence.onJoin((id, current, newPres) => {
    console.log("User joined:", id, newPres);
  });

  // Handle presence leaves
  presence.onLeave((id, current, leftPres) => {
    console.log("User left:", id, leftPres);
  });
  ```

  ## Backend Usage

  Presence is automatically tracked when users join notification channels.
  You can also query presence programmatically:

  ```elixir
  # Get all online users in a channel
  TemplateAppWeb.Presence.list("notifications:\#{user_id}")

  # Track custom presence data
  TemplateAppWeb.Presence.track(socket, user_id, %{
    online_at: DateTime.utc_now() |> DateTime.to_iso8601(),
    status: "active"
  })
  ```
  """

  use Phoenix.Presence,
    otp_app: :template_app,
    pubsub_server: TemplateApp.PubSub

  @doc """
  Fetches presence data, called when listing presences.

  Override this to customize how presence data is returned.
  The default implementation returns the metas unchanged.
  """
  def fetch(_topic, presences) do
    presences
  end

  @doc """
  Gets all online user IDs from presence.

  ## Example

      online_ids = Presence.online_user_ids("notifications:user_123")
      # => ["user_456", "user_789"]
  """
  def online_user_ids(topic) do
    topic
    |> list()
    |> Map.keys()
  end

  @doc """
  Checks if a specific user is online in a topic.

  ## Example

      if Presence.user_online?("notifications:some_topic", user_id) do
        # User is connected
      end
  """
  def user_online?(topic, user_id) do
    topic
    |> list()
    |> Map.has_key?(user_id)
  end
end
