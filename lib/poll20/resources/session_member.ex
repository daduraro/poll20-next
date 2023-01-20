defmodule Poll20.SessionMember do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :winner, :boolean do
      allow_nil? false
    end

    attribute :vote, :atom do
      constraints [one_of: [-1, 1]]
    end
  end

  relationships do
    belongs_to :session, Poll20.Session do
      allow_nil? false
    end
    belongs_to :user, Poll20.Member do
      allow_nil? false
    end
  end

  postgres do
    table "session_members"
    repo Poll20.Repo
  end
end
