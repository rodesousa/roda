import flatpickr from "flatpickr";
import { French } from "flatpickr/dist/l10n/fr.js";

export const Flatpickr = {
  mounted() {
    flatpickr(this.el, {
      mode: "range",
      dateFormat: "d/m/Y",
      locale: French,
      onChange: (selectedDates, dateStr, instance) => {
        if (selectedDates.length === 2) {
          this.pushEvent("date_range_selected", {
            begin_at: selectedDates[0].toISOString(),
            end_at: selectedDates[1].toISOString(),
            formatted: dateStr
          });
        }
      }
    });
  },

  destroyed() {
    // Cleanup quand le hook est détruit
    if (this.el._flatpickr) {
      this.el._flatpickr.destroy();
    }
  }
}
