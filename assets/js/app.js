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
  player: null, // Store Hls instance

  mounted() {
    this.initPlayer();
  },

  updated() {
    // If the HLS URL changes, re-initialize the player
    const newHlsUrl = this.el.dataset.hlsUrl;
    if (this.player && this.currentUrl !== newHlsUrl) {
      this.initPlayer();
    }
  },

  destroyed() {
    if (this.player) {
      this.player.destroy();
    }
  },

  initPlayer() {
    const video = this.el;
    const hlsUrl = video.dataset.hlsUrl;
    
    if (this.player) {
      this.player.destroy();
    }

    this.currentUrl = hlsUrl;

    if (Hls.isSupported()) {
      this.player = new Hls();
      this.player.loadSource(hlsUrl);
      this.player.attachMedia(video);
      this.player.on(Hls.Events.MANIFEST_PARSED, () => {
        video.play();
      });
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = hlsUrl;
      video.addEventListener('loadedmetadata', () => {
        video.play();
      });
    } else {
      console.error('This browser does not support HLS natively or via hls.js');
    }
  }
};


Hooks.AnimateCount = {
  mounted() {
    this.lastValue = this.el.innerText;
  },
  updated() {
    const newValue = this.el.innerText;
    if (newValue !== this.lastValue) {
      this.lastValue = newValue;
      this.el.classList.remove("animate-pop");
      void this.el.offsetWidth; 
      this.el.classList.add("animate-pop");
    }
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
  params: { _csrf_token: csrfToken },
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
