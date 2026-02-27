# Progress Log — 2026-02-25

## Summary
- Fixed guest access crashes in `ChatLive` and `Layouts.app`.
- Added guest login hint to chat input.
- Added social links display on profile About tab.
- Resolved Tailwind/DaisyUI build issues, restored Tailwind v3 config and DaisyUI after explicit override.
- Added streaming search helpers and search UIs for Landing and Directory pages.
- Rebuilt Directory page UI to mimic Twitch Browse (custom colors) and category cards.
- Fixed `/live` static routing to serve `.m4s` segments.
- Cleaned compilation warnings (unused aliases, regrouped functions, etc.).
- Added DB-backed categories on Directory page.

## Changes by Area

### Auth/Guest/Layouts
- `lib/kameramani_phx_web/live/chat_live.ex`
  - Use `current_user` from live session; safe access for guests.
  - Removed unused `DummyData` alias.
  - Added `Scope` default when `current_user` is nil.
- `lib/kameramani_phx_web/components/layouts.ex`
  - Safe `current_user` handling to avoid nil `Map.get` crashes.

### Chat UI
- `lib/kameramani_phx_web/live/chat_live.html.heex`
  - Added “Log in to chat” hint for guests.

### Social Links
- `lib/kameramani_phx_web/live/Profile/user_profile_live.ex`
  - Load `social_accounts` from `Socials.list_user_socials/1`.
- `lib/kameramani_phx_web/live/Profile/user_profile_live.html.heex`
  - Render Social Links section.

### Streaming Search
- `lib/kameramani_phx/streaming.ex`
  - Fixed tag search to use array containment.
  - Added `list_live_streams_by_username/1`.
  - Added `list_live_streams_by_category_or_tag/1`.
  - Fixed `list_streams/0` preload; added `list_live_streams/0`.

### Landing Search
- `lib/kameramani_phx_web/live/landing_live.ex`
  - Added username search handler + `search_form`.
  - Added helper `streams_to_cards/1`.
- `lib/kameramani_phx_web/live/landing_live.html.heex`
  - Added search form and wrapped with `<Layouts.app ...>`.

### Directory UI and Search
- `lib/kameramani_phx_web/live/directory_live.ex`
  - Use DB categories via `Content.list_categories()`.
  - Add `active_tab` state + `set_directory_tab` handler.
  - Search handler for categories + tags.
  - Map streams to cards with user preloads.
- `lib/kameramani_phx_web/live/directory_live.html.heex`
  - Twitch-style browse layout with tabs, pills, search, and live/cat views.
- `lib/kameramani_phx_web/components/card_components.ex`
  - Reworked `category_card` to render image + overlay and `thumbnail_url`.

### Static Streaming
- `lib/kameramani_phx_web/router.ex`
  - `/live` now serves `m3u8`, `ts`, `m4s`, `mp4`.

### Build/Tooling
- Restored Tailwind v3 config + DaisyUI after override.
  - `assets/tailwind.config.js` restored.
  - `config/config.exs` uses Tailwind 3.4.3 with config.
  - `assets/css/app.css` reverted to `@tailwind` directives.
  - DaisyUI re-added to `assets/package.json` and `assets/package-lock.json`.

### Cleanup
- `lib/kameramani_phx_web/live/landing_live.ex`: removed unused alias + unused default arg.
- `lib/kameramani_phx_web/live/chat_live.ex`: removed unused alias.
- `lib/kameramani_phx/rtmp_ingest_listener/client_handler.ex`: removed invalid `@impl` on `handle_teardown`.
- `lib/mix/tasks/start_pipeline.ex`: regrouped `def run/1` clauses.
- `lib/kameramani_phx/accounts.ex`: removed unused private functions.

## Commands Run (not exhaustive)
- `mix assets.build`
- `mix tailwind.install`
- `npm install` (in `assets/`)

## Known Warnings (as of last successful build)
- Some warnings in RTMP handler and Accounts were cleaned.
- If any remain, rerun `mix precommit` to verify.

# Progress Log — 2026-02-26

## Summary
- Implemented navbar search with live dropdown results; routes to stream if live, otherwise user profile.
- Added thumbnail capture worker (GenServer) that periodically snapshots live HLS into `/thumbnails/<stream_id>.jpg`.
- Added thumbnail rendering on stream cards (Landing/Directory/Profile).
- Excluded thumbnails from dev live reload to prevent constant reloads.
- Added user search helper in Accounts for navbar dropdown.

## Changes by Area

### Navbar Search
- `lib/kameramani_phx_web/components/layouts.ex`
  - Injected `NavbarSearchComponent` with `current_user`.
- `lib/kameramani_phx_web/components/navbar_search_component.ex`
  - Live dropdown search for usernames.
  - Live badge for currently live users.
  - Conditional navigation: stream page if live, profile if offline.
- `lib/kameramani_phx/accounts.ex`
  - Added `list_users_by_username/2` for navbar search.

### Live Thumbnails
- `lib/kameramani_phx/thumbnail_worker.ex`
  - GenServer that uses ffmpeg to capture a thumbnail from `index.m3u8`.
- `lib/kameramani_phx/application.ex`
  - Added `ThumbnailRegistry` and `ThumbnailSupervisor`.
- `lib/kameramani_phx/stream_manager.ex`
  - Starts/stops thumbnail worker per stream.
- `lib/kameramani_phx_web/endpoint.ex`
  - Serves `/thumbnails` via `Plug.Static`.
- `config/dev.exs`
  - Excluded `priv/static/thumbnails` from live reload patterns.

### Card Thumbnails
- `lib/kameramani_phx_web/components/card_components.ex`
  - Added `thumbnail_url` attr and renders stream thumbnail in card.
- `lib/kameramani_phx_web/live/landing_live.ex`
  - Adds thumbnail URL to stream card data.
- `lib/kameramani_phx_web/live/landing_live.html.heex`
  - Passes `thumbnail_url` to cards.
- `lib/kameramani_phx_web/live/directory_live.ex`
  - Adds thumbnail URL to stream card data.
- `lib/kameramani_phx_web/live/directory_live.html.heex`
  - Passes `thumbnail_url` to cards.
- `lib/kameramani_phx_web/components/profile_components.ex`
  - Passes thumbnail URL to VOD cards.

## Known Issues
- `mix precommit` fails in this environment due to Mix PubSub socket permissions (`:eperm`).
