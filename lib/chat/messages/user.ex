defmodule Chat.Messages.User do
  use Ecto.Schema

  schema "users" do
    field :username, :string
    has_many :messages, Chat.Messages.Message
  end
end
