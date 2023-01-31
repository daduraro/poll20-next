defmodule Poll20.Session do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  json_api do
    type "session"
    includes [
      attendees: []
    ]

    routes do
      base "/sessions"

      get :read
      index :read
      post :create
      patch :update
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      argument :attendees, {:array, :map} do
        allow_nil? false
      end

      change manage_relationship(:attendees, :attendees, type: :direct_control)
    end

    update :update do
      argument :attendees, {:array, :uuid} do
        allow_nil? true
        default []
      end

      change manage_relationship(:attendees, :attendees, type: :direct_control)
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if {Poll20.Policy.MatchResource,
        attribute: :game_id,
        resource: Poll20.Game,
        resource_attribute: :room_id,
        actor_attribute: :room_id}
    end

    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(room.id == ^actor(:room_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :game_id, :uuid

    attribute :comment, :string do
      allow_nil? true
      default ""
    end

    timestamps()
  end

  relationships do
    belongs_to :game, Poll20.Game do
      allow_nil? false
    end
    has_many :attendees, Poll20.SessionMember
  end

  postgres do
    table "sessions"
    repo Poll20.Repo
  end
end
