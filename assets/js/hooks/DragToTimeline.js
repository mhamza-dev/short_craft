const DragToTimeline = {
  mounted() {
    this.draggedItem = null;
    this.setupDragAndDrop();
  },

  setupDragAndDrop() {
    // Make sidebar items draggable
    this.setupDraggableItems();

    // Make timeline droppable
    this.setupDroppableTimeline();

    // Make video container droppable
    this.setupDroppableVideoContainer();
  },

  setupDraggableItems() {
    // Find all draggable items in the sidebar
    const draggableItems = this.el.querySelectorAll('[data-draggable="true"]');

    draggableItems.forEach((item) => {
      item.addEventListener("dragstart", (e) => {
        this.draggedItem = {
          type: item.dataset.type,
          subtype: item.dataset.subtype,
          src: item.dataset.src,
          text: item.dataset.text,
          style: item.dataset.style,
        };

        e.dataTransfer.setData("text/plain", JSON.stringify(this.draggedItem));
        e.dataTransfer.effectAllowed = "copy";

        // Add visual feedback
        item.classList.add("opacity-50");
      });

      item.addEventListener("dragend", (e) => {
        item.classList.remove("opacity-50");
        this.draggedItem = null;
      });
    });
  },

  setupDroppableTimeline() {
    const timeline = this.el.querySelector('[data-timeline="true"]');

    if (!timeline) return;

    timeline.addEventListener("dragover", (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = "copy";

      // Add visual feedback
      timeline.classList.add("bg-blue-50", "border-blue-300");
    });

    timeline.addEventListener("dragleave", (e) => {
      // Only remove feedback if leaving the timeline area
      if (!timeline.contains(e.relatedTarget)) {
        timeline.classList.remove("bg-blue-50", "border-blue-300");
      }
    });

    timeline.addEventListener("drop", (e) => {
      e.preventDefault();
      timeline.classList.remove("bg-blue-50", "border-blue-300");

      if (!this.draggedItem) return;

      // Calculate drop position relative to timeline
      const rect = timeline.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const timeInSeconds = Math.max(0, x / 20); // 20px per second

      // Send the drop event to LiveView
      this.pushEvent("drop_on_timeline", {
        item: this.draggedItem,
        time: Math.round(timeInSeconds * 10) / 10, // Round to 1 decimal place
        x: x,
      });

      this.draggedItem = null;
    });
  },

  setupDroppableVideoContainer() {
    const videoContainer = this.el.querySelector(
      '[data-video-container="true"]'
    );

    if (!videoContainer) return;

    videoContainer.addEventListener("dragover", (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = "copy";

      // Add visual feedback
      videoContainer.classList.add("bg-blue-50", "border-blue-300");
    });

    videoContainer.addEventListener("dragleave", (e) => {
      // Only remove feedback if leaving the video container area
      if (!videoContainer.contains(e.relatedTarget)) {
        videoContainer.classList.remove("bg-blue-50", "border-blue-300");
      }
    });

    videoContainer.addEventListener("drop", (e) => {
      e.preventDefault();
      videoContainer.classList.remove("bg-blue-50", "border-blue-300");

      if (!this.draggedItem) return;

      // Find the <video> element inside the container
      const videoEl = videoContainer.querySelector("video");
      const containerRect = videoContainer.getBoundingClientRect();
      let x = e.clientX - containerRect.left;
      let y = e.clientY - containerRect.top;
      let overlayWidth = 200;
      let overlayHeight = 50;
      // Try to get default overlay size from draggedItem type
      if (
        this.draggedItem.type === "shape" ||
        this.draggedItem.type === "image" ||
        this.draggedItem.type === "video" ||
        this.draggedItem.type === "chart"
      ) {
        overlayWidth = 100;
        overlayHeight = 100;
      }
      if (this.draggedItem.type === "text") {
        overlayWidth = 200;
        overlayHeight = 50;
      }
      // Clamp to video area if possible
      if (videoEl) {
        const videoRect = videoEl.getBoundingClientRect();
        const videoX = videoRect.left - containerRect.left;
        const videoY = videoRect.top - containerRect.top;
        const videoWidth = videoRect.width;
        const videoHeight = videoRect.height;
        // Clamp x/y so overlay stays fully within video
        x = Math.max(videoX, Math.min(x, videoX + videoWidth - overlayWidth));
        y = Math.max(videoY, Math.min(y, videoY + videoHeight - overlayHeight));
        // If mouse is outside video, snap to top-left of video
        if (
          e.clientX < videoRect.left ||
          e.clientX > videoRect.right ||
          e.clientY < videoRect.top ||
          e.clientY > videoRect.bottom
        ) {
          x = videoX;
          y = videoY;
        }
      }
      // Send the drop event to LiveView with position
      this.pushEvent("drop_on_video_container", {
        item: this.draggedItem,
        x: Math.round(x),
        y: Math.round(y),
      });

      this.draggedItem = null;
    });
  },

  updated() {
    // Re-setup drag and drop when the component updates
    this.setupDragAndDrop();
  },
};

export default DragToTimeline;
