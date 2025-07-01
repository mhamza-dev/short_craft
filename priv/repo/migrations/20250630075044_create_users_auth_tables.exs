defmodule ShortCraft.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :name, :string, null: false
      add :hashed_password, :string, null: true
      add :confirmed_at, :utc_datetime
      add :avatar_url, :string
      add :provider, :string
      add :provider_id, :string
      add :access_token, :text
      add :refresh_token, :text
      add :expires_at, :utc_datetime
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:users, [:provider, :provider_id])

    create_if_not_exists unique_index(:users, [:provider, :provider_id],
                           name: :users_provider_provider_id_index,
                           where: "provider IS NOT NULL AND provider_id IS NOT NULL"
                         )

    create_if_not_exists unique_index(:users, [:email])

    create table(:users_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
