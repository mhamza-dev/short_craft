defmodule ShortCraft.Shorts do
  @moduledoc """
  The Shorts context.
  """

  import Ecto.Query, warn: false
  alias ShortCraft.Repo

  alias ShortCraft.Shorts.{Activity, SourceVideo, GeneratedShort}

  @doc """
  Returns the list of activities.

  ## Examples

      iex> list_activities()
      [%Activity{}, ...]

  """
  def list_activities do
    Repo.all(Activity)
  end

  @doc """
  Gets a single activity.

  Raises `Ecto.NoResultsError` if the Activity does not exist.

  ## Examples

      iex> get_activity!(123)
      %Activity{}

      iex> get_activity!(456)
      ** (Ecto.NoResultsError)

  """
  def get_activity!(id), do: Repo.get!(Activity, id)

  @doc """
  Creates a activity.

  ## Examples

      iex> create_activity(%{field: value})
      {:ok, %Activity{}}

      iex> create_activity(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_activity(attrs \\ %{}) do
    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a activity.

  ## Examples

      iex> update_activity(activity, %{field: new_value})
      {:ok, %Activity{}}

      iex> update_activity(activity, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_activity(%Activity{} = activity, attrs) do
    activity
    |> Activity.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a activity.

  ## Examples

      iex> delete_activity(activity)
      {:ok, %Activity{}}

      iex> delete_activity(activity)
      {:error, %Ecto.Changeset{}}

  """
  def delete_activity(%Activity{} = activity) do
    Repo.delete(activity)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking activity changes.

  ## Examples

      iex> change_activity(activity)
      %Ecto.Changeset{data: %Activity{}}

  """
  def change_activity(%Activity{} = activity, attrs \\ %{}) do
    Activity.changeset(activity, attrs)
  end

  @doc """
  Returns the list of source_videos.

  ## Examples

      iex> list_source_videos()
      [%SourceVideo{}, ...]

  """
  def list_source_videos(options \\ []) do
    query = from(sv in SourceVideo)

    query =
      Enum.reduce(options, query, fn
        {:user_id, value}, acc -> from(sv in acc, where: sv.user_id == ^value)
        {:preload, value}, acc -> from(sv in acc, preload: ^value)
        {:order_by, value}, acc -> from(sv in acc, order_by: ^value)
        {:limit, value}, acc -> from(sv in acc, limit: ^value)
        {:offset, value}, acc -> from(sv in acc, offset: ^value)
        _, acc -> acc
      end)

    from(q in query, where: q.status != :source_deleted) |> Repo.all()
  end

  @doc """
  Gets a single source_video.

  Raises `Ecto.NoResultsError` if the Source video does not exist.

  ## Examples

      iex> get_source_video!(123)
      %SourceVideo{}

      iex> get_source_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_source_video!(id), do: Repo.get!(SourceVideo, id)

  @doc """
  Creates a source_video.

  ## Examples

      iex> create_source_video(%{field: value})
      {:ok, %SourceVideo{}}

      iex> create_source_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_source_video(attrs \\ %{}) do
    %SourceVideo{}
    |> SourceVideo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a source_video.

  ## Examples

      iex> update_source_video(source_video, %{field: new_value})
      {:ok, %SourceVideo{}}

      iex> update_source_video(source_video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_source_video(%SourceVideo{} = source_video, attrs) do
    source_video
    |> SourceVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a source_video.

  ## Examples

      iex> delete_source_video(source_video)
      {:ok, %SourceVideo{}}

      iex> delete_source_video(source_video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_source_video(%SourceVideo{} = source_video) do
    Repo.delete(source_video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking source_video changes.

  ## Examples

      iex> change_source_video(source_video)
      %Ecto.Changeset{data: %SourceVideo{}}

  """
  def change_source_video(%SourceVideo{} = source_video, attrs \\ %{}) do
    SourceVideo.changeset(source_video, attrs)
  end

  @doc """
  Returns the list of generated_shorts.

  ## Examples

      iex> list_generated_shorts()
      [%GeneratedShort{}, ...]

  """
  def list_generated_shorts do
    Repo.all(GeneratedShort)
  end

  @doc """
  Gets a single generated_short.

  Raises `Ecto.NoResultsError` if the GeneratedShort does not exist.

  ## Examples

      iex> get_generated_short!(123)
      %GeneratedShort{}

      iex> get_generated_short!(456)
      ** (Ecto.NoResultsError)

  """
  def get_generated_short!(id), do: Repo.get!(GeneratedShort, id)

  @doc """
  Creates a generated_short.

  ## Examples

      iex> create_generated_short(%{field: value})
      {:ok, %GeneratedShort{}}

      iex> create_generated_short(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_generated_short(attrs \\ %{}) do
    %GeneratedShort{}
    |> GeneratedShort.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a generated_short.

  ## Examples

      iex> update_generated_short(generated_short, %{field: new_value})
      {:ok, %GeneratedShort{}}

      iex> update_generated_short(generated_short, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_generated_short(%GeneratedShort{} = generated_short, attrs) do
    generated_short
    |> GeneratedShort.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a generated_short.

  ## Examples

      iex> delete_generated_short(generated_short)
      {:ok, %GeneratedShort{}}

      iex> delete_generated_short(generated_short)
      {:error, %Ecto.Changeset{}}

  """
  def delete_generated_short(%GeneratedShort{} = generated_short) do
    Repo.delete(generated_short)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking generated_short changes.

  ## Examples

      iex> change_generated_short(generated_short)
      %Ecto.Changeset{data: %GeneratedShort{}}

  """
  def change_generated_short(%GeneratedShort{} = generated_short, attrs \\ %{}) do
    GeneratedShort.changeset(generated_short, attrs)
  end
end
