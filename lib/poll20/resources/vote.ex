defmodule Poll20.Vote do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

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
