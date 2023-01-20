defmodule Poll20.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Poll20.Repo,
      # Start the Telemetry supervisor
      Poll20Web.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Poll20.PubSub},
      # Start the Endpoint (http/https)
      Poll20Web.Endpoint
      # Start a worker by calling: Poll20.Worker.start_link(arg)
      # {Poll20.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Poll20.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Poll20Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
