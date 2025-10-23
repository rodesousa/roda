import MarkdownIt from 'markdown-it'

const md = new MarkdownIt({
  html: true,
  linkify: true,
  typographer: true,
  breaks: true,
})

export const MarkdownCitations = {
  mounted() {
    this.render()
  },

  updated() {
    this.render()
  },

  render() {
    const content = this.el.dataset.content
    const citationMap = JSON.parse(this.el.dataset.citationMap || '{}')
    const modalsHtml = this.el.dataset.modalsHtml || ''

    if (!content) return

    // 1. Render markdown
    let html = md.render(content)

    // 2. Replace [cite:...] with clickable badges
    html = this.replaceCitations(html, citationMap)

    // 3. Inject HTML + modals
    this.el.innerHTML = html + modalsHtml
  },

  replaceCitations(html, citationMap) {
    // Regex pour capturer [cite:uuid1,uuid2,...]
    const regex = /\[cite:([\w\-,]+)\]/g

    return html.replace(regex, (match, idsString) => {
      const modalId = citationMap[idsString]

      if (!modalId) {
        return '<span class="text-error text-xs">?</span>'
      }

      // Count number of sources
      const count = idsString.split(',').length

      // Generate clickable badge that opens the modal
      return `<span class="cursor-pointer text-primary hover:underline ml-1" onclick="${modalId}.showModal()">${count}</span>`
    })
  },
}
