defmodule Poll20.Registry do
  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry Poll20.Game
    entry Poll20.GameOwner
    entry Poll20.Member
    entry Poll20.Room
    entry Poll20.Session
    entry Poll20.SessionMember
    entry Poll20.Vote
  end
end
