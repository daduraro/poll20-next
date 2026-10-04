defmodule Poll20.Vote do
  use Ash.Resource,
    domain: Poll20,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  json_api do
    type "vote"
    includes [
      game: [],
      member: []
    ]

    routes do
      base "/votes"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end

  actions do
    default_accept :*
    defaults [:create, :read, :destroy, update: [:value]]
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(game.room_id == ^actor(:room_id))
    end

    policy action_type(:create) do
      forbid_unless expr(member_id == ^actor(:id))
      authorize_if expr(game.room_id == ^actor(:room_id))
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(member_id == ^actor(:id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :value, Poll20.Types.VoteValue do
      allow_nil? false
      public? true
    end

    timestamps(public?: true)
  end

  validations do
    validate one_of(:value, [-1, 1])
  end

  relationships do
    belongs_to :game, Poll20.Game do
      allow_nil? false
      public? true
      attribute_writable? true
    end

    belongs_to :member, Poll20.Member do
      allow_nil? false
      public? true
      attribute_writable? true
    end
  end

  postgres do
    table "votes"
    repo Poll20.Repo
    migration_types value: :smallint

    references do
      reference :game, on_delete: :delete
      reference :member, on_delete: :delete
    end
  end
end
