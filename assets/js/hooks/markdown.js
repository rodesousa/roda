import MarkdownIt from "markdown-it"
import DOMPurify from "dompurify"

const md = new MarkdownIt({
  html: false,  // Disable raw HTML for security
  linkify: true,
  typographer: true,
  breaks: true,
})

export const Markdown = {
  mounted() {
    this.render()
  },

  updated() {
    this.render()
  },

  render() {
    const content = this.el.dataset.content
    if (content) {
      const rendered = md.render(content)
      // Sanitize HTML to prevent XSS attacks
      this.el.innerHTML = DOMPurify.sanitize(rendered, {
        ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'u', 's', 'code', 'pre', 'blockquote', 'ul', 'ol', 'li', 'a', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'table', 'thead', 'tbody', 'tr', 'th', 'td'],
        ALLOWED_ATTR: ['href', 'title', 'target', 'rel', 'class']
      })
    }
  },
}
