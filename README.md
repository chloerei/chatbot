# Chatbot

A Rails chat app for DeepSeek, built on [ruby_llm](https://github.com/crmne/ruby_llm).

## Development

The development container is defined once: `compose.yaml` is the service and
`Dockerfile.dev` builds the image. The two entry points below run that same
container and share the `chatbot-dev` compose project.

Inside the container, `bin/setup --skip-server` installs gems and npm packages and
prepares the SQLite database, and `bin/dev` runs the web, js and css processes from
`Procfile.dev` through foreman. The app is served on http://localhost:3000, on the
loopback interface only. Rails reloading and the esbuild/Tailwind watchers work
against the mounted source, so edits on the host take effect immediately.

### Dev Containers

Open the project in an editor that supports [Dev Containers](https://containers.dev/)
(VS Code, JetBrains, ...); `.devcontainer/devcontainer.json` inherits the root
`compose.yaml`.

The container only idles (`overrideCommand`), so start the app by hand:

```sh
bin/setup --skip-server   # first time only
bin/dev
```

Restarting the server is then just re-running `bin/dev`; the container and its
volumes stay put.

### Docker Compose

Without Dev Container support, `docker compose up --build` starts the same
environment and runs `bin/setup --skip-server` and `bin/dev` for you:

```sh
docker compose up --build             # build, setup and start bin/dev
docker compose exec app bash          # shell inside the container
docker compose exec app bin/rails c   # console
docker compose exec app bin/rails test
docker compose run --rm app bin/rubocop
docker compose down                   # stop and remove the containers
docker compose down -v                # also drop the bundle/node_modules volumes
```

### Notes

* Secrets such as `DEEPSEEK_API_KEY` live in `.env.development` (git ignored), which
  the `dotenv` gem loads in development. It is reachable through the bind mount, so
  no `env_file` is needed.
* Gems and `node_modules` are cached in named volumes, so only the first
  `docker compose up` installs them. `node_modules` must live in a volume because
  esbuild ships platform specific binaries. Drop both with `docker compose down -v`
  after a Ruby bump in `Dockerfile.dev`.
* On Linux hosts the container (running as `root`, like the Dev Container) owns the
  files it creates in the mounted source (`log/`, `tmp/`, `storage/*.sqlite3`,
  `app/assets/builds/`); fix with `sudo chown -R "$(id -u):$(id -g)" .`. Docker
  Desktop maps ownership to your user.
* The web console on error pages only answers `127.0.0.1`/`::1`, while requests
  through the published port arrive from the Docker gateway. Add e.g.
  `config.web_console.allowed_networks = [ "127.0.0.1", "::1", "172.16.0.0/12" ]` to
  `config/environments/development.rb` to use it.
* Remote debugging: `Procfile.dev` opens rdbg on port 12345. Uncomment the rdbg port
  and `RUBY_DEBUG_HOST` in `compose.yaml` to attach from the host.
* Switching between Dev Containers and `docker compose` recreates the container (the
  commands differ) but keeps gems, `node_modules` and the database.
