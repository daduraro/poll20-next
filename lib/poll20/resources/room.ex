defmodule Poll20.Room do
  use Ash.Resource,
    domain: Poll20,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  policies do
    bypass action_type(:create) do
      authorize_if always()
    end

    # need to specify types since the previous bypass for create doesn't work with AshJsonApi
    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(exists(members, id == ^actor(:id)))
      authorize_if expr(invite_code == ^actor(:invite_code)) # ugly but way simpler
    end
  end

  json_api do
    type "room"
    includes [
      members: [],
      games: [
        owners: []
      ],
    ]

    routes do
      base "/rooms"

      get :read
      index :read
      post :create
      patch :update

      patch :join, route: "/:id/join"
      patch :kick, route: "/:id/kick"
    end
  end

  actions do
    default_accept :*
    defaults [:update, :destroy]

    read :read do
      primary? true
    end

    create :create do
      accept [:name]
      set_context(%{new: true})
    end

    update :join do
      require_atomic? false

      argument :name, :string do
        allow_nil? false
      end

      change manage_relationship :name, :members,
        value_is_key: :name,
        type: :create
    end

    update :kick do
      require_atomic? false

      argument :member_id, :uuid do
        allow_nil? false
      end

      change manage_relationship :member_id, :members,
        type: :remove,
        on_match: :destroy,
        # membership depends on room
        authorize?: false
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    # id is already an uuid, but this allows for re-generation, which could be used
    # to invalidate circulating existing invite codes.
    attribute :invite_code, :uuid do
      allow_nil? false
      public? true
      default &Ash.UUID.generate/0
    end

    timestamps()
  end

  relationships do
    has_many :members, Poll20.Member do
      public? true
    end

    has_many :games, Poll20.Game do
      public? true
    end
  end

  postgres do
    table "rooms"
    repo Poll20.Repo
  end
end
