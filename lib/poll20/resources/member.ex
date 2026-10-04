defmodule Poll20.Member do
  # The primary read sorts members by join order on purpose, also when loaded as a relationship
  @moduledoc false
  use Ash.Resource,
    domain: Poll20,
    primary_read_warning?: false,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  json_api do
    type "member"
    includes room: []

    routes do
      base "/members"

      get :read
      index :read
      patch :update
    end
  end

  postgres do
    table "members"
    repo Poll20.Repo

    references do
      reference :room, on_delete: :delete
    end
  end

  actions do
    default_accept :*
    defaults [:create, :destroy, update: [:name]]

    read :read do
      primary? true
      prepare build(sort: [inserted_at: :asc])
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if expr(room.invite_code == ^actor(:invite_code))
    end

    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(room.id == ^actor(:room_id))
      authorize_if expr(room.invite_code == ^actor(:invite_code))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :room, Poll20.Room do
      allow_nil? false
      public? true
      attribute_writable? true
    end
  end
end
