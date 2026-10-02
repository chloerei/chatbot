# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Development

Both entry points below run the same development container: `compose.yaml` is the
single service definition and `Dockerfile.dev` builds the image, so Ruby/Node
versions, system packages, volumes and ports are identical either way. Inside the
container `bin/setup --skip-server` installs gems and npm packages and prepares the
SQLite database, and `bin/dev` runs the web, js and css processes from `Procfile.dev`
through foreman. The Rails reloader and the esbuild/Tailwind watchers work against
the mounted source, so edits on the host take effect immediately.

### Dev Containers

Open the project in an editor that supports [Dev Containers](https://containers.dev/)
(VS Code, JetBrains, ...). `.devcontainer/devcontainer.json` inherits the root
`compose.yaml`, mounts the source at `/workspaces/chatbot` and forwards port 3000.

The container itself only idles (`overrideCommand`), so the app is started by hand:
run `bin/setup --skip-server` the first time, then `bin/dev`, and it is served on
http://localhost:3000. Restarting the server is then just re-running `bin/dev`, while
the container and its volumes stay put.

### Docker Compose

For machines and editors without Dev Container support, start the same environment
directly. Port 3000 is published on the loopback interface only:

```sh
docker compose up --build
```

Unlike the Dev Container, this runs `bin/setup --skip-server` and `bin/dev` for you,
so http://localhost:3000 is ready once foreman has started.

```sh
docker compose exec app bash          # shell inside the container
docker compose exec app bin/rails c   # Rails console
docker compose exec app bin/rails test
docker compose run --rm app bin/rubocop
docker compose down                   # stop and remove the containers
docker compose down -v                # also drop the bundle/node_modules volumes
```

Notes:

* Secrets such as `DEEPSEEK_API_KEY` live in `.env.development`, which the `dotenv`
  gem loads in development (the file is git ignored and reachable through the bind
  mount). No extra `environment:`/`env_file:` entries are needed.
* Gems and `node_modules` are cached in named volumes, so only the first
  `docker compose up` installs them; later runs boot in seconds. `node_modules` has
  to live in a volume because esbuild ships platform specific binaries and the host
  copy cannot be used by the Linux container. Drop both volumes with
  `docker compose down -v` if dependencies ever look out of sync, for example after
  a Ruby version bump in `Dockerfile.dev`.
* On Linux hosts the container runs as `root` (as in the Dev Container), so files it
  creates in the mounted source (`log/`, `tmp/`, `storage/*.sqlite3`,
  `app/assets/builds/`) are owned by root; fix with
  `sudo chown -R "$(id -u):$(id -g)" .`. Docker Desktop (macOS/Windows) maps file
  ownership to your user instead.
* The interactive web console on error pages only answers requests from
  `127.0.0.1`/`::1`, and requests forwarded through the published port arrive from
  the Docker gateway address, so it stays inert. Add e.g.
  `config.web_console.allowed_networks = [ "127.0.0.1", "::1", "172.16.0.0/12" ]`
  to `config/environments/development.rb` if you want to use it.
* Remote debugging: `Procfile.dev` opens rdbg on port 12345. Uncomment the rdbg port
  and `RUBY_DEBUG_HOST` in `compose.yaml` to attach a debugger from the host.
* Dev Containers and `docker compose` share the `chatbot-dev` compose project, so
  they use the same containers and volumes; switching between the two recreates the
  container (the commands differ) but keeps gems, `node_modules` and the database.
