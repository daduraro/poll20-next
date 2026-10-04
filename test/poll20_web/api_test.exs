defmodule Poll20Web.ApiTest do
  @moduledoc """
  HTTP-level tests of the JSON:API, shaped like the requests the Vue client
  (assets/src/composables/api.ts) sends: JSON:API headers, an `x-member-id`
  header (empty when logged out) and bodies of the form `%{data: %{attributes: ...}}`.
  """
  use Poll20Web.ConnCase

  defp api(method, path, opts \\ []) do
    body =
      case opts[:attributes] do
        nil -> ""
        attributes -> Jason.encode!(%{data: %{attributes: attributes}})
      end

    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")
      |> put_req_header("x-member-id", opts[:member] || "")
      |> dispatch(@endpoint, method, "/api" <> path, body)

    {conn.status, if(conn.resp_body == "", do: nil, else: Jason.decode!(conn.resp_body))}
  end

  # Unique included entries of a type (the API may repeat an entity in `included`)
  defp included(body, type),
    do: body["included"] |> List.wrap() |> Enum.filter(&(&1["type"] == type)) |> Enum.uniq_by(& &1["id"])

  # Resolves a relationship the way the frontend's serialize() does: by matching id and type in `included`
  defp related(body, entity, relationship) do
    resolve = fn ref ->
      Enum.find(body["included"], &(&1["id"] == ref["id"] and &1["type"] == ref["type"]))
    end

    case entity["relationships"][relationship]["data"] do
      refs when is_list(refs) -> Enum.map(refs, resolve)
      ref -> resolve.(ref)
    end
  end

  # Creates a room and joins it, like pages/index.vue
  defp create_room(name \\ "Room", member_name \\ "Alice") do
    {201, %{"data" => room}} = api(:post, "/rooms", attributes: %{name: name})
    invite_code = room["attributes"]["invite_code"]

    {status, joined} =
      api(:patch, "/rooms/#{room["id"]}/join?invite_code=#{invite_code}&include=members",
        attributes: %{name: member_name}
      )

    assert status in [200, 201]
    [member] = included(joined, "member")
    %{id: room["id"], invite_code: invite_code, member: member["id"]}
  end

  defp join(room, name) do
    {status, joined} =
      api(:patch, "/rooms/#{room.id}/join?invite_code=#{room.invite_code}&include=members", attributes: %{name: name})

    assert status in [200, 201]

    joined
    |> included("member")
    |> Enum.find(&(&1["attributes"]["name"] == name))
    |> Map.get("id")
  end

  defp create_game(room, attributes \\ %{}) do
    {201, %{"data" => game}} =
      api(:post, "/games",
        member: room.member,
        attributes:
          Map.merge(
            %{
              name: "Catan",
              players_min: 3,
              players_max: 4,
              match_all_owners: false,
              owners: [],
              room_id: room.id
            },
            attributes
          )
      )

    game
  end

  describe "rooms" do
    test "create returns name and invite_code" do
      {status, %{"data" => room}} = api(:post, "/rooms", attributes: %{name: "Board night"})
      assert status == 201
      assert room["type"] == "room"
      assert room["attributes"]["name"] == "Board night"
      assert is_binary(room["attributes"]["invite_code"])
    end

    test "join creates a member and returns it as included" do
      {201, %{"data" => room}} = api(:post, "/rooms", attributes: %{name: "R"})
      code = room["attributes"]["invite_code"]

      {status, body} =
        api(:patch, "/rooms/#{room["id"]}/join?invite_code=#{code}&include=members", attributes: %{name: "Alice"})

      assert status in [200, 201]

      assert [%{"attributes" => %{"name" => "Alice", "room_id" => room_id}}] =
               included(body, "member")

      assert room_id == room["id"]
      assert [%{"id" => _}] = body["data"]["relationships"]["members"]["data"]
    end

    test "join with a wrong invite code is rejected" do
      {201, %{"data" => room}} = api(:post, "/rooms", attributes: %{name: "R"})

      {status, _} =
        api(
          :patch,
          "/rooms/#{room["id"]}/join?invite_code=#{Ecto.UUID.generate()}&include=members",
          attributes: %{name: "Mallory"}
        )

      assert status in [403, 404]
    end

    test "lookup by invite code (join page) works without being a member" do
      room = create_room()

      {status, body} = api(:get, "/rooms?invite_code=#{room.invite_code}&include=members")
      assert status == 200
      assert [%{"id" => id}] = body["data"]
      assert id == room.id
      assert [%{"attributes" => %{"name" => "Alice"}}] = included(body, "member")
    end

    test "index without actor or invite code returns nothing" do
      create_room()
      assert {200, %{"data" => []}} = api(:get, "/rooms")
    end

    test "member can load their room with members and games.owners" do
      room = create_room()
      game = create_game(room, %{owners: [room.member]})

      {status, body} =
        api(:get, "/rooms/#{room.id}?include=members,games.owners", member: room.member)

      assert status == 200
      assert body["data"]["attributes"]["invite_code"] == room.invite_code
      assert [%{"id" => member_id}] = included(body, "member")
      assert member_id == room.member
      assert [%{"id" => game_id} = g] = included(body, "game")
      assert game_id == game["id"]
      assert [%{"id" => ^member_id}] = g["relationships"]["owners"]["data"]
    end

    test "member of another room cannot load the room" do
      room = create_room()
      other = create_room("Other", "Eve")

      {status, _} = api(:get, "/rooms/#{room.id}?include=members", member: other.member)
      assert status in [403, 404]
    end

    test "kick removes the member" do
      room = create_room()
      bob = join(room, "Bob")

      {status, _} =
        api(:patch, "/rooms/#{room.id}/kick", member: room.member, attributes: %{member_id: bob})

      assert status in [200, 201]

      {200, body} = api(:get, "/rooms/#{room.id}?include=members", member: room.member)
      assert [%{"id" => remaining}] = included(body, "member")
      assert remaining == room.member
    end
  end

  describe "members" do
    test "rename" do
      room = create_room()

      {status, %{"data" => member}} =
        api(:patch, "/members/#{room.member}", member: room.member, attributes: %{name: "Alicia"})

      assert status in [200, 201]
      assert member["attributes"]["name"] == "Alicia"
    end

    test "members are sorted by join order" do
      room = create_room()
      join(room, "Bob")
      join(room, "Carol")

      {200, body} = api(:get, "/rooms/#{room.id}?include=members", member: room.member)
      ids = Enum.map(body["data"]["relationships"]["members"]["data"], & &1["id"])

      names =
        Enum.map(ids, fn id ->
          Enum.find(included(body, "member"), &(&1["id"] == id))["attributes"]["name"]
        end)

      assert names == ["Alice", "Bob", "Carol"]
    end
  end

  describe "games" do
    test "create with owners" do
      room = create_room()
      game = create_game(room, %{owners: [room.member]})

      assert game["attributes"]["name"] == "Catan"
      assert game["attributes"]["players_min"] == 3
      assert game["attributes"]["players_max"] == 4
      assert game["attributes"]["match_all_owners"] == false
      assert game["attributes"]["room_id"] == room.id
    end

    test "cannot create a game in another room" do
      room = create_room()
      other = create_room("Other", "Eve")

      {status, _} =
        api(:post, "/games",
          member: other.member,
          attributes: %{
            name: "Sneaky",
            players_min: 1,
            players_max: "",
            match_all_owners: false,
            owners: [],
            room_id: room.id
          }
        )

      assert status == 403
    end

    test "update with empty players_max and new owners" do
      room = create_room()
      bob = join(room, "Bob")
      game = create_game(room, %{owners: [room.member]})

      {status, %{"data" => updated}} =
        api(:patch, "/games/#{game["id"]}",
          member: room.member,
          attributes: %{
            name: "Catan 2",
            players_min: 2,
            players_max: "",
            match_all_owners: true,
            owners: [bob]
          }
        )

      assert status in [200, 201]
      assert updated["attributes"]["name"] == "Catan 2"
      assert updated["attributes"]["players_max"] == nil
      assert updated["attributes"]["match_all_owners"] == true

      {200, body} = api(:get, "/rooms/#{room.id}?include=games.owners", member: room.member)
      [g] = included(body, "game")
      assert [%{"id" => ^bob}] = g["relationships"]["owners"]["data"]
    end

    test "delete" do
      room = create_room()
      game = create_game(room)

      {status, _} = api(:delete, "/games/#{game["id"]}", member: room.member)
      assert status in [200, 204]

      {200, body} = api(:get, "/rooms/#{room.id}?include=games", member: room.member)
      assert included(body, "game") == []
    end
  end

  describe "votes" do
    test "create, list with member, update, delete" do
      room = create_room()
      game = create_game(room)

      {status, %{"data" => vote}} =
        api(:post, "/votes",
          member: room.member,
          attributes: %{game_id: game["id"], member_id: room.member, value: 1}
        )

      assert status == 201
      assert vote["attributes"]["value"] == 1
      assert vote["attributes"]["game_id"] == game["id"]
      assert vote["attributes"]["member_id"] == room.member
      assert is_binary(vote["attributes"]["inserted_at"])

      {200, body} = api(:get, "/votes?include=member", member: room.member)
      assert [%{"id" => vote_id}] = body["data"]
      assert vote_id == vote["id"]
      assert [%{"attributes" => %{"name" => "Alice"}}] = included(body, "member")

      {status, %{"data" => updated}} =
        api(:patch, "/votes/#{vote["id"]}", member: room.member, attributes: %{value: -1})

      assert status in [200, 201]
      assert updated["attributes"]["value"] == -1

      {status, _} = api(:delete, "/votes/#{vote["id"]}", member: room.member)
      assert status in [200, 204]
      assert {200, %{"data" => []}} = api(:get, "/votes", member: room.member)
    end

    test "cannot vote on behalf of someone else" do
      room = create_room()
      bob = join(room, "Bob")
      game = create_game(room)

      {status, _} =
        api(:post, "/votes",
          member: room.member,
          attributes: %{game_id: game["id"], member_id: bob, value: 1}
        )

      assert status == 403
    end

    test "only valid values" do
      room = create_room()
      game = create_game(room)

      {status, _} =
        api(:post, "/votes",
          member: room.member,
          attributes: %{game_id: game["id"], member_id: room.member, value: 5}
        )

      assert status == 400
    end

    test "votes from other rooms are not listed" do
      room = create_room()
      game = create_game(room)

      {201, _} =
        api(:post, "/votes",
          member: room.member,
          attributes: %{game_id: game["id"], member_id: room.member, value: 1}
        )

      other = create_room("Other", "Eve")
      assert {200, %{"data" => []}} = api(:get, "/votes?include=member", member: other.member)
    end
  end

  describe "sessions" do
    test "create, list (history/statistics), delete" do
      room = create_room()
      bob = join(room, "Bob")
      game = create_game(room)

      {status, %{"data" => session}} =
        api(:post, "/sessions",
          member: room.member,
          attributes: %{
            game_id: game["id"],
            comment: "close one",
            attendees: [
              %{member_id: room.member, winner: true, vote: 1},
              %{member_id: bob, winner: false, vote: -1}
            ]
          }
        )

      assert status == 201
      assert session["attributes"]["comment"] == "close one"

      {201, %{"data" => second}} =
        api(:post, "/sessions",
          member: room.member,
          attributes: %{
            game_id: game["id"],
            comment: "",
            attendees: [%{member_id: bob, winner: true, vote: nil}]
          }
        )

      {status, body} =
        api(:get, "/sessions?include=attendees.member,game&sort=-inserted_at", member: room.member)

      assert status == 200
      assert Enum.map(body["data"], & &1["id"]) == [second["id"], session["id"]]

      [listed | _] = Enum.reverse(body["data"])
      assert is_binary(listed["attributes"]["inserted_at"])
      assert listed["attributes"]["game_id"] == game["id"]
      assert listed["relationships"]["game"]["data"]["id"] == game["id"]

      attendees = Enum.flat_map(body["data"], &related(body, &1, "attendees"))
      assert length(attendees) == 3
      assert Enum.all?(attendees, & &1)

      alice_attendance = Enum.find(attendees, &(&1["attributes"]["member_id"] == room.member))
      assert alice_attendance["attributes"]["winner"] == true
      assert alice_attendance["attributes"]["vote"] == 1
      assert related(body, alice_attendance, "member")["attributes"]["name"] == "Alice"

      assert [%{"attributes" => %{"name" => "Catan"}}] = included(body, "game")

      member_names =
        body |> included("member") |> Enum.map(& &1["attributes"]["name"]) |> Enum.sort()

      assert member_names == ["Alice", "Bob"]

      {status, _} = api(:delete, "/sessions/#{session["id"]}", member: room.member)
      assert status in [200, 204]

      {200, body} = api(:get, "/sessions", member: room.member)
      assert [%{"id" => remaining}] = body["data"]
      assert remaining == second["id"]
    end

    test "sessions from other rooms are not listed" do
      room = create_room()
      game = create_game(room)

      {201, _} =
        api(:post, "/sessions",
          member: room.member,
          attributes: %{
            game_id: game["id"],
            comment: "",
            attendees: [%{member_id: room.member, winner: true, vote: 1}]
          }
        )

      other = create_room("Other", "Eve")
      assert {200, %{"data" => []}} = api(:get, "/sessions", member: other.member)
    end
  end

  describe "updates only change editable fields" do
    test "a member cannot move to another room" do
      room = create_room()
      other = create_room("Other", "Eve")

      {status, _} =
        api(:patch, "/members/#{room.member}",
          member: room.member,
          attributes: %{room_id: other.id}
        )

      assert status in 400..499

      {200, body} = api(:get, "/rooms/#{other.id}?include=members", member: other.member)
      refute Enum.any?(included(body, "member"), &(&1["id"] == room.member))
    end

    test "a game cannot be moved to another room" do
      room = create_room()
      other = create_room("Other", "Eve")
      game = create_game(room)

      {status, _} =
        api(:patch, "/games/#{game["id"]}", member: room.member, attributes: %{room_id: other.id})

      assert status in 400..499

      {200, body} = api(:get, "/rooms/#{room.id}?include=games", member: room.member)
      assert [%{"id" => id}] = included(body, "game")
      assert id == game["id"]
    end

    test "a vote cannot be reassigned to another member or game" do
      room = create_room()
      bob = join(room, "Bob")
      game = create_game(room)
      other_game = create_game(room, %{name: "Other"})

      {201, %{"data" => vote}} =
        api(:post, "/votes",
          member: room.member,
          attributes: %{game_id: game["id"], member_id: room.member, value: 1}
        )

      {status, _} =
        api(:patch, "/votes/#{vote["id"]}", member: room.member, attributes: %{member_id: bob})

      assert status in 400..499

      {status, _} =
        api(:patch, "/votes/#{vote["id"]}",
          member: room.member,
          attributes: %{game_id: other_game["id"]}
        )

      assert status in 400..499

      {200, %{"data" => [listed]}} = api(:get, "/votes", member: room.member)
      assert listed["attributes"]["member_id"] == room.member
      assert listed["attributes"]["game_id"] == game["id"]
    end

    test "the invite code cannot be set through a room update" do
      room = create_room()

      {status, _} =
        api(:patch, "/rooms/#{room.id}",
          member: room.member,
          attributes: %{invite_code: Ecto.UUID.generate()}
        )

      assert status in 400..499

      {200, body} = api(:get, "/rooms/#{room.id}", member: room.member)
      assert body["data"]["attributes"]["invite_code"] == room.invite_code
    end

    test "updating a game without owners keeps its owners" do
      room = create_room()
      game = create_game(room, %{owners: [room.member]})

      {status, _} =
        api(:patch, "/games/#{game["id"]}", member: room.member, attributes: %{name: "Renamed"})

      assert status in [200, 201]

      {200, body} = api(:get, "/rooms/#{room.id}?include=games.owners", member: room.member)
      [g] = included(body, "game")
      assert g["attributes"]["name"] == "Renamed"
      assert [%{"id" => owner}] = g["relationships"]["owners"]["data"]
      assert owner == room.member
    end

    test "editing a session comment keeps its attendees" do
      room = create_room()
      game = create_game(room)

      {201, %{"data" => session}} =
        api(:post, "/sessions",
          member: room.member,
          attributes: %{
            game_id: game["id"],
            comment: "",
            attendees: [%{member_id: room.member, winner: true, vote: 1}]
          }
        )

      {status, %{"data" => updated}} =
        api(:patch, "/sessions/#{session["id"]}",
          member: room.member,
          attributes: %{comment: "edited"}
        )

      assert status in [200, 201]
      assert updated["attributes"]["comment"] == "edited"

      {200, body} = api(:get, "/sessions?include=attendees", member: room.member)
      assert [listed] = body["data"]
      assert [_] = listed["relationships"]["attendees"]["data"]
    end
  end
end
