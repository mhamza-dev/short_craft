const VideoControls = {
  mounted() {
    this.video = this.el;
    this.lastTimeUpdate = 0;
    this.isPlaying = false;

    // Set up event listeners
    this.video.addEventListener("timeupdate", this.handleTimeUpdate.bind(this));
    this.video.addEventListener("play", this.handlePlay.bind(this));
    this.video.addEventListener("pause", this.handlePause.bind(this));
    this.video.addEventListener("ended", this.handleEnded.bind(this));
    this.video.addEventListener(
      "loadedmetadata",
      this.handleLoadedMetadata.bind(this)
    );
    this.video.addEventListener("error", this.handleError.bind(this));

    // Listen for Phoenix events from LiveView (for timeline controls)
    this.handleEvent("video_play", () => {
      this.playVideo();
    });

    this.handleEvent("video_pause", () => {
      this.pauseVideo();
    });

    this.handleEvent("video_toggle_play", () => {
      this.togglePlay();
    });

    this.handleEvent("video_stop", () => {
      this.stopVideo();
    });

    this.handleEvent("video_seek", ({ time }) => {
      this.seekVideo(parseFloat(time));
    });

    this.handleEvent("video_previous_frame", () => {
      this.seekVideo(Math.max(0, this.video.currentTime - 1 / 300));
    });

    this.handleEvent("video_next_frame", () => {
      this.seekVideo(
        Math.min(this.video.duration, this.video.currentTime + 1 / 300)
      );
    });

    // Direct video click - handle locally
    this.video.addEventListener("click", () => {
      this.togglePlay();
    });

    // Listen for button clicks from timeline
    this.setupTimelineControls();

    window.videoControlsHook = this;
  },

  setupTimelineControls() {
    // Find timeline control buttons and handle them locally
    document.addEventListener("click", (e) => {
      const button = e.target.closest("[data-video-control]");
      if (button) {
        e.preventDefault();
        e.stopPropagation();

        const control = button.getAttribute("data-video-control");
        switch (control) {
          case "toggle_play":
            this.togglePlay();
            break;
          case "stop":
            this.stopVideo();
            break;
          case "previous_frame":
            this.seekVideo(Math.max(0, this.video.currentTime - 1 / 30));
            break;
          case "next_frame":
            this.seekVideo(
              Math.min(this.video.duration, this.video.currentTime + 1 / 30)
            );
            break;
        }
      }
    });
  },

  playVideo() {
    this.video.play().catch(() => {
      this.video.muted = true;
      this.video.play();
    });
  },

  pauseVideo() {
    this.video.pause();
  },

  togglePlay() {
    if (this.video.paused) {
      this.playVideo();
    } else {
      this.pauseVideo();
    }
  },

  stopVideo() {
    this.video.pause();
    this.video.currentTime = 0;
  },

  seekVideo(time) {
    this.video.currentTime = time;
  },

  handleTimeUpdate() {
    const now = Date.now();
    if (now - this.lastTimeUpdate > 200) {
      // Update every 200ms max
      this.lastTimeUpdate = now;
      this.pushEvent("video_time_update", {
        current_time: this.video.currentTime,
      });
    }
  },

  handlePlay() {
    this.isPlaying = true;
    this.pushEvent("video_play");
  },

  handlePause() {
    this.isPlaying = false;
    this.pushEvent("video_pause");
  },

  handleEnded() {
    this.isPlaying = false;
    this.pushEvent("video_pause");
  },

  handleLoadedMetadata() {
    // No action needed
  },

  handleError(event) {
    console.error("Video error:", event);
  },

  updated() {
    const currentTime = parseFloat(this.el.dataset.currentTime || 0);
    if (Math.abs(this.video.currentTime - currentTime) > 0.1) {
      this.video.currentTime = currentTime;
    }
  },
};

export default VideoControls;
