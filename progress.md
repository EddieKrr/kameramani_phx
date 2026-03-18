# Progress

## Completed
- Fixed profile page crash when a user has no active stream.
  - Root cause: `active_stream.id` was accessed when `active_stream` was `nil`.
  - Change: `stream_id` is now assigned safely (`nil` when offline).

- Fixed current user access in `UserProfileLive`.
  - Root cause: `get_in(socket.assigns, [:current_user, :user])` on `KameramaniPhx.Accounts.Scope` (struct without Access behaviour).
  - Change: switched to safe pattern matching on `socket.assigns[:current_user]`.

- Added real-time profile updates for stream lifecycle events.
  - Subscribed `UserProfileLive` to PubSub topic `streams:all` on mount.
  - Added `handle_info({:stream_status_updated, stream}, socket)` to update:
    - `is_live`
    - `stream_id`
    - `active_stream`
    - `vods` (refreshed after stream stop)

- Hardened `ChatLive` onboarding so the stream is fetched before evaluating state, IP guardrails run before joining, and presence metadata includes each viewer IP.
  - Added `live_ip/1`, `per_ip_limit_reached?/2`, and a `@per_ip_limit` constant while moving the PubSub/Presence setup inside a single `connected?` block.
  - `ChatLive` and `StudioLive` now send `stream_id` with `send_update/2` so `ChatLiveComponent` always knows which chat to subscribe to.
  - `AdminComponents.user_tab` now compiles because its `attr` declarations occur before any function clauses.
 - Added a `@total_viewer_limit` guard for `ChatLive` so the stream rejects new connections when Presence already reports the configured viewer ceiling (currently 500).
- Added Scivener-driven pagination for the admin dashboard by reusing `Accounts.get_all_users(page:...)` and `Streaming.list_live_streams(page:...)`, showing pagination controls, and rendering a paged live-streams card list in the `user_tab`.
- Added the `:scrivener` dependency so `use Scrivener` in `Repo` and `Repo.paginate/2` resolve cleanly once `mix deps.get` runs again.
- Implemented User Verification and Social Accounts integration.
  - Created `VerificationRequest` and `SocialAccount` schemas/migrations.
  - Added real-time notifications and email alerts for verification approval/rejection.
  - Configured notification navigation to link directly to the user's verified profile.
  - Added "Get Verified" button and modal for profile owners.
  - Implemented social account linking with platform-specific URL prefixing (YouTube, X, Instagram, Twitch, TikTok, Discord).
  - Added verified badge next to usernames in profile headers.
  - Integrated social icons into the profile "About" section.
  - Added a library of social and utility SVG icons to `CoreComponents`.
- Updated auth and settings flows to match the `/auth` LiveView, fixed LiveView DOM id collisions, and aligned tests and redirects.
  - Added a missing magic-link confirmation route and corrected `/auth` redirects.
  - Added missing form ids and adjusted registration/login tests for the new UI behavior.
  - Ensured email-change errors render by setting changeset action.
  - Removed unused aliases and duplicate keys to satisfy `mix precommit`.

## In Progress / Next Steps
- **Distributed Storage Migration:** Resolve the issue where viewers on Machine A cannot watch streams originating from Machine B.
  - Research `Membrane.HTTPAdaptiveStream.Storages.S3Storage` for centralized HLS segment storage.
  - Implement S3/R2 storage backend in `pipeline.ex`.
  - Update `VideoPlayer` hook to resolve the correct HLS manifest URL from the shared storage provider.
  - Move thumbnail storage from `priv/static/thumbnails` to centralized storage.

## Validation
- `mix test`
- `mix precommit`

## Files Updated
- `lib/kameramani_phx_web/live/Profile/user_profile_live.ex`
- `lib/kameramani_phx_web/live/chat_live.ex`
- `lib/kameramani_phx_web/live/studio_live.ex`
- `lib/kameramani_phx_web/components/admin_components.ex`
- `lib/kameramani_phx/accounts.ex`
- `lib/kameramani_phx/streaming.ex`
- `lib/kameramani_phx_web/live/admin/admin_live.ex`
- `lib/kameramani_phx_web/live/admin/admin_live.html.heex`
- `lib/kameramani_phx_web/router.ex`
- `lib/kameramani_phx_web/live/user_live/confirmation.ex`
- `lib/kameramani_phx_web/live/new_auth_live.ex`
- `lib/kameramani_phx_web/live/new_auth_live.html.heex`
- `lib/kameramani_phx_web/live/user_live/user_settings_live.ex`
- `lib/kameramani_phx_web/live/user_live/user_settings_live.html.heex`
- `lib/kameramani_phx_web/live/directory_live.ex`
- `lib/kameramani_phx_web/live/studio_live.ex`
- `test/support/conn_case.ex`
- `test/kameramani_phx/chat_test.exs`
- `test/kameramani_phx_web/controllers/page_controller_test.exs`
- `test/kameramani_phx_web/controllers/user_session_controller_test.exs`
- `test/kameramani_phx_web/live/user_live/confirmation_test.exs`
- `test/kameramani_phx_web/live/user_live/login_test.exs`
- `test/kameramani_phx_web/live/user_live/registration_test.exs`
- `test/kameramani_phx_web/live/user_live/settings_test.exs`
- `test/kameramani_phx_web/user_auth_test.exs`
