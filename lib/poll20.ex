defmodule Poll20 do
  use Ash.Api, extensions: [AshJsonApi.Api]

  resources do
    registry Poll20.Registry
  end
end
