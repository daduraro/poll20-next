defmodule Poll20.Game do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  json_api do
    type "game"
    includes [
      owners: []
    ]

    routes do
      base "/games"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      argument :owners, {:array, :uuid} do
        allow_nil? true
        default []
      end

      change manage_relationship(:owners, :owners, type: :append_and_remove)
    end

    update :update do
      argument :owners, {:array, :uuid} do
        allow_nil? true
        default []
      end

      change manage_relationship(:owners, :owners, type: :append_and_remove)
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if {Poll20.Policy.MatchActorOnCreate, match: %{room_id: :room_id}}
    end

    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(room.id == ^actor(:room_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :room_id, :uuid

    attribute :name, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :room, Poll20.Room do
      allow_nil? false
    end

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
