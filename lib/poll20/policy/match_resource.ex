defmodule Poll20.Policy.MatchResource do
  @moduledoc """
  Validate attribute based on another resource's value.
  Example: validate that the game from a user's vote matches that of their room's games
  `{Poll20.Policy.ValidRelationship,
    attribute: :game_id,
    resource: Poll20.Game,
    resource_attribute: :room_id,
    actor_attribute: :room_id}`
  """

  use Ash.Policy.SimpleCheck

  @impl true
  def describe(opts) do
    "match relationship with: #{inspect(opts)}"
  end

  @impl true
  def match?(nil, _, _), do: false
  def match?(actor, %{changeset: %{attributes: attributes}}, opts) do
    IO.inspect(attributes)
    with {:ok, fkey} <- Map.fetch(attributes, opts[:attribute]),
        {:ok, item} <- Poll20.get(opts[:resource], fkey),
        {:ok, value} <- Map.fetch(item, opts[:resource_attribute]),
        {:ok, actor_value} <- Map.fetch(actor, opts[:actor_attribute]) do
      value == actor_value
    else
      _ -> false
    end
  end

end
