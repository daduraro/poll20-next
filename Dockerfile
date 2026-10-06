ARG ELIXIR_VERSION=1.20.4-otp-29
ARG NODE_VERSION=24

FROM node:${NODE_VERSION}-slim AS build
RUN corepack enable
WORKDIR /app
COPY . .
WORKDIR /app/assets
RUN pnpm install --frozen-lockfile
RUN pnpm run build

FROM elixir:${ELIXIR_VERSION}
ENV MIX_ENV=prod
WORKDIR /opt/app
COPY . .
RUN mix local.hex --force && \
    mix local.rebar --force

COPY --from=build /app/priv priv

CMD ["/bin/sh", "-c", "mix setup && exec mix phx.server"]