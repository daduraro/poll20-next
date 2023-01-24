# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Poll20.Repo.insert!(%Poll20.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

room = Ash.Seed.seed!(%Poll20.Room{})
member = Ash.Seed.seed!(%Poll20.Member{
  room_id: room.id
})

IO.inspect(%{
  room_id: room.id,
  invite_code: room.invite_code,
  member_id: member.id
})
