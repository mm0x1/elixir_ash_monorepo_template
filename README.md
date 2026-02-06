# Phoenix SAAS Template

An example app built with Phoenix, Ash Framework, InertiaJs, React, and TypeScript based on [phx_inertia_react_ts_tw](https://github.com/0ff1ane/phx_inertia_react_ts_tw#).

I had a hard time getting InertiaJs working with phoenix adn ash, so I created this repo to serve as a starting point for any projects I might do in the future.

## Quick Start

### Prerequisites

Before starting development, ensure you have the following tools installed:

#### Required Tools

- **[Mise](https://mise.jdx.dev/)** - Runtime version manager

  ```bash
  # Install mise (macOS)
  brew install mise

  # Install mise (Linux)
  curl https://mise.run | sh
  ```

- **[Docker](https://www.docker.com/)** & **[Docker Compose](https://docs.docker.com/compose/)** - For database and services

  ```bash
  # macOS
  brew install --cask docker

  # Linux (Ubuntu/Debian)
  sudo apt-get update && sudo apt-get install docker.io docker-compose-plugin
  ```

- **[direnv](https://direnv.net/)** - Environment variable management

#### Automatic Tool Installation

This project uses mise to manage tool versions. After installing mise:

```bash
# Install all required tools (Elixir, Erlang, Node.js, etc.)
mise install
```

#### Database Setup

The project uses PostgreSQL. You can run it via Docker Compose:

```bash
# Start PostgreSQL in the background
docker compose up -d postgres
```

### Local Development Setup

1. **Clone the repository**:

   ```bash
   git clone <repository-url> my-saas-app
   cd my-saas-app
   ```

2. **Set up environment variables**:

   ```bash
   # Copy the example environment file
   cp .env.example .env

   # Allow direnv to manage environment variables
   direnv allow
   ```

3. **Install dependencies and setup the project**:

   ```bash
   # Install all tools via mise
   mise install

   # Setup database, install dependencies, build assets
   docker compose up
   mix setup
   ```

4. **Start the app**:

   ```bash
   mix phx.server
   ```

5. **Visit your application**:
   Open [http://localhost:4000](http://localhost:4000) in your browser

## Development Commands

### Code Quality

```bash
mix quality                      # Run all quality checks (format, credo, compile, lint)
mix quality.fix                  # Auto-fix formatting and linting issues
mix credo                        # Run Credo code quality analysis
mix credo --strict               # Strict mode with all checks
mise exec -- lefthook run pre-commit  # Run git hooks manually
```

### Git Hooks

This project uses [Lefthook](https://github.com/evilmartians/lefthook) for automated code quality checks on commit.

**Pre-commit hooks automatically:**
- Format Elixir code (`mix format`)
- Run Credo code quality analysis
- Check TypeScript compilation
- Lint and fix frontend code (ESLint)

Hooks install automatically during `mix setup`. To skip hooks in emergencies:
```bash
LEFTHOOK=0 git commit -m "Emergency commit"
```

## Customization Guide

### Naming

Search the codebase for the following words and rename them. Also rename folders.

```
template_app
TemplateApp
TemplateAppWeb
template_app_web
_template_app_key
```

### Branding

1. **Update environment variables** in `.env`
2. **Customize colors** in `frontend/src/App.css`
3. **Replace logo** in `priv/static/images/`
4. **Modify page titles** using the configuration system

## Contributing

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `mix test && cd frontend && npm test`
5. Submit a pull request

### Code Standards

- **Backend**: Follow Elixir community standards, use `mix format`
- **Credo**: All code must pass `mix credo --strict` quality checks
- **Frontend**: ESLint configuration provided, fix linting errors
- **Pre-commit**: Hooks automatically check formatting and linting before commits
- **Documentation**: Update README for significant changes
- **Tests**: Maintain test coverage for new features

### Development Resources

- [Phoenix Documentation](https://hexdocs.pm/phoenix) - Framework guides
- [Ash Framework](https://ash-hq.org) - Business logic framework
- [Inertia.js](https://inertiajs.com) - SPA adapter documentation
- [Vite](https://vitejs.dev) - Frontend build tool
- [TailwindCSS](https://tailwindcss.com) - Styling framework
