const https = require('https');

const queries = [
  {
    panel: 1,
    title: 'Tần suất Đăng nhập Thất bại (LOGIN_FAILED / 1m)',
    expr: 'sum(count_over_time({job="webapp"} |= "LOGIN_FAILED" [1m]))',
    queryType: 'range'
  },
  {
    panel: 2,
    title: 'Phân bố Mã Trạng thái HTTP Nginx (5m)',
    expr: 'sum by (status) (count_over_time({job="nginx"} [5m]))',
    queryType: 'range'
  },
  {
    panel: 3,
    title: 'Hoạt động Duyệt bài (POST_STATUS / 5m)',
    expr: 'sum(count_over_time({job="webapp"} |= "POST_STATUS" [5m]))',
    queryType: 'range'
  },
  {
    panel: 4,
    title: 'Sự kiện Đăng nhập Thất bại ({job="webapp"} |= "LOGIN_FAILED")',
    expr: '{job="webapp"} |= "LOGIN_FAILED"',
    queryType: 'range'
  },
  {
    panel: 5,
    title: 'Toàn bộ Nhật ký Ứng dụng Web ({job="webapp"})',
    expr: '{job="webapp"}',
    queryType: 'range'
  }
];

function testQuery(q) {
  return new Promise((resolve) => {
    const payload = JSON.stringify({
      queries: [{
        refId: 'A',
        datasource: { type: 'loki', uid: 'loki' },
        expr: q.expr,
        queryType: q.queryType
      }],
      from: 'now-30m',
      to: 'now'
    });

    const req = https.request({
      hostname: 'localhost',
      port: 443,
      path: '/grafana/api/ds/query',
      method: 'POST',
      rejectUnauthorized: false,
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'https://localhost',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          const frameCount = json.results?.A?.frames?.length || 0;
          let rowCount = 0;
          if (frameCount > 0) {
            json.results.A.frames.forEach(f => {
              rowCount += (f.data?.values?.[0]?.length || 0);
            });
          }
          resolve({
            panel: q.panel,
            title: q.title,
            status: res.statusCode,
            frames: frameCount,
            rows: rowCount,
            ok: res.statusCode === 200 && (frameCount > 0 || rowCount > 0)
          });
        } catch (e) {
          resolve({ panel: q.panel, title: q.title, status: res.statusCode, error: e.message });
        }
      });
    });

    req.on('error', (err) => resolve({ panel: q.panel, title: q.title, error: err.message }));
    req.write(payload);
    req.end();
  });
}

async function run() {
  console.log('=== KIỂM TRA DỮ LIỆU CẢ 5 PANEL TRÊN GRAFANA DASHBOARD ===\n');
  for (const q of queries) {
    const res = await testQuery(q);
    console.log(`Panel ${res.panel}: "${res.title}"`);
    console.log(`  -> HTTP Status: ${res.status}`);
    console.log(`  -> Số frames: ${res.frames} | Số rows/datapoints: ${res.rows}`);
    console.log(`  -> Kết quả: ${res.ok ? '✅ CÓ DỮ LIỆU HIỂN THỊ' : '⚠️ CẦN THÊM DỮ LIỆU'}\n`);
  }
}

run();
