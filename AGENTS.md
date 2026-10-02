# AGENTS.md

## Development environment

Prefer Docker Compose whenever it is available. Start the app and run project
commands in the container instead of on the host, so the Ruby/Node versions and the
installed gems match `Dockerfile.dev`. The compose project is `chatbot-dev`, the
service is `app`, and the source is mounted at `/workspaces/chatbot`.

```sh
docker compose up -d
docker compose exec app bin/rails test
docker compose exec app bin/rails console
docker compose exec app bin/rails db:migrate
docker compose exec app bin/rubocop
docker compose exec app npm run build
docker compose run --rm app bin/brakeman
docker compose down
```

* `docker compose up` starts the app, running `bin/setup --skip-server` and then
  `bin/dev`, so a running stack needs no extra setup. The app is served on
  http://localhost:3000.
* `exec` runs in the running container; `run --rm` starts a one-off container, which
  is what long or isolated commands such as `bin/brakeman` should use.
* Check `docker compose version` first, and fall back to running `bin/*` directly on
  the host only when Docker Compose is unavailable. Do not install gems or npm
  packages on the host for this project.
* A session already attached to the dev container counts as inside the container: run
  the commands plainly (`bin/rails test`), without the compose prefix.
