# Project Progress: KameramaniPhx

## Latest Updates (Monday, Feb 23, 2026)
- **Streaming Setup**: Verified RTMP configuration. Advised on using TCP tunneling (ngrok tcp/playit.gg) for OBS.
- **Viewer Counting**:
  - Implemented persistent `guest_id` in session to prevent viewer count inflation on refresh.
  - Integrated real-time viewer counts into `StudioLive` sidebar and `LandingLive` cards.
  - Fixed `UptimeTimer` to halt when stream goes offline.
- **Profile Management**:
  - **Universal Access**: Updated `LandingLive` (sidebar/cards), `ChatLive`, and `StudioLive` to consistently fetch and display the user's `profile_picture` with dynamic fallbacks.
  - **Settings UI**: Refactored `UserSettingsLive` to remove the manual URL input and strictly enforce image uploads via Phoenix LiveView.
  - **Upload Fixes**: Corrected form nesting issues that prevented file submission and updated the storage path to `priv/static/uploads` for immediate availability.

## Previous Updates (Friday, Feb 20, 2026)
- **Flash Styling**: Refactored `CoreComponents.flash/1` with glassmorphism (translucency, backdrop-blur, indigo/rose glows).
- **Flash UX**: Added CSS `delay-1000` and `phx-loading` transitions to connection-related flashes to prevent flickering on page refreshes.
- **Category Refactoring**:
  - Migrated `streams` table: Removed `category_id` (UUID) and added `category` (String, default: "Just Chatting").
  - Updated `Stream` schema and `Streaming` context (removed category preload).
  - Updated `ChatLive` mount and template to use `@category_name` from the string field.
  - Updated `StudioLive` (LiveView and template) to handle category selection by name instead of ID.

## Next Steps
- Validate live streaming with the new upload and viewer count logic.
- Further UI/UX refinements.
