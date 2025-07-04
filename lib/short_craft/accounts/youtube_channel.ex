defmodule ShortCraft.Accounts.YoutubeChannel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "youtube_channels" do
    field :metadata, :map
    field :channel_id, :string
    field :channel_title, :string
    field :channel_url, :string
    field :access_token, :string
    field :refresh_token, :string
    field :expires_at, :utc_datetime
    field :is_connected, :boolean, default: false

    belongs_to :user, ShortCraft.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(youtube_channel, attrs) do
    youtube_channel
    |> cast(attrs, [
      :channel_id,
      :channel_title,
      :channel_url,
      :access_token,
      :refresh_token,
      :expires_at,
      :is_connected,
      :metadata,
      :user_id
    ])
    |> validate_required([
      :channel_id,
      :channel_title,
      :channel_url,
      :access_token,
      :refresh_token,
      :expires_at,
      :is_connected,
      :user_id
    ])
  end
end
