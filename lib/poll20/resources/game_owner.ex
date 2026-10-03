defmodule Poll20.GameOwner do
  use Ash.Resource,
    domain: Poll20,
    data_layer: AshPostgres.DataLayer

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id
    timestamps()
  end

  relationships do
    belongs_to :member, Poll20.Member do
      allow_nil? false
      public? true
      attribute_writable? true
    end

    belongs_to :game, Poll20.Game do
      allow_nil? false
      public? true
      attribute_writable? true
    end
  end

  postgres do
    table "game_owners"
    repo Poll20.Repo
  end
end
