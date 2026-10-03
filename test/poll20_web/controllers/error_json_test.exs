defmodule Poll20Web.ErrorJSONTest do
  use Poll20Web.ConnCase, async: true

  test "renders 404" do
    assert Poll20Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Poll20Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
