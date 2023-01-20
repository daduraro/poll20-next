defmodule Poll20.GameOwner do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    timestamps()
  end

  relationships do
    belongs_to :member, Poll20.Member do
      allow_nil? false
    end

    belongs_to :game, Poll20.Game do
      allow_nil? false
    end
  end

  postgres do
    table "game_owners"
    repo Poll20.Repo
  end
end
