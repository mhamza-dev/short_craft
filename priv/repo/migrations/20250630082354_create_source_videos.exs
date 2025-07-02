defmodule ShortCraft.Repo.Migrations.CreateSourceVideos do
  use Ecto.Migration

  def change do
    create table(:source_videos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :text
      add :title, :text
      add :duration, :integer
      add :thumbnail, :text
      add :channel_title, :string
      add :status, :string, default: "not_started"
      add :auto_upload_shorts, :boolean, default: false
      add :shorts_to_generate, :integer, default: 0
      add :short_duration, :integer, default: 15
      add :progress, :integer, default: 0
      add :downloaded_file_path, :text
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:source_videos, [:user_id])
  end
end
