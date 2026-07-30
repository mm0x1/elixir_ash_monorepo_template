# Stage 1: Build the Elixir release
FROM hexpm/elixir:1.20.2-erlang-29.0.4-debian-bookworm-20250428 AS builder

RUN apt-get update -y && apt-get install -y build-essential git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY backend/mix.exs backend/mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config
COPY backend/config/config.exs backend/config/prod.exs backend/config/runtime.exs config/
RUN mix deps.compile

COPY backend/lib lib/
COPY backend/priv priv/

RUN mix compile
RUN mix release

# Stage 2: Build the frontend
FROM node:22-bookworm-slim AS frontend

WORKDIR /app

COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ ./
RUN npm run build

# Stage 3: Production runner
FROM debian:bookworm-slim AS runner

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

RUN useradd --create-home app
USER app

COPY --from=builder --chown=app:app /app/_build/prod/rel/template_app ./
COPY --from=frontend --chown=app:app /app/build ./priv/static

EXPOSE 4000

ENV PHX_SERVER=true

CMD ["bin/template_app", "start"]
