defmodule Poll20 do
  use Ash.Api

  resources do
    registry Poll20.Registry
  end
end
