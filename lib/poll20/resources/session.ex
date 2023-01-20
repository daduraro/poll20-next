defmodule Poll20.Session do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id
    timestamps()
  end


  relationships do
    belongs_to :game, Poll20.Game do
      allow_nil? false
    end
    has_many :session_members, Poll20.SessionMember
  end

  postgres do
    table "sessions"
    repo Poll20.Repo
  end
end
