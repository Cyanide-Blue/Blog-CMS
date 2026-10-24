const express = require('express');
const router = express.Router();
const db = require('../config/db');

router.get('/health', async (req, res) => {
  try {
    // Quick DB ping
    await db.query('SELECT 1');
    res.status(200).send('OK');
  } catch (err) {
    res.status(503).send('DEGRADED');
  }
});

router.get('/api/simulate-500', (req, res) => {
  res.status(500).json({ status: 500, error: 'Simulated HTTP 500 Internal Server Error for LogQL Q1 testing' });
});

module.exports = router;