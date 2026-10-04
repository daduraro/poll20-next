defmodule Poll20.Types.VoteValue do
  @moduledoc """
  An upvote (`1`) or a downvote (`-1`).
  """
  use Ash.Type.NewType, subtype_of: :integer
  use AshJsonApi.Type

  # Used by AshJsonApi for both request validation and the OpenAPI spec, which would
  # otherwise only say `integer` (validations aren't part of the schema)
  @impl AshJsonApi.Type
  def json_schema(_constraints), do: %{"type" => "integer", "enum" => [-1, 1]}
end
