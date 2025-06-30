defmodule ShortCraft.Repo.Migrations.CreateSourceVideos do
  use Ecto.Migration

  def change do
    create table(:source_videos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string
      add :title, :string
      add :duration, :integer
      add :status, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:source_videos, [:user_id])
  end
end
