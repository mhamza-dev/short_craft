const DraggableResizableOverlay = {
  mounted() {
    console.log("DraggableResizableOverlay mounted for:", this.el.dataset.id);
    this.isDragging = false;
    this.isResizing = false;
    this.startX = 0;
    this.startY = 0;
    this.startWidth = 0;
    this.startHeight = 0;
    this.originalX = 0;
    this.originalY = 0;
    this.lastSentWidth = 0;
    this.lastSentHeight = 0;
    this.lastSentX = 0;
    this.lastSentY = 0;
    this.hasMoved = false; // Track if overlay actually moved

    this.el.addEventListener("mousedown", this.handleMouseDown.bind(this));
    document.addEventListener("mousemove", this.handleMouseMove.bind(this));
    document.addEventListener("mouseup", this.handleMouseUp.bind(this));
  },

  handleMouseDown(e) {
    console.log("Mouse down on overlay:", this.el.dataset.id);

    // Get the canvas container (the video element's parent)
    const canvasContainer = this.el.closest(".aspect-video");
    if (!canvasContainer) {
      console.error("Canvas container not found");
      return;
    }

    const canvasRect = canvasContainer.getBoundingClientRect();
    const overlayRect = this.el.getBoundingClientRect();

    // Calculate current overlay position relative to canvas
    this.originalX = parseInt(this.el.style.left) || 0;
    this.originalY = parseInt(this.el.style.top) || 0;

    // Calculate mouse position relative to canvas
    this.startX = e.clientX - canvasRect.left;
    this.startY = e.clientY - canvasRect.top;

    const handleSize = 8;

    // Check if clicking on resize handle (bottom-right corner)
    const isResizeHandle =
      e.clientX > overlayRect.right - handleSize &&
      e.clientX < overlayRect.right + handleSize &&
      e.clientY > overlayRect.bottom - handleSize &&
      e.clientY < overlayRect.bottom + handleSize;

    if (isResizeHandle) {
      console.log("Starting resize");
      this.isResizing = true;
      e.preventDefault();
      e.stopPropagation();
      this.startWidth = parseInt(this.el.style.width) || overlayRect.width;
      this.startHeight = parseInt(this.el.style.height) || overlayRect.height;
      this.lastSentWidth = this.startWidth;
      this.lastSentHeight = this.startHeight;
    } else {
      console.log(
        "Starting drag from position:",
        this.originalX,
        this.originalY
      );
      this.isDragging = true;
      this.hasMoved = false; // Reset move flag
      e.preventDefault();
      e.stopPropagation();
      this.lastSentX = this.originalX;
      this.lastSentY = this.originalY;
    }
  },

  handleMouseMove(e) {
    if (!this.isDragging && !this.isResizing) return;

    // Get the canvas container
    const canvasContainer = this.el.closest(".aspect-video");
    if (!canvasContainer) return;

    const canvasRect = canvasContainer.getBoundingClientRect();

    if (this.isDragging) {
      // Calculate new position relative to canvas
      const newX = e.clientX - canvasRect.left - (this.startX - this.originalX);
      const newY = e.clientY - canvasRect.top - (this.startY - this.originalY);

      // Constrain to canvas bounds
      const maxX =
        canvasRect.width -
        (parseInt(this.el.style.width) || this.el.offsetWidth);
      const maxY =
        canvasRect.height -
        (parseInt(this.el.style.height) || this.el.offsetHeight);

      const constrainedX = Math.max(0, Math.min(newX, maxX));
      const constrainedY = Math.max(0, Math.min(newY, maxY));

      // Check if overlay actually moved
      if (
        Math.abs(constrainedX - this.originalX) > 2 ||
        Math.abs(constrainedY - this.originalY) > 2
      ) {
        this.hasMoved = true;
      }

      // Update the overlay position immediately for smooth dragging
      this.el.style.left = constrainedX + "px";
      this.el.style.top = constrainedY + "px";

      // Only send event if position changed significantly (throttle)
      if (
        Math.abs(constrainedX - this.lastSentX) > 2 ||
        Math.abs(constrainedY - this.lastSentY) > 2
      ) {
        console.log("Dragging to:", constrainedX, constrainedY);
        this.pushEvent("move_overlay", {
          id: this.el.dataset.id,
          x: Math.round(constrainedX),
          y: Math.round(constrainedY),
        });
        this.lastSentX = constrainedX;
        this.lastSentY = constrainedY;
      }
    }

    if (this.isResizing) {
      const deltaWidth = e.clientX - canvasRect.left - this.startX;
      const deltaHeight = e.clientY - canvasRect.top - this.startY;

      const newWidth = Math.max(20, this.startWidth + deltaWidth);
      const newHeight = Math.max(20, this.startHeight + deltaHeight);

      // Update the overlay size immediately for smooth resizing
      this.el.style.width = newWidth + "px";
      this.el.style.height = newHeight + "px";

      // Only send event if size changed significantly (throttle)
      if (
        Math.abs(newWidth - this.lastSentWidth) > 2 ||
        Math.abs(newHeight - this.lastSentHeight) > 2
      ) {
        console.log("Resizing to:", newWidth, newHeight);
        this.pushEvent("resize_overlay", {
          id: this.el.dataset.id,
          width: Math.round(newWidth),
          height: Math.round(newHeight),
        });
        this.lastSentWidth = newWidth;
        this.lastSentHeight = newHeight;
      }
    }
  },

  handleMouseUp(e) {
    if (this.isDragging || this.isResizing) {
      console.log("Stopping drag/resize");

      // Send final position/size to ensure server has the latest state
      if (this.isDragging && this.hasMoved) {
        const finalX = parseInt(this.el.style.left) || 0;
        const finalY = parseInt(this.el.style.top) || 0;
        this.pushEvent("move_overlay", {
          id: this.el.dataset.id,
          x: Math.round(finalX),
          y: Math.round(finalY),
        });
      }

      if (this.isResizing) {
        const finalWidth = parseInt(this.el.style.width) || 0;
        const finalHeight = parseInt(this.el.style.height) || 0;
        this.pushEvent("resize_overlay", {
          id: this.el.dataset.id,
          width: Math.round(finalWidth),
          height: Math.round(finalHeight),
        });
      }
    } else {
      // If no dragging/resizing occurred, this was a click - let the click event bubble up
      console.log("Click detected on overlay:", this.el.dataset.id);
    }

    this.isDragging = false;
    this.isResizing = false;
    this.hasMoved = false;
  },

  destroyed() {
    document.removeEventListener("mousemove", this.handleMouseMove.bind(this));
    document.removeEventListener("mouseup", this.handleMouseUp.bind(this));
  },
};

export default DraggableResizableOverlay;
