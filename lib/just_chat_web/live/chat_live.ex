defmodule JustChatWeb.ChatLive do
  use JustChatWeb, :live_view
  alias Phoenix.PubSub

  import JustChat.Rooms, only: [validate_room_name: 1]
  import JustChatWeb.ChatComponents

  # For /channel/:id
  def mount(%{"id" => id}, _session, socket) do
    mount_room(id, socket)
  end

  # For global chat
  def mount(_params, _session, socket) do
    mount_room("global", socket)
  end

  def handle_event("send_message", %{"message" => message}, socket)
      when byte_size(message) == 0 do
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    topic = socket.assigns.topic
    socket_id = socket.assigns.socket_id

    PubSub.broadcast(JustChat.PubSub, topic, {
      :new_message,
      message,
      socket_id,
      DateTime.utc_now()
    })

    {:noreply, socket}
  end

  def handle_event("change_room", %{"room" => room_name}, socket) do
    room_name = String.trim(room_name)

    case validate_room_name(room_name) do
      :ok ->
        socket =
          socket
          |> assign(show_modal: false, modal_error: nil)
          |> push_navigate(to: ~p"/channel/#{room_name}", replace: true)

        {:noreply, socket}

      error ->
        {:noreply, socket |> assign(modal_error: error_message(error))}
    end
  end

  def handle_event("validate_room", %{"room" => room_name}, socket) do
    room_name = String.trim(room_name)

    case validate_room_name(room_name) do
      :ok -> {:noreply, socket |> assign(modal_error: nil)}
      error -> {:noreply, socket |> assign(modal_error: error_message(error))}
    end
  end

  def handle_event("open_room_modal", _params, socket) do
    {:noreply, socket |> assign(:show_modal, true)}
  end

  def handle_event("close_room_modal", _params, socket) do
    {:noreply, socket |> assign(:show_modal, false)}
  end

  def handle_info({:new_message, message, socket_id, time}, socket) do
    from_self = socket_id == socket.assigns.socket_id

    message = %{
      id: time,
      body: message,
      from_self: from_self,
      time: time
    }

    {:noreply, stream_insert(socket, :messages, message)}
  end

  defp mount_room(room_id, socket) do
    topic = "room:#{room_id}"
    PubSub.subscribe(JustChat.PubSub, topic)

    socket_id = System.system_time(:nanosecond)

    {:ok,
     socket
     |> assign(room_id: room_id, topic: topic, socket_id: socket_id, input: "")
     |> assign(show_modal: false, modal_error: nil)
     |> stream(:messages, [])}
  end

  defp error_message(:empty), do: "Name can't be empty"
  defp error_message(:too_long), do: "Max 30 characters"
  defp error_message(:invalid_characters), do: "Only letters, numbers, - and _"

  defp linkify(text) do
    url_regex = ~r/((https?:\/\/|www\.)[a-zA-Z0-9\-\._~:\/\?#\[\]@!\$&'\(\)\*\+,;=%]+)/
    mention_regex = ~r/@([a-zA-Z0-9_-]{1,30})/

    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> then(fn escaped ->
      escaped =
        Regex.replace(url_regex, escaped, fn _full, url ->
          href = if String.starts_with?(url, "http"), do: url, else: "https://" <> url
          ~s(<a href="#{href}" target="_blank" class="text-blue-600 underline">#{url}</a>)
        end)

      Regex.replace(mention_regex, escaped, fn _full, room ->
        ~s(<a href="/channel/#{room}" class="text-blue-600 underline">@#{room}</a>)
      end)
    end)
  end
end
