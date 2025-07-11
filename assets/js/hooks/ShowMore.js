export default {
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
