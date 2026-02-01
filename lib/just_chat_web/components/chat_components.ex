defmodule JustChatWeb.ChatComponents do
  use Phoenix.Component
  import Phoenix.Component
  import JustChatWeb.CoreComponents

  attr :input, :string, default: ""

  def chat_input(assigns) do
    ~H"""
    <div class="flex gap-2 z-50">
      <input
        id="message_input"
        phx-hook=".ChatInput"
        name="message"
        class="flex-grow border rounded px-3 py-2 bg-gray-800 text-white border-gray-600 placeholder-gray-400"
        value={@input}
        placeholder="Write a message..."
        autocomplete="off"
      />
      <button id="send_button" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded">
        Send
      </button>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ChatInput">
      export default {
        mounted() {
          const input = this.el
          const sendButton = document.querySelector("#send_button")
          const send = () => this.pushEvent("send_message", { message: input.value })          
          input.addEventListener("keydown", (e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault()
              send()
              input.value = ""
              input.focus()
            }
          })
          sendButton?.addEventListener("click", (e) => {
            e.preventDefault()
            send()
            input.value = ""
            input.focus()
          })
        }
      }
    </script>
    """
  end

  attr :version, :string, required: true
  attr :channel, :string, required: true
  attr :repo_link, :string, required: true

  def top_bar(assigns) do
    ~H"""
    <header class="fixed top-0 left-0 right-0 px-4 sm:px-6 lg:px-8 z-50 bg-gray-900">
      <div class="max-w-[800px] mx-auto flex items-center justify-between border-b border-zinc-800 py-3 text-sm">
        <span class="bg-blue-900/30 text-blue-300 rounded-full px-2 py-1 font-medium leading-6">v{@version}</span>
        <div
          phx-click="open_room_modal"
          class="cursor-pointer text-blue-400 hover:underline font-semibold"
        >
          {@channel}
        </div>
        <a
          href={@repo_link}
          target="_blank"
          rel="noopener noreferrer"
          class="text-zinc-300 hover:text-zinc-100 font-semibold leading-6"
        >
          GitHub
        </a>
      </div>
    </header>
    """
  end

  attr :error, :string, default: nil

  def room_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/40 flex justify-center items-center z-50">
      <div class="bg-gray-800 p-6 rounded shadow-md w-80">
        <h2 class="text-lg font-bold mb-4 text-white">Change Channel</h2>
        <.form for={%{}} as={:room} phx-submit="change_room" phx-change="validate_room">
          <.input
            type="text"
            name="room"
            value=""
            placeholder="Channel name"
            class="w-full mb-4 bg-gray-700 text-white border-gray-600"
          />
          <div class="flex justify-end gap-2">
            <%= if @error do %>
              <p class="text-red-400 text-sm mt-1">{@error}</p>
            <% end %>
            <button type="button" phx-click="close_room_modal" class="text-sm text-gray-400">Cancel</button>
            <button type="submit" class={[
                "text-white px-3 py-1 rounded text-sm",
                @error != nil && "bg-gray-600 cursor-not-allowed disabled",
                @error == nil && "bg-blue-600 hover:bg-blue-700"
              ]}>Go</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
