defmodule Poll20.Session do
  use Ash.Resource,
    domain: Poll20,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  json_api do
    type "session"
    includes [
      attendees: [
        member: []
      ],
      game: []
    ]

    routes do
      base "/sessions"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end

  actions do
    default_accept :*
    defaults [:read, :destroy]

    create :create do
      argument :attendees, {:array, :map} do
        allow_nil? false
      end

      change manage_relationship(:attendees, :attendees, type: :direct_control)
    end

    update :update do
      accept [:comment]
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if expr(game.room_id == ^actor(:room_id))
    end

    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(game.room.id == ^actor(:room_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :comment, :string do
      allow_nil? true
      public? true
      default ""
    end

    timestamps(public?: true)
  end

  relationships do
    belongs_to :game, Poll20.Game do
      allow_nil? false
      public? true
      attribute_writable? true
    end

    has_many :attendees, Poll20.SessionMember do
      public? true
    end
  end

  postgres do
    table "sessions"
    repo Poll20.Repo

    references do
      reference :game, on_delete: :delete
    end
  end
end
