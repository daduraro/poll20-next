defmodule Poll20.SessionMember do
  use Ash.Resource,
    domain: Poll20,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  # No routes: only exposed as included `attendees` of sessions
  json_api do
    type "session_member"
  end

  actions do
    default_accept :*
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

    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(session.game.room_id == ^actor(:room_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :member_id, :uuid do
      public? true
    end

    attribute :winner, :boolean do
      allow_nil? false
      public? true
    end

    attribute :vote, :integer do
      allow_nil? true
      public? true
    end
  end

  validations do
    validate one_of(:vote, [-1, 1])
  end

  relationships do
    belongs_to :session, Poll20.Session do
      allow_nil? false
      public? true
    end

    belongs_to :member, Poll20.Member do
      allow_nil? false
      public? true
      define_attribute? false
    end
  end

  postgres do
    table "session_members"
    repo Poll20.Repo
  end
end
