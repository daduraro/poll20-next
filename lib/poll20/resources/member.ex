defmodule Poll20.Member do
  use Ash.Resource,
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

      get :read, action: :read
      index :read, action: :read
      post :create
      patch :update
    end
  end

  actions do
    defaults [:read, :create, :update, :destroy]
  end

  policies do
    policy always() do
      authorize_if expr(room.id == ^actor(:room_id))
      authorize_if expr(room.invite_code == ^actor(:invite_code))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :room_id, :uuid do
      allow_nil? false
    end

    attribute :name, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :room, Poll20.Room do
      allow_nil? false
    end
  end

  postgres do
    table "members"
    repo Poll20.Repo
  end
end
