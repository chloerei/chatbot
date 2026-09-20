# AGENTS.md

## Testing

- Do not use `assert_select` to test page elements unless it is strictly necessary.
  Assert observable behavior instead: response status, redirects, database changes,
  and enqueued jobs.
