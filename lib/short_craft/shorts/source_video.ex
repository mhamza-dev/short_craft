defmodule ShortCraft.Shorts.SourceVideo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @status_values [
    :not_started,
    :queued,
    :downloading,
    :downloaded,
    :shorts_processing,
    :shorts_generation_failed,
    :waiting_review,
    :shorts_publishing,
    :shorts_published,
    :failed,
    :cancelled,
    :source_deleted
  ]

  schema "source_videos" do
    field :title, :string
    field :url, :string
    field :duration, :integer

    field :status, Ecto.Enum,
      values: @status_values,
      default: :not_started

    field :thumbnail, :string
    field :channel_title, :string
    field :auto_upload_shorts, :boolean, default: false
    field :shorts_to_generate, :integer, default: 0
    field :short_duration, :integer, default: 15
    field :progress, :integer, default: 0
    field :downloaded_file_path, :string
    field :transcript, :string

    belongs_to :user, ShortCraft.Accounts.User, foreign_key: :user_id
    has_many :generated_shorts, ShortCraft.Shorts.GeneratedShort

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(source_video, attrs) do
    source_video
    |> cast(attrs, [
      :url,
      :title,
      :duration,
      :status,
      :thumbnail,
      :channel_title,
      :auto_upload_shorts,
      :shorts_to_generate,
      :short_duration,
      :progress,
      :downloaded_file_path,
      :transcript,
      :user_id
    ])
    |> validate_required([
      :url,
      :title,
      :duration,
      :status,
      :thumbnail,
      :channel_title,
      :auto_upload_shorts,
      :shorts_to_generate,
      :short_duration,
      :progress,
      :user_id
    ])
  end

  def statuses_as_list do
    @status_values
    |> Enum.map(&{String.capitalize(Regex.replace(~r/_/, Atom.to_string(&1), " ")), &1})
  end
end
