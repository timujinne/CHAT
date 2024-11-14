defmodule Chat.Messages do
  alias Chat.Message

  def system_message(text) do
    %Message{id: UUID.uuid4(), text: text, user: "system"}
  end

  alias Chat.Messages.Message
  alias Chat.Repo
  import Ecto.Query

  @doc """
  Returns the list of messages for specific room.

  ## Examples

      iex> list_messages("biwp")
      [%Message{}, ...]

  """
  def list_messages(room) do
    from(msg in Message, where: msg.room == ^room, preload: :user)#, preload: :user
    |> Repo.all()
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value}, user)
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value}, user)
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}, user) do
    result = %Message{}
    |> Message.create_changeset(attrs, user)
    |> Repo.insert()
    case result do
      {:ok, message} -> {:ok, Repo.preload(message, :user)}
      other -> other
    end
  end

  # @doc """
  # Updates a message.

  # ## Examples

  #     iex> update_message(message, %{field: new_value})
  #     {:ok, %Message{}}

  #     iex> update_message(message, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_message(%Message{} = message, attrs) do
  #   message
  #   |> Message.changeset(attrs)
  #   |> Repo.update()
  # end

  # @doc """
  # Deletes a message.

  # ## Examples

  #     iex> delete_message(message)
  #     {:ok, %Message{}}

  #     iex> delete_message(message)
  #     {:error, %Ecto.Changeset{}}

  # """
  # def delete_message(%Message{} = message) do
  #   Repo.delete(message)
  # end

  # @doc """
  # Returns an `%Ecto.Changeset{}` for tracking message changes.

  # ## Examples

  #     iex> change_message(message)
  #     %Ecto.Changeset{data: %Message{}}

  # """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
