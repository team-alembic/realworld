let Hooks = {};

Hooks.TagInput = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.key !== "Enter") {
        return;
      }

      e.preventDefault();

      this.pushEvent("add_tag", { tag: this.el.value }, (reply) => {
        if (reply.tag_added === true) {
          this.el.value = "";
        }
      });
    });
  },
};

export default Hooks;
