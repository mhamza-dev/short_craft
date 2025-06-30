defmodule ShortCraft.Repo.Migrations.CreateGeneratedShorts do
  use Ecto.Migration

  def change do
    create table(:generated_shorts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :output_path, :string
      add :title, :string
      add :description, :text
      add :tags, {:array, :string}
      add :status, :string
      add :youtube_id, :string
      add :uploaded_at, :utc_datetime
      add :error, :text
      add :processing_log, {:array, :map}
      add :segment, :integer
      add :source_video_id, references(:source_videos, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:generated_shorts, [:source_video_id])
    create index(:generated_shorts, [:user_id])
  end
end
