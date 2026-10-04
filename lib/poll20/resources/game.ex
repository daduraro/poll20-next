defmodule Poll20.Game do
  @moduledoc false
  use Ash.Resource,
    domain: Poll20,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [
      Ash.Policy.Authorizer
    ]

  json_api do
    type "game"
    includes owners: []

    routes do
      base "/games"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end

  postgres do
    table "games"
    repo Poll20.Repo

    references do
      reference :room, on_delete: :delete
    end
  end

  actions do
    default_accept :*
    defaults [:read, :destroy]

    create :create do
      argument :owners, {:array, :uuid} do
        allow_nil? true
        default []
      end

      change manage_relationship(:owners, :owners, type: :append_and_remove)
    end

    update :update do
      require_atomic? false
      accept [:name, :players_min, :players_max, :match_all_owners]

      # no default: owners are only changed when the argument is sent
      argument :owners, {:array, :uuid} do
        allow_nil? true
      end

      change manage_relationship(:owners, :owners, type: :append_and_remove)
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if expr(room_id == ^actor(:room_id))
    end

    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(room.id == ^actor(:room_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :players_min, :integer do
      allow_nil? true
      public? true
      constraints min: 1
    end

    attribute :players_max, :integer do
      allow_nil? true
      public? true
      constraints min: 1
    end

    attribute :match_all_owners, :boolean do
      allow_nil? false
      public? true
      default false
    end

    timestamps()
  end

  relationships do
    belongs_to :room, Poll20.Room do
      allow_nil? false
      public? true
      attribute_writable? true
    end

    many_to_many :owners, Poll20.Member do
      public? true
      through Poll20.GameOwner
      source_attribute_on_join_resource :game_id
      destination_attribute_on_join_resource :member_id
    end
  end
end
