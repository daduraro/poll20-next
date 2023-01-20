defmodule Poll20.Member do
  import Poll20.Gettext

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :room_id, :uuid do
      allow_nil? false
    end

    attribute :account_id, :uuid do
      allow_nil? true
    end

    attribute :name, :string do
      allow_nil? false
    end

    attribute :admin, :boolean do
      allow_nil? false
    end

    attribute :invite_code, :uuid do
      allow_nil? true
    end

    timestamps()
  end

  relationships do
    belongs_to :rooms, Poll20.Room do
      allow_nil? false
    end
  end

  postgres do
    table "members"
    repo Poll20.Repo
  end

  json_api do
    type "member"

    routes do
      base "/members"

      get :read
      index :read
      post :create
      patch :update
    end
  end
end
