# Local development environment for the native Phoenix/Vite workflow.
docker_compose("docker-compose.db.yml", wait=True)
backend_port = int(os.getenv("PORT", "4000"))
root_env_deps = [".env"]

local_resource(
    "hooks",
    cmd=["mise", "run", "hooks:install"],
    deps=["mise.toml", "lefthook.yml"] + root_env_deps,
)

local_resource(
    "backend",
    cmd=["mise", "run", "backend:prepare"],
    serve_cmd=["mise", "exec", "--", "mix", "phx.server"],
    dir="backend",
    serve_dir="backend",
    deps=[
        "mise.toml",
        ".env",
        "backend/mix.exs",
        "backend/mix.lock",
        "backend/config/config.exs",
        "backend/config/dev.exs",
        "backend/config/prod.exs",
        "backend/config/runtime.exs",
        "backend/priv/repo/migrations",
        "backend/priv/resource_snapshots",
        "backend/priv/repo/seeds.exs",
    ],
    resource_deps=["database"],
    readiness_probe=probe(
        period_secs=1,
        timeout_secs=1,
        failure_threshold=30,
        http_get=http_get_action(
            host="127.0.0.1",
            port=backend_port,
            path="/health",
        ),
    ),
    links=["http://127.0.0.1:%d/dev/dashboard" % backend_port],
)

local_resource(
    "frontend",
    cmd=["mise", "run", "frontend:install"],
    serve_cmd=["mise", "exec", "--", "npm", "run", "dev"],
    dir="frontend",
    serve_dir="frontend",
    deps=[
        "mise.toml",
        ".env",
        "frontend/package.json",
        "frontend/package-lock.json",
        "frontend/.npmrc",
        "frontend/svelte.config.js",
        "frontend/vite.config.ts",
        "frontend/tsconfig.json",
        "frontend/src/app.html",
    ],
    resource_deps=["backend"],
    readiness_probe=probe(
        period_secs=1,
        timeout_secs=1,
        failure_threshold=30,
        http_get=http_get_action(
            host="127.0.0.1",
            port=5173,
            path="/",
        ),
    ),
    links=["http://127.0.0.1:5173"],
)
