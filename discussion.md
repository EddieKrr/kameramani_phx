# Discussion Summary

- The app uses RTMP ingest to generate HLS output. A streamer creates a stream and gets a stream key, then OBS connects with that key. The RTMP pipeline writes HLS artifacts (`index.m3u8` + `.ts` segments) into `priv/static/live/<stream_id>/`.
- Viewer playback is done by loading the HLS manifest (`/live/<stream_id>/index.m3u8`) and letting Hls.js fetch segments continuously. The player just follows the manifest; it does not open a single video file.
- Public access to HLS files is provided via `Plug.Static` under `/live`, and the video element is wired to a `VideoPlayer` JS hook.
- Switching from local storage to Cloudflare R2 is compatible with the same HLS behavior as long as the manifest and segments are uploaded quickly and served at a reachable URL. The player would use the R2 URL instead of `/live/...`.
- Cloudflare Stream was discussed as an alternative, but the user intends to use an R2 bucket.
- Next steps offered: minimal change (upload HLS artifacts to R2 + update playback URL) or a cleaner refactor that introduces a storage/playback service layer.
- Future direction: implement VOD storage by persisting live HLS segments/manifests and “freezing” a final playlist on stream end.
- VOD storage model: keep the live HLS segments as they are written, then finalize the manifest at stream end and store a VOD record that references the finalized playlist URL.
- Optional packaging: allow a background job to stitch or repackage to MP4 for download while still serving the HLS playlist for playback.
- Retention policy: apply tier-based TTL (e.g., 7/14/60 days) with a cleanup job to delete expired manifests/segments and mark VODs as expired.
- Publish controls: support “store VODs” and “auto-publish” toggles plus excluded categories, with unpublished VODs requiring review before showing publicly.
- Indexing/search: store metadata (title, category, tags, duration, thumbnail, streamer, start/end time) for discovery and filtering.
- Storage backend: compatible with local disk or object storage (e.g., R2/S3) as long as manifests and segments are quickly accessible by the CDN.

## 2026-03-10 Streaming Capacity Discussion

- We mapped the overall capacity to RTMP ingest/encoding per streamer vs. HLS delivery per viewer; the Phoenix nodes saturate when each fan pulls segments directly, so unbounded viewers can bite.
- The simplest throttles are presence-based caps (count viewers per stream) or per-IP limits before handing out the stream URLs; without them a busy show could exhaust your origin bandwidth.
- Adding a Presence hook for `{stream_id, ip}` lets you reject joins once an IP exceeds its quota without a separate GenServer, and you can still issue CDN URLs for approved viewers.
- Offloading the heavy bytes to a CDN (Cloudflare Stream/R2, Fastly, etc.) is the scalable step—Phoenix handles authentication/metadata while the CDN handles millions of viewers.
- We are still just exploring these guardrails; no code was changed yet, so you can pick whether to enforce caps in Presence, add per-IP tracking, or adopt a CDN first.
## 2026-03-04 Chat Crash Discussion

- Reported runtime error: `KeyError key :stream_id not found` in `KameramaniPhxWeb.ChatLiveComponent.update/2`.
- Cause: parent LiveViews (`ChatLive` and `StudioLive`) call `send_update/2` with partial assigns (`id`, `new_message`) while component update expected `assigns.stream_id` on every call.
- Decision: keep `stream_id` as a required component state value, but do not require it in every incremental update payload.
- Implemented approach:
  - resolve stream id from `assigns[:stream_id] || socket.assigns[:stream_id]`
  - initialize `:messages` stream at mount
  - only subscribe/load initial history when stream id exists and component has not subscribed yet
- Outcome: incremental chat updates no longer crash when `send_update/2` omits `stream_id`; compile passes.

## 2026-03-10 ChatLive per-IP guardrails

- `ChatLive` now fetches the streamer record before branching, records the viewer IP from `connect_info`, and enforces a `@per_ip_limit` guard against repeated joins. Presence metadata includes the IP so the guard can count existing watchers for the same address before tracking a new one.
- `ChatLive` and `StudioLive` include `stream_id` when calling `send_update/2`, which removes the earlier KeyError from `ChatLiveComponent.update/2` and keeps the chat history scoped to the correct stream.
- The `attr :users` declaration in `AdminComponents.user_tab/1` moved ahead of any function clause so LiveView can compile it; this clears the compile-time complaint that attributes must be defined before functions.
- Added a `@total_viewer_limit` guard so the stream will stop accepting new connections once Presence already reports that viewer ceiling, even when the new viewers come from unique IPs.

## 2026-03-14 Admin pagination

- `Accounts.get_all_users/1` now accepts pagination options (`page` and `page_size`) and returns a `Scrivener.Page` if those opts are supplied, otherwise it keeps returning the full list for callers that don’t pass pagination.
- `Streaming.list_live_streams/1` mirrors the same optional pagination pattern, making it easy to drive both the user table and the “Live streams currently on air” list from page structs.
- `AdminLive` stores `users_page` and `live_streams_page` in the socket, handles `paginate_users`/`paginate_streams` events, and forwards those pages to `AdminComponents.user_tab`, which renders the table plus pagination controls and a paged stream grid.
- Added the explicit `:scrivener` dependency so `Scrivener.Config`/`Repo.paginate/2` resolve once dependencies are recompiled.
