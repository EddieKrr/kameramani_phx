export default {
  mounted() {
    const hlsUrl = this.el.dataset.hlsUrl;
    const video = this.el;

    if (!hlsUrl) {
      console.warn("No HLS URL provided");
      return;
    }

    // Check if HLS.js is available
    if (typeof Hls === "undefined") {
      console.warn("HLS.js not loaded, trying native HLS support");
      // Use native HLS support if available
      if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = hlsUrl;
      }
      return;
    }

    // Use HLS.js
    const hls = new Hls({
      autoStartLoad: true,
      debug: false,
      capLevelOnFPSDrop: true,
      capLevelOnFPSDropMultiplier: 0.9,
      defaultAudioCodec: "mp4a.40.2",
    });

    hls.loadSource(hlsUrl);
    hls.attachMedia(video);

    hls.on(Hls.Events.MANIFEST_PARSED, () => {
      console.log("HLS manifest loaded");
      // Store hls instance for updates
      this.el.hls = hls;
    });

    hls.on(Hls.Events.ERROR, (event, data) => {
      console.error("HLS error:", data);
      if (data.fatal) {
        switch (data.type) {
          case Hls.ErrorTypes.NETWORK_ERROR:
            hls.startLoad();
            break;
          case Hls.ErrorTypes.MEDIA_ERROR:
            hls.recoverMediaError();
            break;
          default:
            hls.destroy();
            break;
        }
      }
    });

    video.play().catch((e) => {
      console.log("Auto-play prevented:", e);
      // User interaction may be required
    });
  },

  updated() {
    const hlsUrl = this.el.dataset.hlsUrl;
    const video = this.el;

    if (!hlsUrl) {
      // Stream ended, stop playback
      video.pause();
      return;
    }

    if (video.hls) {
      // HLS instance exists, update if URL changed
      const currentSource = video.hls.url;
      if (currentSource !== hlsUrl) {
        video.hls.loadSource(hlsUrl);
      }
      video.play().catch((e) => {
        console.log("Play prevented:", e);
      });
    } else if (typeof Hls !== "undefined") {
      // Create new HLS instance
      const hls = new Hls({
        autoStartLoad: true,
        debug: false,
        capLevelOnFPSDrop: true,
      });

      hls.loadSource(hlsUrl);
      hls.attachMedia(video);
      this.el.hls = hls;

      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        video.play().catch((e) => {
          console.log("Auto-play prevented:", e);
        });
      });
    }
  },

  destroyed() {
    const video = this.el;
    if (video.hls) {
      video.hls.destroy();
    }
  },
};
