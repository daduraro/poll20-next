defmodule Poll20.Vote do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  json_api do
    type "vote"
    includes [
      game: []
    ]

    routes do
      base "/votes"

      get :read
      index :read
      post :create
      patch :update
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(game.room_id == ^actor(:room_id))
    end

    policy action_type(:create) do
      forbid_unless {Poll20.Policy.MatchActorOnCreate, match: %{member_id: :id}}
      authorize_if {Poll20.Policy.MatchResource,
        attribute: :game_id,
        resource: Poll20.Game,
        resource_attribute: :room_id,
        actor_attribute: :room_id}
    end

    policy action_type([:update, :delete]) do
      authorize_if expr(member_id == ^actor(:id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :game_id, :uuid
    attribute :member_id, :uuid

    attribute :value, :integer do
      allow_nil? false
    end

    timestamps()
  end

  validations do
    validate present(:value), on: :create
    validate one_of(:value, [-1, 1])
  end

  relationships do
    belongs_to :game, Poll20.Game do
      allow_nil? false
    end

    belongs_to :member, Poll20.Member do
      allow_nil? false
    end
  end

  postgres do
    table "votes"
    repo Poll20.Repo
  end
end
