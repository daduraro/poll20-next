defmodule Poll20.Policy.MatchActorOnCreate do
  @moduledoc """
  Despite all the magic in Ash policies, it's not possible to make an expression policy on creation.
  This policy allows you to match creation attributes to actor on creation.
  Example match attribute user_id to actor id: `{Poll20.Policy.MatchActorOnCreate, match: %{member_id: :id}}`
  """

  use Ash.Policy.SimpleCheck

  @impl true
  def describe(opts) do
    "match attributes with actor: #{inspect(Map.keys(opts[:match]))}"
  end

  @impl true
  def match?(nil, _, _), do: false
  def match?(actor, %{changeset: %{attributes: attributes}}, opts) do
    opts[:match]
    |> Map.keys()
    |> Enum.all?(fn key ->
        Map.fetch(attributes, key) == Map.fetch(actor, opts[:match][key])
    end )
  end

end
