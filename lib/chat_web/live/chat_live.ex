defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view

  def mount(%{"room_id" => room_id}, _session, socket) do
    topic = "room:#[room_id]"
    #user = MnemonicSlugs.generate_slug(2)
    current_user = socket.assigns.current_user

    if connected?(socket) do
      ChatWeb.Endpoint.subscribe(topic)
      ChatWeb.Presence.track(self(), topic, current_user.username, %{typing: false})
    end

    online_users =
      topic
      |> ChatWeb.Presence.list()
      |> Map.keys()

    messages = Chat.Messages.list_messages(room_id)

    form = to_form(%{"text" => ""}, as: :message)
    # message = Chat.Messages.insert_message("#{user} join the chat", "system")
    # ChatWeb.Endpoint.broadcast(topic, "new message", message)
    # [message]
    # messages = [Chat.Messages.insert_message("#{user} joined", "System")]

    {:ok,
     assign(socket,
       room: room_id,
       current_user: current_user,
       form: form,
       topic: topic,
       online_users: online_users,
       typing_users: [],
       page_title: room_id,
       messages: messages ++ [Chat.Messages.system_message("#{current_user.username} joined")]
     ), temporary_assigns: [messages: []]}
  end

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Chat Room</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                margin: 0;
                padding: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
            }

            .container {
                max-width: 90%;
                width: 700px;
                background-color: #fff;
                box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
                border-radius: 8px;
                overflow: hidden;
                display: flex;
            }

            .chat-container {
                width: 75%;
                display: flex;
                flex-direction: column;
            }

            .user-list {
                width: 25%;
                background-color: #f0f0f0;
                border-left: 1px solid #ccc;
                padding: 10px;
                overflow-y: auto;
            }

            .chat-header {
                background-color: #007bff;
                color: #fff;
                padding: 10px;
                text-align: center;
                font-size: 18px;
            }

            .chat-messages {
                flex-grow: 1;
                padding: 10px;
                overflow-y: auto;
                border-bottom: 1px solid #ccc;
            }

            .chat-message {
                margin-bottom: 10px;
            }

            .chat-message .username {
                font-weight: bold;
                margin-right: 5px;
            }

            .chat-message .time {
                font-size: 0.85em;
                color: #888;
            }

            .chat-input {
                background-color: #f4f4f4;
                padding: 10px;
            }

            .chat-input input {
                flex-grow: 1;
                padding: 10px;
                border: 1px solid #ccc;
                border-radius: 4px;
                margin-right: 10px;
            }

            .chat-input button {
                padding: 10px 120px;
                margin: 10px 0;
                border: none;
                background-color: #007bff;
                color: #fff;
                border-radius: 4px;
                cursor: pointer;
            }

            .chat-input button:hover {
                background-color: #0056b3;
            }

            .user-list h3 {
                margin-top: 0;
            }

            .user-item {
                margin-bottom: 5px;
                padding: 5px;
                background-color: #e0e0e0;
                border-radius: 4px;
            }
        </style>
    </head>
    <body>
    <.simple_form for={@form} phx-submit="save_message" phx-change="change_message">
        <div class="container">
            <div class="chat-container">
                <div class="chat-header">
                    Chat Room: <%= @room %> as <%= @current_user.username %>
                </div>

                <div class="chat-messages" id="message-list" phx-update="append">
                    <div :for={message <- @messages} id={"message-#{message.id}"} class="chat-message">
                        <.message_line message={message} />
                    </div>
                </div>

                <div class="chat-input">
                    <.input field={@form[:text]} name="message" type="text" placeholder="Type your message here..." />
                    <.typing_users_message users={@typing_users} />
                    <button type="submit">Send</button>
                </div>
            </div>

            <div class="user-list">
                <h3>Connected Users</h3>
                <ul :for={user <- @online_users} class="user-item">
                   <li> <%= user %> </li>
                </ul>
            </div>
        </div>

        <script>
            window.addEventListener("phx:clear_input", () => {
                document.querySelector('input[name="message"]').value = "";
            });
        </script>
    </.simple_form>
    </body>
    </html>
    """
  end

  def handle_event("save_message", %{"message" => text}, socket) do
    # messages = [text | socket.assigns.messages]
    # form = to_form(%{"text" => ""}, as: :message)
    # {:noreply, assign(socket, messages: messages, form: form)}
   {:ok, message } =
      Chat.Messages.create_message(%{
          "text" => text,
          "room" => socket.assigns.room
      }, socket.assigns.current_user
      )

    ChatWeb.Presence.update(self(), socket.assigns.topic, socket.assigns.current_user.username, %{typing: false})
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new message", message)
    messages = [message]
    #IO.inspect(message.inserted_at, label: "recive this message")
    {:noreply,
     socket
     |> assign(messages: messages)
     |> push_event("clear_input", %{})}
  end

  def handle_event("change_message", %{"message" => ""}, socket) do
    ChatWeb.Presence.update(self(), socket.assigns.topic, socket.assigns.current_user.username, %{typing: false})
    {:noreply, socket}
  end

  def handle_event("change_message", %{"message" => _text}, socket) do
    # IO.inspect(text, label: "recive this message")
    ChatWeb.Presence.update(self(), socket.assigns.topic, socket.assigns.current_user.username, %{typing: true})
    {:noreply, socket}
  end

  def typing_users_message(%{users: []} = assigns) do
    ~H"""
    """
  end

  def typing_users_message(%{users: _users} = assigns) do
    ~H"""
    <div class = "ml-3 text-slate-500 text-sm"><%= Enum.join(@users, ", ") %> is typing </div>
    """
  end

  def message_line(%{message: %{user: "system"}} = assigns) do
    ~H"""
        <span class="time"><%= @message.text %></span>
    """
  end

  def message_line(assigns) do
    ~H"""
        <span class="username"><%= @message.user.username %></span>
        <span class="time"><%= @message.inserted_at %></span>
        <p><%= @message.text %></p>
    """
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: _joins, leaves: _leaves}} = _payload,
        socket
      ) do
    original_online_users = socket.assigns.online_users

    current_online_users =
      socket.assigns.topic
      |> ChatWeb.Presence.list()

    current_online_usernames =
      current_online_users
      |> Map.keys()

    leaves_users = original_online_users -- current_online_usernames
    join_users = current_online_usernames -- original_online_users

    join_messages =
      join_users
      |> Enum.map(fn user -> Chat.Messages.system_message("#{user} joined") end)

    leaves_messages =
      leaves_users
      |> Enum.map(fn user -> Chat.Messages.system_message("#{user} left") end)

    # typing_users =
    #   current_online_users
    #   |> Enum.filter(fn {_useraname, %{metas: [%{typing: typing}]}} -> typing end)
    #   |> Enum.into(%{})
    #   |> Map.keys()
    # Здесь исправление: проверяем наличие typing: true среди всех метаданных пользователя
  typing_users =
    current_online_users
    |> Enum.filter(fn {_username, %{metas: metas}} ->
      Enum.any?(metas, fn meta -> meta.typing == true end)
    end)
    |> Enum.map(fn {username, _} -> username end)

    {:noreply,
     assign(socket,
       messages: join_messages ++ leaves_messages,
       online_users: current_online_usernames,
       typing_users: typing_users
     )}
  end

  def handle_info(%{event: "new message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end
end
