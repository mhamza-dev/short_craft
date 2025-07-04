defmodule ShortCraft.Repo.Migrations.CreateYoutubeChannels do
  use Ecto.Migration

  def change do
    create table(:youtube_channels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :channel_id, :string
      add :channel_title, :string
      add :channel_url, :string
      add :access_token, :string
      add :refresh_token, :string
      add :expires_at, :utc_datetime
      add :is_connected, :boolean, default: false, null: false
      add :metadata, :map
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:youtube_channels, [:user_id])

    create unique_index(:youtube_channels, [:user_id, :channel_id],
             name: :youtube_channels_user_id_channel_id_index
           )
  end
end
