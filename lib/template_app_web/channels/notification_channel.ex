defmodule TemplateAppWeb.NotificationChannel do
  @moduledoc """
  Channel for real-time user notifications.

  Users can only join their own notification channel (notifications:USER_ID).
  This channel can be used to push real-time notifications like:

  - New messages
  - System alerts
  - Activity updates
  - etc.

  ## Frontend Usage

  ```javascript
  const channel = socket.channel(`notifications:${userId}`, {});

  channel.join()
    .receive("ok", resp => console.log("Joined notifications"))
    .receive("error", resp => console.log("Failed to join"));

  channel.on("new_notification", payload => {
    console.log("New notification:", payload);
    // Add to notifications state, show toast, etc.
  });
  ```

  ## Broadcasting from Backend

  ```elixir
  # From anywhere in the application
  TemplateAppWeb.Endpoint.broadcast(
    "notifications:\#{user_id}",
    "new_notification",
    %{
      type: "info",
      message: "You have a new message",
      data: %{...}
    }
  )
  ```
  """

  use Phoenix.Channel

  require Logger

  @doc """
  Handles channel join requests.

  Users can only join their own notification channel.
  The topic must match "notifications:USER_ID" where USER_ID
  is the authenticated user's ID.
  """
  @impl true
  def join("notifications:" <> user_id, _payload, socket) do
    current_user = socket.assigns.current_user

    if user_id == current_user.id do
      send(self(), :after_join)
      {:ok, %{user_id: user_id}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Track user presence when they join
    if Code.ensure_loaded?(TemplateAppWeb.Presence) do
      {:ok, _} =
        TemplateAppWeb.Presence.track(socket, socket.assigns.current_user.id, %{
          online_at: DateTime.to_iso8601(DateTime.utc_now()),
          username: socket.assigns.current_user.username
        })

      push(socket, "presence_state", TemplateAppWeb.Presence.list(socket))
    end

    {:noreply, socket}
  end

  @doc """
  Handles incoming messages from the client.

  Currently supports:
  - "mark_read" - Mark notifications as read
  """
  @impl true
  def handle_in("mark_read", %{"notification_ids" => ids}, socket) when is_list(ids) do
    Logger.debug("Marking notifications as read",
      user_id: socket.assigns.current_user.id,
      notification_ids: ids
    )

    # Placeholder for notification marking logic
    # In a real implementation, you would update the notification records here

    {:reply, {:ok, %{marked: ids}}, socket}
  end

  def handle_in("mark_read", _payload, socket) do
    {:reply, {:error, %{reason: "invalid_payload"}}, socket}
  end

  @impl true
  def handle_in(_event, _payload, socket) do
    {:noreply, socket}
  end

  @doc """
  Broadcasts a notification to a specific user.

  ## Parameters

  - `user_id` - The user's ID
  - `type` - Notification type (e.g., "info", "warning", "success", "error")
  - `message` - The notification message
  - `data` - Optional additional data

  ## Example

      NotificationChannel.broadcast_notification(
        user.id,
        "info",
        "Your export is ready",
        %{download_url: "/exports/123.csv"}
      )
  """
  def broadcast_notification(user_id, type, message, data \\ %{}) do
    TemplateAppWeb.Endpoint.broadcast(
      "notifications:#{user_id}",
      "new_notification",
      %{
        id: Ash.UUID.generate(),
        type: type,
        message: message,
        data: data,
        timestamp: DateTime.to_iso8601(DateTime.utc_now())
      }
    )
  end
end
