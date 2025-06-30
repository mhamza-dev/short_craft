defmodule ShortCraft.Shorts.SourceVideo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "source_videos" do
    field :status, :string
    field :title, :string
    field :url, :string
    field :duration, :integer
    field :user_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(source_video, attrs) do
    source_video
    |> cast(attrs, [:url, :title, :duration, :status])
    |> validate_required([:url, :title, :duration, :status])
  end
end
