const OverlayContextMenu = {
  mounted() {
    this.el.addEventListener("contextmenu", (e) => {
      e.preventDefault();
      this.pushEvent("show_context_menu", {
        id: this.el.dataset.id,
        x: e.clientX,
        y: e.clientY,
      });
    });
  },
};

export default OverlayContextMenu;
