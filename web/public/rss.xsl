<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="4.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <html lang="vi">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title><xsl:value-of select="/rss/channel/title"/> - Nguồn cấp tin RSS</title>
        <link rel="preconnect" href="https://fonts.googleapis.com"/>
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin=""/>
        <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;family=JetBrains+Mono:wght@400;500;600&amp;display=swap" rel="stylesheet"/>
        <style><![CDATA[
:root {
            --bg-base: #090d16;
            --bg-card: rgba(17, 24, 39, 0.75);
            --bg-card-hover: rgba(24, 33, 53, 0.85);
            --border: rgba(255, 255, 255, 0.08);
            --border-hover: rgba(249, 115, 22, 0.4);
            --text-main: #f1f5f9;
            --text-muted: #94a3b8;
            --primary: #f97316;
            --primary-glow: rgba(249, 115, 22, 0.25);
            --accent-cyan: #06b6d4;
            --accent-indigo: #6366f1;
            --font-sans: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif;
            --font-mono: 'JetBrains Mono', monospace;
          }

          * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
          }

          body {
            background-color: var(--bg-base);
            background-image: 
              radial-gradient(at 10% 10%, rgba(99, 102, 241, 0.12) 0px, transparent 50%),
              radial-gradient(at 90% 20%, rgba(249, 115, 22, 0.1) 0px, transparent 45%),
              radial-gradient(at 50% 80%, rgba(6, 182, 212, 0.08) 0px, transparent 50%);
            color: var(--text-main);
            font-family: var(--font-sans);
            line-height: 1.6;
            min-height: 100vh;
            padding: 2.5rem 1rem 4rem;
          }

          .container {
            max-width: 960px;
            margin: 0 auto;
          }

          /* Top Nav & Breadcrumb */
          .top-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 2rem;
            padding-bottom: 1.25rem;
            border-bottom: 1px solid var(--border);
          }

          .back-link {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            color: var(--text-muted);
            text-decoration: none;
            font-size: 0.875rem;
            font-weight: 500;
            padding: 0.4rem 0.85rem;
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid var(--border);
            transition: all 0.2s ease;
          }

          .back-link:hover {
            color: #fff;
            background: rgba(255, 255, 255, 0.08);
            border-color: rgba(255, 255, 255, 0.2);
            transform: translateX(-2px);
          }

          .badge-student {
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            font-family: var(--font-mono);
            font-size: 0.75rem;
            color: #cbd5e1;
            background: rgba(99, 102, 241, 0.15);
            border: 1px solid rgba(99, 102, 241, 0.3);
            padding: 0.35rem 0.75rem;
            border-radius: 9999px;
          }

          /* Hero / Channel Header Card */
          .feed-hero {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 2.25rem;
            margin-bottom: 2.5rem;
            box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.5), 0 0 25px var(--primary-glow);
            position: relative;
            overflow: hidden;
          }

          .feed-hero::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, #f97316, #6366f1, #06b6d4);
          }

          .hero-header {
            display: flex;
            align-items: flex-start;
            gap: 1.25rem;
            margin-bottom: 1.25rem;
          }

          .rss-icon-wrapper {
            width: 56px;
            height: 56px;
            border-radius: 14px;
            background: linear-gradient(135deg, #f97316, #ea580c);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            box-shadow: 0 8px 20px rgba(249, 115, 22, 0.35);
          }

          .rss-icon-wrapper svg {
            width: 30px;
            height: 30px;
            fill: #fff;
          }

          .hero-title-group h1 {
            font-size: 1.625rem;
            font-weight: 800;
            letter-spacing: -0.02em;
            color: #fff;
            margin-bottom: 0.25rem;
          }

          .hero-title-group p {
            color: var(--text-muted);
            font-size: 0.95rem;
          }

          /* Notice Callout Box */
          .notice-box {
            background: rgba(249, 115, 22, 0.08);
            border: 1px solid rgba(249, 115, 22, 0.25);
            border-radius: 12px;
            padding: 1rem 1.25rem;
            margin: 1.5rem 0;
            display: flex;
            align-items: flex-start;
            gap: 0.75rem;
            font-size: 0.875rem;
            color: #fed7aa;
            line-height: 1.5;
          }

          .notice-box svg {
            width: 20px;
            height: 20px;
            fill: #f97316;
            flex-shrink: 0;
            margin-top: 2px;
          }

          /* Copy URL Bar */
          .copy-bar {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            background: rgba(0, 0, 0, 0.35);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            padding: 0.4rem 0.5rem 0.4rem 1rem;
            margin-top: 1.25rem;
          }

          .copy-bar input {
            background: transparent;
            border: none;
            color: #cbd5e1;
            font-family: var(--font-mono);
            font-size: 0.85rem;
            width: 100%;
            outline: none;
          }

          .copy-btn {
            background: #f97316;
            color: #fff;
            border: none;
            padding: 0.45rem 1rem;
            border-radius: 7px;
            font-size: 0.8125rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            white-space: nowrap;
          }

          .copy-btn:hover {
            background: #ea580c;
            box-shadow: 0 4px 12px rgba(249, 115, 22, 0.3);
          }

          /* Feed Stats Grid */
          .stats-strip {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
            gap: 1rem;
            margin-top: 1.5rem;
            padding-top: 1.25rem;
            border-top: 1px solid var(--border);
          }

          .stat-item {
            font-size: 0.8125rem;
          }

          .stat-label {
            color: var(--text-muted);
            text-transform: uppercase;
            font-size: 0.7rem;
            font-weight: 700;
            letter-spacing: 0.05em;
            margin-bottom: 0.2rem;
          }

          .stat-value {
            color: #f1f5f9;
            font-weight: 600;
            font-family: var(--font-mono);
          }

          /* Items Section Heading */
          .section-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 1.5rem;
          }

          .section-title {
            font-size: 1.25rem;
            font-weight: 700;
            color: #fff;
            display: flex;
            align-items: center;
            gap: 0.6rem;
          }

          .items-count {
            background: rgba(255, 255, 255, 0.08);
            color: #cbd5e1;
            font-size: 0.75rem;
            font-weight: 600;
            padding: 0.2rem 0.6rem;
            border-radius: 9999px;
            font-family: var(--font-mono);
          }

          /* Articles List */
          .articles-list {
            display: flex;
            flex-direction: column;
            gap: 1.25rem;
          }

          .article-card {
            background: var(--bg-card);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 1.5rem 1.75rem;
            transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
            position: relative;
          }

          .article-card:hover {
            background: var(--bg-card-hover);
            border-color: var(--border-hover);
            transform: translateY(-2px);
            box-shadow: 0 12px 24px -10px rgba(0, 0, 0, 0.5), 0 0 15px rgba(249, 115, 22, 0.15);
          }

          .article-meta-top {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            margin-bottom: 0.6rem;
            flex-wrap: wrap;
          }

          .category-tag {
            background: rgba(6, 182, 212, 0.12);
            color: var(--accent-cyan);
            border: 1px solid rgba(6, 182, 212, 0.3);
            font-size: 0.75rem;
            font-weight: 600;
            padding: 0.18rem 0.65rem;
            border-radius: 6px;
          }

          .article-date {
            color: var(--text-muted);
            font-size: 0.8125rem;
            font-family: var(--font-mono);
          }

          .article-title {
            font-size: 1.2rem;
            font-weight: 700;
            line-height: 1.4;
            margin-bottom: 0.6rem;
          }

          .article-title a {
            color: #fff;
            text-decoration: none;
            transition: color 0.2s ease;
          }

          .article-title a:hover {
            color: var(--primary);
          }

          .article-desc {
            color: #94a3b8;
            font-size: 0.925rem;
            line-height: 1.55;
            margin-bottom: 1rem;
          }

          .article-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-top: 0.85rem;
            border-top: 1px solid rgba(255, 255, 255, 0.05);
            font-size: 0.8125rem;
          }

          .author-info {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            color: #cbd5e1;
            font-weight: 500;
          }

          .author-avatar {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            background: linear-gradient(135deg, #6366f1, #06b6d4);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.65rem;
            font-weight: 700;
            color: #fff;
          }

          .read-btn {
            display: inline-flex;
            align-items: center;
            gap: 0.3rem;
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
            font-size: 0.85rem;
            transition: all 0.2s ease;
          }

          .read-btn:hover {
            color: #fb923c;
            transform: translateX(3px);
          }

          /* Footer */
          .site-footer {
            text-align: center;
            margin-top: 3.5rem;
            padding-top: 1.5rem;
            border-top: 1px solid var(--border);
            color: var(--text-muted);
            font-size: 0.8125rem;
          }

          .site-footer a {
            color: #cbd5e1;
            text-decoration: none;
          }

          .site-footer a:hover {
            color: #fff;
          }
]]></style>
        <script type="text/javascript"><![CDATA[
function copyRssUrl() {
            var input = document.getElementById('rssUrlInput');
            if (!input) return;
            navigator.clipboard.writeText(input.value).then(function() {
              var btn = document.getElementById('copyBtn');
              if (btn) {
                var oldText = btn.innerText;
                btn.innerText = 'Đã sao chép!';
                btn.style.background = '#10b981';
                setTimeout(function() {
                  btn.innerText = oldText;
                  btn.style.background = '#f97316';
                }, 2000);
              }
            });
          }
]]></script>
      </head>
      <body>
        <div class="container">
          <!-- Top Navigation -->
          <div class="top-bar">
            <a href="/" class="back-link">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="15 18 9 12 15 6"></polyline>
              </svg>
              <span>Trở về Trang chủ Blog</span>
            </a>
            <div class="badge-student">
              <span>Hà Đức Trung • DTC245180035</span>
            </div>
          </div>

          <!-- Hero Feed Banner -->
          <div class="feed-hero">
            <div class="hero-header">
              <div class="rss-icon-wrapper">
                <svg viewBox="0 0 24 24">
                  <path d="M6.18 15.64a2.18 2.18 0 0 1 2.18 2.18C8.36 19 7.38 20 6.18 20C5 20 4 19 4 17.82a2.18 2.18 0 0 1 2.18-2.18M4 4.44A15.56 15.56 0 0 1 19.56 20h-2.83A12.73 12.73 0 0 0 4 7.27V4.44m0 5.66a9.9 9.9 0 0 1 9.9 9.9h-2.83A7.07 7.07 0 0 0 4 12.93V10.1z"/>
                </svg>
              </div>
              <div class="hero-title-group">
                <h1><xsl:value-of select="/rss/channel/title"/></h1>
                <p><xsl:value-of select="/rss/channel/description"/></p>
              </div>
            </div>

            <div class="notice-box">
              <svg viewBox="0 0 24 24">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/>
              </svg>
              <div>
                <strong>Đây là Nguồn cấp tin RSS (Web Feed) chuẩn XML 2.0.</strong> Trình duyệt của bạn đang hiển thị bản xem trước trực quan (XSLT). Bạn có thể sao chép URL bên dưới để theo dõi bài viết mới nhất trên các ứng dụng đọc tin như <em>Feedly</em>, <em>NetNewsWire</em>, <em>Reeder</em>, hoặc <em>Inoreader</em>.
              </div>
            </div>

            <!-- Copy URL Tool -->
            <div class="copy-bar">
              <input type="text" id="rssUrlInput" readonly="readonly">
                <xsl:attribute name="value">
                  <xsl:value-of select="/rss/channel/link"/>/rss.xml
                </xsl:attribute>
              </input>
              <button class="copy-btn" id="copyBtn" onclick="copyRssUrl()">Sao chép URL</button>
            </div>

            <!-- Feed Stats -->
            <div class="stats-strip">
              <div class="stat-item">
                <div class="stat-label">Định dạng</div>
                <div class="stat-value">RSS 2.0 / XML</div>
              </div>
              <div class="stat-item">
                <div class="stat-label">Ngôn ngữ</div>
                <div class="stat-value">
                  <xsl:value-of select="/rss/channel/language"/> (Tiếng Việt)
                </div>
              </div>
              <div class="stat-item">
                <div class="stat-label">Cập nhật lần cuối</div>
                <div class="stat-value">
                  <xsl:value-of select="/rss/channel/lastBuildDate"/>
                </div>
              </div>
              <div class="stat-item">
                <div class="stat-label">Số bài viết cấp tin</div>
                <div class="stat-value">
                  <xsl:value-of select="count(/rss/channel/item)"/> bài
                </div>
              </div>
            </div>
          </div>

          <!-- Section Heading -->
          <div class="section-header">
            <h2 class="section-title">
              <span>Danh Sách Bài Viết Mới Nhất</span>
              <span class="items-count"><xsl:value-of select="count(/rss/channel/item)"/> bài</span>
            </h2>
          </div>

          <!-- Articles Stream -->
          <div class="articles-list">
            <xsl:for-each select="/rss/channel/item">
              <article class="article-card">
                <div class="article-meta-top">
                  <xsl:if test="category != ''">
                    <span class="category-tag"><xsl:value-of select="category"/></span>
                  </xsl:if>
                  <span class="article-date"><xsl:value-of select="pubDate"/></span>
                </div>

                <h3 class="article-title">
                  <a>
                    <xsl:attribute name="href">
                      <xsl:value-of select="link"/>
                    </xsl:attribute>
                    <xsl:value-of select="title"/>
                  </a>
                </h3>

                <p class="article-desc">
                  <xsl:value-of select="description"/>
                </p>

                <div class="article-footer">
                  <div class="author-info">
                    <div class="author-avatar">
                      <xsl:value-of select="substring(author, 1, 1)"/>
                    </div>
                    <span><xsl:value-of select="author"/></span>
                  </div>

                  <a class="read-btn">
                    <xsl:attribute name="href">
                      <xsl:value-of select="link"/>
                    </xsl:attribute>
                    <span>Đọc toàn bài</span>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                      <line x1="5" y1="12" x2="19" y2="12"></line>
                      <polyline points="12 5 19 12 12 19"></polyline>
                    </svg>
                  </a>
                </div>
              </article>
            </xsl:for-each>
          </div>

          <!-- Footer -->
          <footer class="site-footer">
            <p>© 2026 DTC BlogCMS • Triển khai Microservices &amp; Giám sát DevOps</p>
            <p style="margin-top: 0.35rem; color: #64748b;">Sinh viên: Hà Đức Trung • MSSV: DTC245180035</p>
          </footer>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
