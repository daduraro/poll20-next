defmodule Poll20.SessionMember do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [
      Ash.Policy.Authorizer
    ]

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  policies do
    policy action_type(:create) do
      authorize_if {Poll20.Policy.MatchResource,
        attribute: :member_id,
        resource: Poll20.Member,
        resource_attribute: :room_id,
        actor_attribute: :room_id}
    end

    policy action_type([:read, :update, :delete]) do
      authorize_if expr(session.game.room_id == ^actor(:room_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :member_id, :uuid

    attribute :winner, :boolean do
      allow_nil? false
    end

    attribute :vote, :integer do
      allow_nil? true
    end
  end

  validations do
    validate one_of(:vote, [-1, 1])
  end

  relationships do
    belongs_to :session, Poll20.Session do
      allow_nil? false
    end
    belongs_to :member, Poll20.Member do
      allow_nil? false
    end
  end

  postgres do
    table "session_members"
    repo Poll20.Repo
  end
end
