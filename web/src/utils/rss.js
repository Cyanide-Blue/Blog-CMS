function escapeXml(unsafe) {
  if (!unsafe) return '';
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function generateRssXml(posts, baseUrl = 'https://localhost') {
  const items = posts.map(post => {
    const postUrl = `${baseUrl}/posts/${post.slug}`;
    const pubDate = post.published_at ? new Date(post.published_at).toUTCString() : new Date().toUTCString();
    return `
    <item>
      <title>${escapeXml(post.title)}</title>
      <link>${postUrl}</link>
      <guid isPermaLink="true">${postUrl}</guid>
      <description>${escapeXml(post.excerpt || '')}</description>
      <category>${escapeXml(post.category_name || '')}</category>
      <author>${escapeXml(post.author_name || '')}</author>
      <pubDate>${pubDate}</pubDate>
    </item>`;
  }).join('');

  return `<?xml version="1.0" encoding="UTF-8" ?>
<?xml-stylesheet type="text/xsl" href="/rss.xsl"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Hệ thống Blog / CMS - DTC245180035</title>
    <link>${baseUrl}</link>
    <description>Hệ thống quản lý nội dung đa tác giả và chia sẻ bài viết công nghệ.</description>
    <language>vi</language>
    <atom:link href="${baseUrl}/rss.xml" rel="self" type="application/rss+xml" />
    <lastBuildDate>${new Date().toUTCString()}</lastBuildDate>
    ${items}
  </channel>
</rss>`;
}

module.exports = {
  generateRssXml
};