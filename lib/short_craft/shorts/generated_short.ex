defmodule ShortCraft.Shorts.GeneratedShort do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "generated_shorts" do
    field :error, :string
    field :status, :string
    field :description, :string
    field :title, :string
    field :segment, :integer
    field :output_path, :string
    field :tags, {:array, :string}
    field :youtube_id, :string
    field :uploaded_at, :utc_datetime
    field :processing_log, {:array, :map}

    belongs_to :source_video, ShortCraft.Shorts.SourceVideo, foreign_key: :source_video_id
    belongs_to :user, ShortCraft.Accounts.User, foreign_key: :user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(generated_short, attrs) do
    generated_short
    |> cast(attrs, [:output_path, :title, :description, :tags, :status, :youtube_id, :uploaded_at, :error, :processing_log, :segment])
    |> validate_required([:output_path, :title, :description, :tags, :status, :youtube_id, :uploaded_at, :error, :processing_log, :segment])
  end
end
