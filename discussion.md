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

## 2026-03-04 Chat Crash Discussion

- Reported runtime error: `KeyError key :stream_id not found` in `KameramaniPhxWeb.ChatLiveComponent.update/2`.
- Cause: parent LiveViews (`ChatLive` and `StudioLive`) call `send_update/2` with partial assigns (`id`, `new_message`) while component update expected `assigns.stream_id` on every call.
- Decision: keep `stream_id` as a required component state value, but do not require it in every incremental update payload.
- Implemented approach:
  - resolve stream id from `assigns[:stream_id] || socket.assigns[:stream_id]`
  - initialize `:messages` stream at mount
  - only subscribe/load initial history when stream id exists and component has not subscribed yet
- Outcome: incremental chat updates no longer crash when `send_update/2` omits `stream_id`; compile passes.
