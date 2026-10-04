defmodule Poll20 do
  @moduledoc false
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  resources do
    resource Poll20.Game
    resource Poll20.GameOwner
    resource Poll20.Member
    resource Poll20.Room
    resource Poll20.Session
    resource Poll20.SessionMember
    resource Poll20.Vote
  end
end
