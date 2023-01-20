defmodule Poll20.Room do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    has_many :members, Poll20.Member
  end

  postgres do
    table "rooms"
    repo Poll20.Repo
  end
end
