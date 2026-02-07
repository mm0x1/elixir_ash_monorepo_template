# Backend Dockerfile
FROM elixir:1.17-alpine AS base

WORKDIR /app

# Install dependencies
RUN apk add --no-cache build-base git

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Development
FROM base AS development

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config config
COPY lib lib
COPY priv priv

EXPOSE 4000
CMD ["mix", "phx.server"]

# Production build
FROM base AS builder

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY config config
COPY lib lib
COPY priv priv

RUN mix deps.compile && \
    mix compile && \
    mix release

# Production runtime
FROM alpine:3.19 AS production

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/template_app ./

EXPOSE 4000
CMD ["bin/template_app", "start"]
