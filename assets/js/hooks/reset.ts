export const ResetForm = {
  mounted() {
    this.handleEvent("reset-form", () => {
      this.el.reset()
    })
  }
}

