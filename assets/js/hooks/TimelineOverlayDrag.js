const TimelineOverlayDrag = {
  mounted() {
    this.setupTimelineOverlayDrag();
    this.setupTimelineSeeking();
  },

  setupTimelineOverlayDrag() {
    const overlayBlocks = this.el.querySelectorAll("[data-timeline-overlay]");

    overlayBlocks.forEach((block) => {
      let isDragging = false;
      let startX = 0;
      let startLeft = 0;
      let originalStart = 0;
      let originalDuration = 0;

      const handleMouseDown = (e) => {
        if (e.target.closest("[data-resize-handle]")) return; // Don't start drag if clicking resize handle

        isDragging = true;
        startX = e.clientX;
        startLeft = parseFloat(block.style.left) || 0;

        // Get original timing data
        originalStart = parseFloat(block.dataset.start) || 0;
        originalDuration = parseFloat(block.dataset.duration) || 5;

        // Add dragging class
        block.classList.add("dragging");
        document.body.style.cursor = "grabbing";

        e.preventDefault();
        e.stopPropagation();
      };

      const handleMouseMove = (e) => {
        if (!isDragging) return;

        const deltaX = e.clientX - startX;
        const newLeft = Math.max(0, startLeft + deltaX);

        // Calculate new start time (20px per second)
        const newStart = Math.max(0, newLeft / 20);

        // Update visual position
        block.style.left = `${newLeft}px`;

        // Update data attributes
        block.dataset.start = newStart.toFixed(1);
      };

      const handleMouseUp = () => {
        if (!isDragging) return;

        isDragging = false;
        block.classList.remove("dragging");
        document.body.style.cursor = "";

        // Send update to LiveView
        const overlayId = block.dataset.overlayId;
        const newStart = parseFloat(block.dataset.start);

        this.pushEvent("update_overlay_timing", {
          id: overlayId,
          start: newStart,
          duration: originalDuration,
        });
      };

      // Remove any existing listeners
      block.removeEventListener("mousedown", handleMouseDown);
      document.removeEventListener("mousemove", handleMouseMove);
      document.removeEventListener("mouseup", handleMouseUp);

      // Add new listeners
      block.addEventListener("mousedown", handleMouseDown);
      document.addEventListener("mousemove", handleMouseMove);
      document.addEventListener("mouseup", handleMouseUp);
    });
  },

  setupTimelineSeeking() {
    const timelineRuler = this.el.querySelector("[data-timeline]");
    if (!timelineRuler) return;

    const handleTimelineClick = (e) => {
      const rect = timelineRuler.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const pxPerSecond = parseFloat(timelineRuler.dataset.pxPerSecond) || 20;
      const seekTime = clickX / pxPerSecond;

      // Find the video element and seek directly
      const video = document.getElementById("main-video");
      if (video) {
        video.currentTime = seekTime;
      }
    };

    // Remove existing listener
    timelineRuler.removeEventListener("click", handleTimelineClick);
    // Add new listener
    timelineRuler.addEventListener("click", handleTimelineClick);
  },

  updated() {
    // Re-setup when component updates
    this.setupTimelineOverlayDrag();
    this.setupTimelineSeeking();
  },
};

export default TimelineOverlayDrag;
