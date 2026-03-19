// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { hooks as colocatedHooks } from "phoenix-colocated/kameramani_phx"
import topbar from "../vendor/topbar"
// Import HLS.js for HLS stream playback
import Hls from "hls.js"
window.Hls = Hls

//my hooks
let Hooks = {}
Hooks.ChatScroll = {
  updated() {
    this.el.scrollTop = this.el.scrollHeight;
  }
}
Hooks.VideoPlayer = {
  player: null,
  hls: null,

  mounted() {
    this.initPlayer();
  },

  updated() {
    const newHlsUrl = this.el.dataset.hlsUrl;
    if (this.hls && this.hls.url !== newHlsUrl) {
      this.destroyPlayer();
      this.initPlayer();
    }
  },

  destroyed() {
    this.destroyPlayer();
  },

  destroyPlayer() {
    if (this.hls) {
      this.hls.destroy();
      this.hls = null;
    }
    // Remove event listeners if necessary (mostly handled by browser/DOM replacement)
  },

  initPlayer() {
    const video = this.el;
    const hlsUrl = video.dataset.hlsUrl;
    const container = video.closest('[id^="player-container"]');
    const playPauseBtn = document.getElementById(`${video.id}-play-pause`);
    const volumeSlider = document.getElementById(`${video.id}-volume-slider`);
    const muteBtn = document.getElementById(`${video.id}-mute`);
    const fullscreenBtn = document.getElementById(`${video.id}-fullscreen`);
    const loader = document.getElementById(`${video.id}-loader`);

    if (Hls.isSupported()) {
      this.hls = new Hls({
        enableWorker: true,
        lowLatencyMode: true,
      });
      this.hls.loadSource(hlsUrl);
      this.hls.attachMedia(video);
      
      this.hls.on(Hls.Events.MANIFEST_PARSED, () => {
        video.play().catch(() => {
          // Auto-play might be blocked, update UI to show paused state
          container.classList.add('is-paused');
        });
      });

      // Handle buffering states
      this.hls.on(Hls.Events.BUFFER_APPENDING, () => loader?.classList.remove('hidden'));
      this.hls.on(Hls.Events.BUFFER_APPENDED, () => loader?.classList.add('hidden'));
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = hlsUrl;
    }

    // --- Custom Controls Logic ---

    // Play/Pause
    const togglePlay = () => {
      if (video.paused) {
        video.play();
        container.classList.remove('is-paused');
        playPauseBtn.querySelector('.player-play-icon').classList.add('hidden');
        playPauseBtn.querySelector('.player-pause-icon').classList.remove('hidden');
      } else {
        video.pause();
        container.classList.add('is-paused');
        playPauseBtn.querySelector('.player-play-icon').classList.remove('hidden');
        playPauseBtn.querySelector('.player-pause-icon').classList.add('hidden');
      }
    };

    video.addEventListener('click', togglePlay);
    playPauseBtn?.addEventListener('click', togglePlay);

    // Volume
    const updateVolumeUI = () => {
      const isMuted = video.muted || video.volume === 0;
      if (isMuted) {
        muteBtn.querySelector('.player-unmuted-icon').classList.add('hidden');
        muteBtn.querySelector('.player-muted-icon').classList.remove('hidden');
        volumeSlider.value = 0;
      } else {
        muteBtn.querySelector('.player-unmuted-icon').classList.remove('hidden');
        muteBtn.querySelector('.player-muted-icon').classList.add('hidden');
        volumeSlider.value = video.volume * 100;
      }
    };

    volumeSlider?.addEventListener('input', (e) => {
      video.volume = e.target.value / 100;
      video.muted = video.volume === 0;
      updateVolumeUI();
    });

    muteBtn?.addEventListener('click', () => {
      video.muted = !video.muted;
      if (!video.muted && video.volume === 0) video.volume = 1;
      updateVolumeUI();
    });

    // Fullscreen
    fullscreenBtn?.addEventListener('click', () => {
      if (!document.fullscreenElement) {
        container.requestFullscreen().catch(err => {
          console.error(`Error attempting to enable full-screen mode: ${err.message}`);
        });
      } else {
        document.exitFullscreen();
      }
    });

    // Sync UI with video state (e.g. if paused via other means)
    video.addEventListener('play', () => {
      container.classList.remove('is-paused');
      playPauseBtn?.querySelector('.player-play-icon').classList.add('hidden');
      playPauseBtn?.querySelector('.player-pause-icon').classList.remove('hidden');
    });

    video.addEventListener('pause', () => {
      container.classList.add('is-paused');
      playPauseBtn?.querySelector('.player-play-icon').classList.remove('hidden');
      playPauseBtn?.querySelector('.player-pause-icon').classList.add('hidden');
    });
  }
};


Hooks.AnimateCount = {
  updated() {
    this.el.classList.remove("animate-pop");
    void this.el.offsetWidth; 
    this.el.classList.add("animate-pop");
  }
}

Hooks.UptimeTimer = {
  mounted() {
    this.timer = setInterval(() => {
      // Check if the stream is live
      const isLive = this.el.getAttribute("data-is-live") === "true";
      if (!isLive) return;

      // Get the start time injected from Elixir
      const startTimeStr = this.el.getAttribute("data-start");
      if(!startTimeStr) return;

      const startTime = new Date(startTimeStr).getTime();
      const now = new Date().getTime();
      const diffInSeconds = Math.floor((now - startTime) / 1000);

      const hours = Math.floor(diffInSeconds / 3600);
      const minutes = Math.floor((diffInSeconds % 3600) / 60);
      const seconds = diffInSeconds % 60;

      // Format to H:MM:SS
      const formattedTime = `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
      
      // Update the text safely
      if(this.el.children.length > 0) {
        // If it has an icon child, update the last child (the span)
        const display = this.el.querySelector("span") || this.el.lastElementChild;
        display.innerText = formattedTime;
      } else {
        // Just raw text
        this.el.innerText = formattedTime;
      }
    }, 1000);
  },
  destroyed() {
    clearInterval(this.timer);
  }
}


const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: () => ({
    _csrf_token: csrfToken,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "Etc/UTC",
  }),
  hooks: {...colocatedHooks, ...Hooks}, // Merge your custom Hooks here
})
// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
