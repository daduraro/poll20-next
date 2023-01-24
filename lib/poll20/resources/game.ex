defmodule Poll20.Game do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  policies do
    policy always() do
      authorize_if expr(room.id == ^actor(:room_id))
      authorize_if expr(room.invite_code == ^actor(:invite_code))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    many_to_many :owners, Poll20.Member do
      through Poll20.GameOwner
      source_attribute_on_join_resource :game_id
      destination_attribute_on_join_resource :member_id
    end
  end

  postgres do
    table "games"
    repo Poll20.Repo
  end
end
