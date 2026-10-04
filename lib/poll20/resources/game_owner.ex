defmodule Poll20.GameOwner do
  @moduledoc false
  use Ash.Resource,
    domain: Poll20,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "game_owners"
    repo Poll20.Repo

    references do
      reference :member, on_delete: :delete
      reference :game, on_delete: :delete
    end
  end

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
end
