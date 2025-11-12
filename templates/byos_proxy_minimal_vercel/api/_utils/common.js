// -------------------------------------------------------
// 目的・役割: 共通ユーティリティ（CORS, JWT検証, JSON応答）を提供する
// 作成日: 2025/11/10
// -------------------------------------------------------

const jwt = require('jsonwebtoken');

function getAllowedOrigins() {
  return (process.env.CORS_ORIGINS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

function allowCors(origin, res) {
  const allowed = getAllowedOrigins();
  if (!origin || allowed.includes(origin)) {
    if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
    else res.setHeader('Access-Control-Allow-Origin', '*');
  }
  res.setHeader('Access-Control-Allow-Credentials', 'false');
  res.setHeader('Access-Control-Allow-Headers', 'authorization, content-type');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
}

function handleCorsPreflight(req, res) {
  allowCors(req.headers.origin, res);
  if (req.method === 'OPTIONS') {
    res.statusCode = 200;
    res.end();
    return true;
  }
  return false;
}

function verifyJwt(req, res) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.substring(7) : null;
  if (!token) {
    res.statusCode = 401;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'missing token' }));
    return false;
  }
  try {
    jwt.verify(token, process.env.JWT_SECRET || 'dev-secret');
    return true;
  } catch (e) {
    res.statusCode = 401;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'invalid token' }));
    return false;
  }
}

function sendJson(res, obj) {
  res.statusCode = 200;
  res.setHeader('content-type', 'application/json');
  res.end(JSON.stringify(obj));
}

module.exports = {
  allowCors,
  handleCorsPreflight,
  verifyJwt,
  sendJson,
};