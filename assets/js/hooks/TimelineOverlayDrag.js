const TimelineOverlayDrag = {
  mounted() {
    console.log("TimelineOverlayDrag mounted");
    this.setupTimelineOverlayDrag();
  },

  setupTimelineOverlayDrag() {
    const overlayBlocks = this.el.querySelectorAll("[data-timeline-overlay]");
    console.log("Found overlay blocks:", overlayBlocks.length);

    overlayBlocks.forEach((block) => {
      let isDragging = false;
      let startX = 0;
      let startLeft = 0;
      let originalStart = 0;
      let originalDuration = 0;

      const handleMouseDown = (e) => {
        console.log("Mouse down on overlay block");
        if (e.target.closest("[data-resize-handle]")) return; // Don't start drag if clicking resize handle

        isDragging = true;
        startX = e.clientX;
        startLeft = parseFloat(block.style.left) || 0;

        // Get original timing data
        originalStart = parseFloat(block.dataset.start) || 0;
        originalDuration = parseFloat(block.dataset.duration) || 5;

        console.log("Starting drag:", {
          startX,
          startLeft,
          originalStart,
          originalDuration,
        });

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

        console.log("Dragging:", { newLeft, newStart });
      };

      const handleMouseUp = () => {
        if (!isDragging) return;

        console.log("Mouse up, ending drag");
        isDragging = false;
        block.classList.remove("dragging");
        document.body.style.cursor = "";

        // Send update to LiveView
        const overlayId = block.dataset.overlayId;
        const newStart = parseFloat(block.dataset.start);

        console.log("Sending update:", {
          overlayId,
          newStart,
          originalDuration,
        });

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

  updated() {
    console.log("TimelineOverlayDrag updated");
    // Re-setup when component updates
    this.setupTimelineOverlayDrag();
  },
};

export default TimelineOverlayDrag;
