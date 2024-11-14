defmodule Chat.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :username, :string
    field :room, :string
    field :text, :string
    belongs_to :user, Chat.Messages.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:room, :text])
    |> validate_required([:room, :text, :user_id])
  end

 @doc false
  def create_changeset(message, attrs,  user) do
    message
    |> cast(attrs, [])
    |> put_change(:user_id, user.id)
    |> changeset(attrs)
  end
end
