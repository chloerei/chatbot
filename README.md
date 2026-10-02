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

### Dev Containers

Open the project in an editor that supports [Dev Containers](https://containers.dev/)
(VS Code, JetBrains, ...). `.devcontainer/` builds the image, mounts the source at
`/workspaces/chatbot` and forwards port 3000. Run `bin/setup --skip-server` once
inside the container, then `bin/dev`.

### Docker Compose

For machines and editors without Dev Container support, `compose.yaml` builds the
same image from `.devcontainer/Dockerfile`, mounts the source the same way and
publishes port 3000 on the loopback interface only:

```sh
docker compose up --build
```

This runs `bin/setup --skip-server` (gems, npm packages, SQLite database) and then
`bin/dev`, so http://localhost:3000 is ready once foreman has started. The Rails
reloader and the esbuild/Tailwind watchers run inside the container against the
mounted source, so edits on the host take effect immediately.

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
  a Ruby version bump in `.devcontainer/Dockerfile`.
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
* The compose project is named `chatbot-dev`, so it does not clash with a Dev
  Container started from the same checkout.
