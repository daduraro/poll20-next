defmodule Poll20Web.Router do
  use Poll20Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug Poll20Web.Plugs.Actor
    plug CORSPlug,
      origin: ["*"],
      headers: [
        "Authorization",
        "Content-Type",
        "Accept",
        "Origin",
        "User-Agent",
        "DNT",
        "Cache-Control",
        "X-Mx-ReqToken",
        "Keep-Alive",
        "X-Requested-With",
        "If-Modified-Since",
        "X-CSRF-Token",
        "X-member-id"
      ]
  end

  pipeline :web do
    plug :put_layout, false
  end

  scope "/" do
    pipe_through :api
    forward "/api", Poll20.Router
  end

  scope "/" do
    pipe_through :web
    get "/*path", Poll20Web.PageController, :index
  end

end
