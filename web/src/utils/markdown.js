const MarkdownIt = require('markdown-it');
const sanitizeHtml = require('sanitize-html');

const md = new MarkdownIt({
  html: false, // Do NOT allow raw HTML in markdown source
  xhtmlOut: true,
  breaks: true,
  linkify: true
});

const sanitizeOptions = {
  allowedTags: [
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'p', 'a', 'b', 'i', 'strong', 'em', 'strike',
    'code', 'hr', 'br', 'ul', 'ol', 'li', 'blockquote', 'pre',
    'img', 'table', 'thead', 'tbody', 'tr', 'th', 'td'
  ],
  allowedAttributes: {
    a: ['href', 'title', 'rel', 'target'],
    img: ['src', 'alt', 'title', 'width', 'height'],
    code: ['class']
  },
  allowedSchemes: ['http', 'https', 'mailto'],
  transformTags: {
    a: (tagName, attribs) => {
      let href = attribs.href || '';
      // Block javascript: and data:
      if (/^\s*(javascript:|data:)/i.test(href)) {
        return { tagName: 'span', text: attribs.title || href };
      }
      // Add secure rel to external links
      if (/^https?:\/\//i.test(href)) {
        attribs.rel = 'noopener noreferrer nofollow';
        attribs.target = '_blank';
      }
      return { tagName: 'a', attribs };
    },
    img: (tagName, attribs) => {
      let src = attribs.src || '';
      // Only allow local images (/uploads/ or /images/)
      if (!src.startsWith('/uploads/') && !src.startsWith('/images/')) {
        return { tagName: 'span', text: `[Ảnh không được phép: ${attribs.alt || ''}]` };
      }
      return { tagName: 'img', attribs };
    }
  }
};

function renderMarkdown(content) {
  if (!content) return '';
  const rawHtml = md.render(content);
  return sanitizeHtml(rawHtml, sanitizeOptions);
}

module.exports = {
  renderMarkdown
};