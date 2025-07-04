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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Clipboard functionality for LiveView events
window.addEventListener("phx:copy-to-clipboard", (event) => {
  const text = event.detail.text;

  if (navigator.clipboard && window.isSecureContext) {
    // Use the modern Clipboard API
    navigator.clipboard
      .writeText(text)
      .then(() => {
        console.log("Text copied to clipboard");
      })
      .catch((err) => {
        console.error("Failed to copy text: ", err);
        fallbackCopyTextToClipboard(text);
      });
  } else {
    // Fallback for older browsers or non-secure contexts
    fallbackCopyTextToClipboard(text);
  }
});

// Fallback copy function for older browsers
function fallbackCopyTextToClipboard(text) {
  const textArea = document.createElement("textarea");
  textArea.value = text;

  // Avoid scrolling to bottom
  textArea.style.top = "0";
  textArea.style.left = "0";
  textArea.style.position = "fixed";
  textArea.style.opacity = "0";

  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();

  try {
    const successful = document.execCommand("copy");
    if (successful) {
      console.log("Text copied to clipboard (fallback)");
    } else {
      console.error("Fallback copy command failed");
    }
  } catch (err) {
    console.error("Fallback copy failed: ", err);
  }

  document.body.removeChild(textArea);
}

let Hooks = window.liveSocket?.hooks || {};

Hooks.AutoHideFlash = {
  mounted() {
    setTimeout(() => {
      this.el.classList.add("opacity-0", "pointer-events-none");
    }, 3500); // 3.5 seconds
  },
};

Hooks.ShowMore = {
  mounted() {
    this.expanded = false;
    this.update();
    this.el
      .querySelector("[data-showmore-toggle]")
      .addEventListener("click", () => {
        this.expanded = !this.expanded;
        this.update();
      });
  },
  update() {
    const more = this.el.querySelector("[data-showmore-more]");
    const less = this.el.querySelector("[data-showmore-less]");
    const toggle = this.el.querySelector("[data-showmore-toggle]");
    if (this.expanded) {
      more.style.display = "";
      less.style.display = "none";
      toggle.textContent = "Show less";
    } else {
      more.style.display = "none";
      less.style.display = "";
      toggle.textContent = toggle.dataset.moreLabel || "Show more";
    }
  },
};

window.liveSocket.hooks = Hooks;
