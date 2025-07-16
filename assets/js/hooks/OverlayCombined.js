const OverlayCombined = {
  mounted() {
    console.log("🔧 OverlayCombined mounted for element:", this.el.dataset.id);

    // Add visual indicator that hook is working
    this.el.style.cursor = "grab";
    this.el.addEventListener("mouseenter", () => {
      this.el.style.cursor = "grab";
    });
    this.el.addEventListener("mouseleave", () => {
      this.el.style.cursor = "grab";
    });

    // Double-click to open properties
    this.el.addEventListener("dblclick", (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.pushEvent("select_canvas_overlay", { id: this.el.dataset.id });
    });

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

  // Helper method to get video bounds
  getVideoBounds() {
    const canvasContainer = this.el.closest('[data-video-container="true"]');
    if (!canvasContainer) return null;

    const videoEl = canvasContainer.querySelector("video");
    if (!videoEl) return null;

    const videoRect = videoEl.getBoundingClientRect();
    const containerRect = canvasContainer.getBoundingClientRect();

    // Calculate offset of video inside container
    const offsetX = videoRect.left - containerRect.left;
    const offsetY = videoRect.top - containerRect.top;
    const videoWidth = videoRect.width;
    const videoHeight = videoRect.height;

    return {
      offsetX,
      offsetY,
      videoWidth,
      videoHeight,
      containerRect,
    };
  },

  // Helper method to constrain position to video bounds
  constrainPosition(x, y, width, height) {
    const bounds = this.getVideoBounds();
    if (!bounds) return { x, y };

    const { offsetX, offsetY, videoWidth, videoHeight } = bounds;

    // Constrain to video area
    const minX = offsetX;
    const minY = offsetY;
    const maxX = offsetX + videoWidth - width;
    const maxY = offsetY + videoHeight - height;

    const constrainedX = Math.max(minX, Math.min(x, maxX));
    const constrainedY = Math.max(minY, Math.min(y, maxY));

    return { x: constrainedX, y: constrainedY };
  },

  // Helper method to constrain size to video bounds
  constrainSize(width, height, currentX, currentY) {
    const bounds = this.getVideoBounds();
    if (!bounds) return { width, height };

    const { offsetX, offsetY, videoWidth, videoHeight } = bounds;

    // Ensure minimum size
    const minWidth = 20;
    const minHeight = 20;

    // Calculate maximum size based on current position
    const maxWidth = offsetX + videoWidth - currentX;
    const maxHeight = offsetY + videoHeight - currentY;

    const constrainedWidth = Math.max(minWidth, Math.min(width, maxWidth));
    const constrainedHeight = Math.max(minHeight, Math.min(height, maxHeight));

    return { width: constrainedWidth, height: constrainedHeight };
  },

  handleMouseDown(e) {
    console.log("🖱️ Mouse down on overlay:", this.el.dataset.id);

    const canvasContainer = this.el.closest('[data-video-container="true"]');
    if (!canvasContainer) {
      console.error("❌ Canvas container not found");
      return;
    }
    console.log("✅ Canvas container found:", canvasContainer);

    const canvasRect = canvasContainer.getBoundingClientRect();
    const overlayRect = this.el.getBoundingClientRect();
    this.originalX = parseInt(this.el.style.left) || 0;
    this.originalY = parseInt(this.el.style.top) || 0;
    this.startX = e.clientX - canvasRect.left;
    this.startY = e.clientY - canvasRect.top;

    console.log("📍 Starting position:", {
      x: this.originalX,
      y: this.originalY,
    });
    console.log("📍 Mouse position:", { x: this.startX, y: this.startY });

    const handleSize = 8;
    const isResizeHandle =
      e.clientX > overlayRect.right - handleSize &&
      e.clientX < overlayRect.right + handleSize &&
      e.clientY > overlayRect.bottom - handleSize &&
      e.clientY < overlayRect.bottom + handleSize;

    if (isResizeHandle) {
      console.log("🔧 Starting resize");
      this.isResizing = true;
      e.preventDefault();
      e.stopPropagation();
      this.startWidth = parseInt(this.el.style.width) || overlayRect.width;
      this.startHeight = parseInt(this.el.style.height) || overlayRect.height;
      this.lastSentWidth = this.startWidth;
      this.lastSentHeight = this.startHeight;
      this.el.style.cursor = "nwse-resize";
    } else {
      console.log("🎯 Starting drag");
      this.isDragging = true;
      this.hasMoved = false;
      e.preventDefault();
      e.stopPropagation();
      this.lastSentX = this.originalX;
      this.lastSentY = this.originalY;
      this.el.style.cursor = "grabbing";
      document.body.style.cursor = "grabbing";
    }
  },

  handleMouseMove(e) {
    if (!this.isDragging && !this.isResizing) return;

    const bounds = this.getVideoBounds();
    if (!bounds) return;

    const { containerRect } = bounds;

    if (this.isDragging) {
      const newX =
        e.clientX - containerRect.left - (this.startX - this.originalX);
      const newY =
        e.clientY - containerRect.top - (this.startY - this.originalY);

      const overlayWidth = parseInt(this.el.style.width) || this.el.offsetWidth;
      const overlayHeight =
        parseInt(this.el.style.height) || this.el.offsetHeight;

      // Constrain position to video bounds
      const { x: constrainedX, y: constrainedY } = this.constrainPosition(
        newX,
        newY,
        overlayWidth,
        overlayHeight
      );

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
      const deltaWidth = e.clientX - containerRect.left - this.startX;
      const deltaHeight = e.clientY - containerRect.top - this.startY;

      const newWidth = this.startWidth + deltaWidth;
      const newHeight = this.startHeight + deltaHeight;

      const currentX = parseInt(this.el.style.left) || 0;
      const currentY = parseInt(this.el.style.top) || 0;

      // Constrain size to video bounds
      const { width: constrainedWidth, height: constrainedHeight } =
        this.constrainSize(newWidth, newHeight, currentX, currentY);

      this.el.style.width = constrainedWidth + "px";
      this.el.style.height = constrainedHeight + "px";

      // If this is a text overlay, dynamically scale font size
      const isText =
        this.el.getAttribute("data-type") === "text" ||
        this.el.classList.contains("text-overlay");

      let fontSize = Math.round(constrainedHeight);
      if (isText) {
        const text = this.el.textContent;
        const fontFamily =
          window.getComputedStyle(this.el).fontFamily || "sans-serif";
        fontSize = this.calculateMaxFontSize(
          text,
          fontFamily,
          constrainedWidth,
          constrainedHeight
        );
        this.el.style.fontSize = fontSize + "px";
      }

      if (
        Math.abs(constrainedWidth - this.lastSentWidth) > 2 ||
        Math.abs(constrainedHeight - this.lastSentHeight) > 2
      ) {
        const payload = {
          id: this.el.dataset.id,
          width: Math.round(constrainedWidth),
          height: Math.round(constrainedHeight),
        };
        if (isText) {
          payload.font_size = fontSize;
        }
        this.pushEvent("resize_overlay", payload);
        this.lastSentWidth = constrainedWidth;
        this.lastSentHeight = constrainedHeight;
      }
    }
  },

  handleMouseUp(e) {
    if (this.isDragging || this.isResizing) {
      console.log("🛑 Stopping drag/resize");

      if (this.isDragging && this.hasMoved) {
        const finalX = parseInt(this.el.style.left) || 0;
        const finalY = parseInt(this.el.style.top) || 0;
        console.log("✅ Final position:", { x: finalX, y: finalY });
        this.pushEvent("move_overlay", {
          id: this.el.dataset.id,
          x: Math.round(finalX),
          y: Math.round(finalY),
        });
      }

      if (this.isResizing) {
        const finalWidth = parseInt(this.el.style.width) || 0;
        const finalHeight = parseInt(this.el.style.height) || 0;
        console.log("✅ Final size:", {
          width: finalWidth,
          height: finalHeight,
        });
        const isText =
          this.el.getAttribute("data-type") === "text" ||
          this.el.classList.contains("text-overlay");
        let fontSize = Math.round(finalHeight);
        if (isText) {
          const text = this.el.textContent;
          const fontFamily =
            window.getComputedStyle(this.el).fontFamily || "sans-serif";
          fontSize = this.calculateMaxFontSize(
            text,
            fontFamily,
            finalWidth,
            finalHeight
          );
          this.el.style.fontSize = fontSize + "px";
        }
        const payload = {
          id: this.el.dataset.id,
          width: Math.round(finalWidth),
          height: Math.round(finalHeight),
        };
        if (isText) {
          payload.font_size = fontSize;
        }
        this.pushEvent("resize_overlay", payload);
      }
    } else {
      // If no dragging/resizing occurred, this was a click - select the overlay
      console.log("👆 Click detected on overlay:", this.el.dataset.id);
      this.pushEvent("select_canvas_overlay", {
        id: this.el.dataset.id,
      });
    }

    // Reset cursors
    this.el.style.cursor = "grab";
    document.body.style.cursor = "";

    this.isDragging = false;
    this.isResizing = false;
    this.hasMoved = false;
  },

  destroyed() {
    document.removeEventListener("mousemove", this.handleMouseMove.bind(this));
    document.removeEventListener("mouseup", this.handleMouseUp.bind(this));
  },

  // Utility: Calculate max font size that fits text in given width/height
  calculateMaxFontSize(
    text,
    fontFamily,
    maxWidth,
    maxHeight,
    fontWeight = "bold"
  ) {
    // Create a hidden span for measurement
    let span = document.getElementById("font-measure-span");
    if (!span) {
      span = document.createElement("span");
      span.id = "font-measure-span";
      span.style.position = "absolute";
      span.style.visibility = "hidden";
      span.style.whiteSpace = "normal";
      span.style.wordBreak = "break-word";
      span.style.left = "-9999px";
      span.style.top = "-9999px";
      document.body.appendChild(span);
    }
    span.style.fontFamily = fontFamily;
    span.style.fontWeight = fontWeight;
    span.textContent = text || "Text";
    span.style.width = maxWidth + "px";

    // Binary search for max font size
    let min = 4;
    let max = Math.floor(maxHeight);
    let best = min;
    while (min <= max) {
      let mid = Math.floor((min + max) / 2);
      span.style.fontSize = mid + "px";
      const { width, height } = span.getBoundingClientRect();
      if (width <= maxWidth && height <= maxHeight) {
        best = mid;
        min = mid + 1;
      } else {
        max = mid - 1;
      }
    }
    return best;
  },
};

export default OverlayCombined;
