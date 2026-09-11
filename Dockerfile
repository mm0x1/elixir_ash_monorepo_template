# Stage 1: Build the frontend SPA
FROM node:22.23.2-bookworm-slim@sha256:83f487e0a63425e5b4d146fb5e5be574bcbe1b7b843d3ebafdd95eaf7767a7e5 AS frontend

WORKDIR /app

COPY frontend/package.json frontend/package-lock.json ./
COPY frontend/svelte.config.js ./
COPY frontend/.npmrc ./
RUN npm ci

COPY frontend/ ./

ARG VITE_API_URL=
ENV VITE_API_URL=${VITE_API_URL}

RUN npm run build

# Stage 2: Build the Elixir release
FROM hexpm/elixir:1.20.2-erlang-29.0.4-debian-bookworm-20260713-slim@sha256:290e52da1c5d5cbf62344d384387e8bdfa7d8a64784302bb7770e76ad13c88a5 AS builder

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
COPY --from=frontend /app/build priv/static/

RUN mix compile
RUN mix release

# Stage 3: Production runner
FROM debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171 AS runner

ARG VITE_API_URL=

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV VITE_API_URL=${VITE_API_URL}

WORKDIR /app

RUN useradd --create-home app
USER app

COPY --from=builder --chown=app:app /app/_build/prod/rel/template_app ./

EXPOSE 4000

ENV PHX_SERVER=true

CMD ["bin/template_app", "start"]
