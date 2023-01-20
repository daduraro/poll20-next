defmodule Poll20.Account do
  import Poll20.Gettext

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
    end

    timestamps()
  end

  validations do
    validate present(:email), on: :create
    validate match(:email, ~r/.+@.+/),
      message: gettext("Must be an email")
  end

  relationships do
    has_many :members, Poll20.Member
  end

  postgres do
    table "accounts"
    repo Poll20.Repo
  end

end
