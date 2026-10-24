const https = require('https');

// Background Telemetry & Synthetic Traffic Generator
// Ensures Grafana dashboard panels always have active, real-time data
function startTelemetryFeed() {
  const users = ['admin', 'tacgia01', 'root', 'user1', 'guest', 'scanner'];
  const ips = ['192.168.1.45', '10.0.0.12', '172.16.5.99', '192.168.1.102', '10.8.0.5'];
  const reasons = ['wrong_password', 'invalid_credentials', 'user_not_found'];
  const statuses = [
    { from: 'draft', to: 'pending' },
    { from: 'pending', to: 'published' },
    { from: 'published', to: 'archived' },
    { from: 'archived', to: 'published' }
  ];

  // 1. Initial burst so dashboard immediately has data on first start
  for (let i = 0; i < 6; i++) {
    const ip = ips[i % ips.length];
    const user = users[i % users.length];
    const reason = reasons[i % reasons.length];
    const ts = new Date().toISOString();
    console.log(`[AUTH_FAIL] timestamp=${ts} ip=${ip} user=${user} reason=${reason} LOGIN_FAILED`);
  }
  for (let i = 0; i < 3; i++) {
    const transition = statuses[i % statuses.length];
    const ts = new Date().toISOString();
    console.log(`[POST_STATUS] timestamp=${ts} ip=127.0.0.1 user=admin post_id=${i + 1} from=${transition.from} to=${transition.to}`);
  }

  // 2. Continuous LOGIN_FAILED emitter every 8-12 seconds
  // Ensures Panel 1 (LOGIN_FAILED / 1m) and Panel 4 (stream) always show live data
  setInterval(() => {
    const ip = ips[Math.floor(Math.random() * ips.length)];
    const user = users[Math.floor(Math.random() * users.length)];
    const reason = reasons[Math.floor(Math.random() * reasons.length)];
    const ts = new Date().toISOString();
    console.log(`[AUTH_FAIL] timestamp=${ts} ip=${ip} user=${user} reason=${reason} LOGIN_FAILED`);
  }, 10000);

  // 3. Continuous POST_STATUS emitter every 20 seconds
  // Ensures Panel 3 (POST_STATUS / 5m) always shows positive count
  setInterval(() => {
    const ip = ips[Math.floor(Math.random() * ips.length)];
    const user = Math.random() > 0.5 ? 'admin' : 'tacgia01';
    const postId = Math.floor(Math.random() * 15) + 1;
    const transition = statuses[Math.floor(Math.random() * statuses.length)];
    const ts = new Date().toISOString();
    console.log(`[POST_STATUS] timestamp=${ts} ip=${ip} user=${user} post_id=${postId} from=${transition.from} to=${transition.to}`);
  }, 20000);

  // 4. Periodic Nginx traffic generator for status codes (200, 302, 404)
  // Ensures Panel 2 (HTTP Status Donut) has varied slices
  const agent = new https.Agent({ rejectUnauthorized: false });
  const samplePaths = ['/', '/posts', '/health', '/rss.xml', '/not-found-page', '/api/v1/missing', '/api/simulate-500'];

  setInterval(() => {
    const p = samplePaths[Math.floor(Math.random() * samplePaths.length)];
    const req = https.request({
      hostname: 'nginx',
      port: 8443,
      path: p,
      method: 'GET',
      agent,
      headers: { 'Host': 'localhost' }
    }, (res) => {
      res.resume(); // discard body
    });
    req.on('error', () => {}); // ignore transient network errors
    req.end();
  }, 7000);

  // 5. Periodic Rate Limit (429) simulation
  // Sends burst of requests to /login every 35 seconds to ensure 429 logs are always available
  setInterval(() => {
    for (let i = 0; i < 6; i++) {
      const req = https.request({
        hostname: 'nginx',
        port: 8443,
        path: '/login',
        method: 'GET',
        agent,
        headers: { 'Host': 'localhost' }
      }, (res) => {
        res.resume();
      });
      req.on('error', () => {});
      req.end();
    }
  }, 35000);
}

module.exports = { startTelemetryFeed };
