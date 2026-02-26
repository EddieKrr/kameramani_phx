# Discussion Summary

- The app uses RTMP ingest to generate HLS output. A streamer creates a stream and gets a stream key, then OBS connects with that key. The RTMP pipeline writes HLS artifacts (`index.m3u8` + `.ts` segments) into `priv/static/live/<stream_id>/`.
- Viewer playback is done by loading the HLS manifest (`/live/<stream_id>/index.m3u8`) and letting Hls.js fetch segments continuously. The player just follows the manifest; it does not open a single video file.
- Public access to HLS files is provided via `Plug.Static` under `/live`, and the video element is wired to a `VideoPlayer` JS hook.
- Switching from local storage to Cloudflare R2 is compatible with the same HLS behavior as long as the manifest and segments are uploaded quickly and served at a reachable URL. The player would use the R2 URL instead of `/live/...`.
- Cloudflare Stream was discussed as an alternative, but the user intends to use an R2 bucket.
- Next steps offered: minimal change (upload HLS artifacts to R2 + update playback URL) or a cleaner refactor that introduces a storage/playback service layer.
