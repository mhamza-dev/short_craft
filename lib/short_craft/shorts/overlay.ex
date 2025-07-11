defmodule ShortCraft.Shorts.Overlay do
  use Ecto.Schema
  import Ecto.Changeset

  @cast_fields [
    :text,
    :color,
    :font_size,
    :font,
    :animation,
    :animation_mode,
    :x,
    :y,
    :width,
    :height,
    :shape,
    :src,
    :chart_type,
    :type,
    :id
  ]
  @required_fields [
    :x,
    :y,
    :width,
    :height,
    :type,
    :id
  ]

  @primary_key false
  embedded_schema do
    field :text, :string
    field :color, :string
    field :font_size, :integer
    field :font, :string
    field :animation, :string
    field :animation_mode, :string
    field :x, :integer
    field :y, :integer
    field :width, :integer
    field :height, :integer
    field :shape, :string
    field :src, :string
    field :chart_type, :string
    field :type, :string
    field :id, :integer
  end

  def changeset(overlay, attrs) do
    overlay
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
  end
end
