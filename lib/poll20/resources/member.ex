defmodule Poll20.Member do
  # The primary read sorts members by join order on purpose, also when loaded as a relationship
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
    includes [
      room: []
    ]

    routes do
      base "/members"

      get :read
      index :read
      patch :update
    end
  end

  actions do
    default_accept :*
    defaults [:create, :update, :destroy]

    read :read do
      primary? true
      prepare build(sort: [inserted_at: :asc])
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if {Poll20.Policy.MatchResource,
        attribute: :room_id,
        resource: Poll20.Room,
        resource_attribute: :invite_code,
        actor_attribute: :invite_code}
    end

    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(room.id == ^actor(:room_id))
      authorize_if expr(room.invite_code == ^actor(:invite_code))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :room_id, :uuid do
      allow_nil? false
      public? true
    end

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
      define_attribute? false
    end
  end

  postgres do
    table "members"
    repo Poll20.Repo
  end
end
