# Poll20

<p align="center">
    <img src="assets/src/assets/logo-transparent.svg" style="width: 75px">
</p>

<p align="center">
    Ash + Phoenix + Vue board game voting and logging app
</p>

<p align="center">
    <img src="docs/images/s1.png">
    <img src="docs/images/s2.png">
    <img src="docs/images/s3.png">
    <img src="docs/images/s4.png">
    <img src="docs/images/s5.png">
    <img src="docs/images/s6.png">
</p>

## Server
Regular Phoenix server https://hexdocs.pm/phoenix/up_and_running.html + Ash https://www.ash-hq.org/docs/guides/ash/latest/tutorials/get-started (+ AshJsonApi + AshPostgres)

TL;DR setup:
* install elixir (e.g. through asdf)
* setup postgres with credentials as specified in `config/dev.exs`
* run `mix setup`

TL;DR run:
* start postgres, e.g. `sudo service postgresql start`
* boot with `mix phx.server`, or play in interactive shell with `iex -S mix`

## Client
Vue3 + Vite app (Vitesse starter template). Lives on `assets/`, compiles to `priv/static`. Develop with `pnpm dev`, build with `pnpm build`.