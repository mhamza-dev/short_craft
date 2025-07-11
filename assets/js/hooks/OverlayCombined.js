const OverlayCombined = {
  mounted() {
    // DraggableResizableOverlay logic
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
    this.hasMoved = false;

    this.el.addEventListener("mousedown", this.handleMouseDown.bind(this));
    document.addEventListener("mousemove", this.handleMouseMove.bind(this));
    document.addEventListener("mouseup", this.handleMouseUp.bind(this));

    // OverlayContextMenu logic
    this.el.addEventListener("contextmenu", (e) => {
      e.preventDefault();
      this.pushEvent("show_context_menu", {
        id: this.el.dataset.id,
        x: e.clientX,
        y: e.clientY,
      });
    });
  },

  handleMouseDown(e) {
    // ... DraggableResizableOverlay handleMouseDown logic ...
    const canvasContainer = this.el.closest('[data-video-container="true"]');
    if (!canvasContainer) {
      console.log("Canvas container not found");
      return;
    }
    console.log("Overlay mouse down:", this.el.dataset.id);
    const canvasRect = canvasContainer.getBoundingClientRect();
    const overlayRect = this.el.getBoundingClientRect();
    this.originalX = parseInt(this.el.style.left) || 0;
    this.originalY = parseInt(this.el.style.top) || 0;
    this.startX = e.clientX - canvasRect.left;
    this.startY = e.clientY - canvasRect.top;
    const handleSize = 8;
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
      console.log("Starting drag");
      this.isDragging = true;
      this.hasMoved = false;
      e.preventDefault();
      e.stopPropagation();
      this.lastSentX = this.originalX;
      this.lastSentY = this.originalY;
    }
  },

  handleMouseMove(e) {
    if (!this.isDragging && !this.isResizing) return;
    const canvasContainer = this.el.closest('[data-video-container="true"]');
    if (!canvasContainer) return;
    const canvasRect = canvasContainer.getBoundingClientRect();
    if (this.isDragging) {
      const newX = e.clientX - canvasRect.left - (this.startX - this.originalX);
      const newY = e.clientY - canvasRect.top - (this.startY - this.originalY);
      const maxX =
        canvasRect.width -
        (parseInt(this.el.style.width) || this.el.offsetWidth);
      const maxY =
        canvasRect.height -
        (parseInt(this.el.style.height) || this.el.offsetHeight);
      const constrainedX = Math.max(0, Math.min(newX, maxX));
      const constrainedY = Math.max(0, Math.min(newY, maxY));
      if (
        Math.abs(constrainedX - this.originalX) > 2 ||
        Math.abs(constrainedY - this.originalY) > 2
      ) {
        this.hasMoved = true;
      }
      this.el.style.left = constrainedX + "px";
      this.el.style.top = constrainedY + "px";
      if (
        Math.abs(constrainedX - this.lastSentX) > 2 ||
        Math.abs(constrainedY - this.lastSentY) > 2
      ) {
        console.log("Moving overlay:", {
          x: Math.round(constrainedX),
          y: Math.round(constrainedY),
        });
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
      this.el.style.width = newWidth + "px";
      this.el.style.height = newHeight + "px";
      if (
        Math.abs(newWidth - this.lastSentWidth) > 2 ||
        Math.abs(newHeight - this.lastSentHeight) > 2
      ) {
        console.log("Resizing overlay:", {
          width: Math.round(newWidth),
          height: Math.round(newHeight),
        });
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

export default OverlayCombined;
