defmodule Poll20.Router do
  use AshJsonApi.Api.Router,
    api: Poll20,
    registry: Poll20.Registry
end
