defmodule Poll20Web.PageController do
  use Poll20Web, :controller

  def index(conn, _params), do: html(conn, File.read!("priv/static/index.html"))
end
