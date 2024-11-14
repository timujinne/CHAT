defmodule Chat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :username, :string
      add :room, :string
      add :text, :string

      timestamps(type: :utc_datetime)
    end

    create index("messages", [:room])
  end
end
