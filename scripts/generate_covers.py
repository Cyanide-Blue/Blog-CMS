import os

covers_dir = os.path.expanduser("~/blogcms/web/public/images/covers")
os.makedirs(covers_dir, exist_ok=True)

covers = [
    (1, "Cong nghe", "Kien truc Microservices hien dai", "#1e3a8a", "#3b82f6"),
    (2, "Lap trinh", "Lam chu Node.js va Event Loop", "#065f46", "#10b981"),
    (3, "DevOps", "Trien khai Docker Compose chuan Production", "#831843", "#ec4899"),
    (4, "Doi song sinh vien", "Ky nang quan ly thoi gian cho sinh vien IT", "#7c2d12", "#f97316"),
    (5, "Thu thuat", "Toi uu hoa truy van PostgreSQL thuc chien", "#4c1d95", "#8b5cf6"),
    (6, "Cong nghe", "Xu huong AI va Machine Learning 2026", "#1e3a8a", "#2563eb"),
    (7, "Lap trinh", "Clean Code va Refactoring trong JavaScript", "#065f46", "#059669"),
    (8, "DevOps", "Giam sat he thong voi Prometheus va Grafana", "#831843", "#db2777"),
    (9, "Doi song sinh vien", "Hanh trang phong van thuc tap sinh DevOps", "#7c2d12", "#ea580c"),
    (10, "Thu thuat", "Bao mat Web voi HTTPS va Security Headers", "#4c1d95", "#7c3aed"),
    (11, "Cong nghe", "Kien truc Event-Driven voi Message Queue", "#1e3a8a", "#1d4ed8"),
    (12, "Lap trinh", "Xay dung RESTful API chuan OpenAPI", "#065f46", "#047857"),
    (13, "DevOps", "Quan ly Log tap trung voi Loki va Promtail", "#831843", "#be185d"),
    (14, "Doi song sinh vien", "Can bang giua hoc tap va du an ca nhan", "#7c2d12", "#c2410c"),
    (15, "Thu thuat", "Ky thuat Docker Multi-Stage Build sieu nhe", "#4c1d95", "#6d28d9"),
]

for num, cat, title, c1, c2 in covers:
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 450" width="100%" height="100%">
  <defs>
    <linearGradient id="grad_{num}" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{c1};stop-opacity:1" />
      <stop offset="100%" style="stop-color:{c2};stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="800" height="450" fill="url(#grad_{num})" />
  <circle cx="720" cy="80" r="140" fill="rgba(255,255,255,0.08)" />
  <circle cx="80" cy="380" r="180" fill="rgba(255,255,255,0.05)" />
  <rect x="60" y="60" width="150" height="34" rx="17" fill="rgba(255,255,255,0.2)" />
  <text x="135" y="82" fill="#ffffff" font-size="13" font-family="system-ui, sans-serif" font-weight="bold" text-anchor="middle">{cat.upper()}</text>
  <text x="60" y="210" fill="#ffffff" font-size="28" font-family="system-ui, sans-serif" font-weight="bold">
    <tspan x="60" dy="0">{title}</tspan>
  </text>
  <text x="60" y="380" fill="rgba(255,255,255,0.8)" font-size="14" font-family="system-ui, sans-serif">Hệ thống Blog / CMS &bull; DTC245180035</text>
</svg>"""
    with open(os.path.join(covers_dir, f"cover-{num}.svg"), "w", newline="\n", encoding="utf-8") as f:
        f.write(svg)

print("Generated 15 covers successfully")
