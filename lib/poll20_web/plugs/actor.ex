defmodule Poll20Web.Plugs.Actor do
  def init(opts) do
    opts
  end

  # we put invite_code in actor because it makes ash policies simpler
  def call(conn, _opts) do
    member = get_member(conn)
    invite_code = get_invite_code(conn)

    # ugly, I know
    actor = case [member, invite_code] do
      [nil, nil] -> nil
      [nil, invite_code] -> %{invite_code: invite_code}
      [actor, nil] -> actor
      [actor, invite_code] -> Map.put(actor, :invite_code, invite_code)
    end
IO.inspect(actor)
    conn
    |> Ash.PlugHelpers.set_actor(actor)
  end

  defp get_member(conn) do
    with [member_id] <- Plug.Conn.get_req_header(conn, "member-id"),
      {:ok, member} <- Poll20.get(Poll20.Member, member_id) do
      member
    else
      _ -> nil
    end
  end

  defp get_invite_code(conn) do
      with %{query_params: %{"invite_code" => invite_code}} <- Plug.Conn.fetch_query_params(conn) do
        invite_code
      else
        _ -> nil
      end
  end
end
