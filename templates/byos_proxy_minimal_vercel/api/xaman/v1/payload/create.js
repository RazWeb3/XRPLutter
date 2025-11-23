// -------------------------------------------------------
// 目的・役割: Xaman ペイロード作成スタブ（deepLink/QR返却）
// 作成日: 2025/11/10
// 更新履歴:
// 2025/11/13 15:25 変更: 入力検証を強化（メソッド/Content-Type/tx_jsonのサイズと型検証）し、過大入力や不正形式を拒否。
// 理由: 不要な負荷や予期せぬ挙動、潜在的な攻撃ベクトル（過大ペイロード）を抑止するため。
// 2025/11/23 10:28 変更: 環境変数名をXAMAN_*へ統一。
// 理由: リブランド後の名称整合のため。
// -------------------------------------------------------

const { handleCorsPreflight, allowCors, rateLimit, verifyJwt, sendJson } = require('../../../_utils/common');

module.exports = async (req, res) => {
  allowCors(req.headers.origin, res);
  if (handleCorsPreflight(req, res)) return;
  if (!(await rateLimit(req, res))) return;
  if (!verifyJwt(req, res)) return;

  if (req.method !== 'POST') {
    res.statusCode = 405;
    return sendJson(res, { error: 'method not allowed' });
  }
  const ct = (req.headers['content-type'] || '').toLowerCase();
  if (!ct.includes('application/json')) {
    res.statusCode = 400;
    return sendJson(res, { error: 'content-type must be application/json' });
  }

  const key = process.env.XAMAN_API_KEY;
  const secret = process.env.XAMAN_API_SECRET;
  if (!key || !secret) {
    res.statusCode = 500;
    return sendJson(res, { error: 'missing xaman api credentials' });
  }

  const txJson = (req.body && req.body.tx_json) || { TransactionType: 'SignIn' };
  const rawLen = Buffer.byteLength(JSON.stringify(txJson || {}), 'utf8');
  if (!txJson || typeof txJson !== 'object') {
    res.statusCode = 400;
    return sendJson(res, { error: 'tx_json must be an object' });
  }
  if (rawLen > 4000) {
    res.statusCode = 413;
    return sendJson(res, { error: 'tx_json too large' });
  }
  if (typeof txJson.TransactionType !== 'string' || !txJson.TransactionType) {
    res.statusCode = 400;
    return sendJson(res, { error: 'TransactionType required' });
  }
  const apiBase = process.env.XAMAN_API_BASE || 'https://xaman.app/api/v1/platform';
  const r = await fetch(apiBase + '/payload', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
      'X-API-Key': key,
      'X-API-Secret': secret,
    },
    body: JSON.stringify({ txjson: txJson }),
    signal: (() => { const ac = new AbortController(); setTimeout(() => ac.abort(), 10000); return ac.signal; })(),
  });

  if (r.status !== 200) {
    const body = await r.text();
    res.statusCode = r.status;
    return sendJson(res, { error: 'xaman create failed', status: r.status, body });
  }

  const json = await r.json();
  const payloadId = json.uuid;
  const deepLink = json.next && (json.next.always || json.next.pushed);
  const qrUrl = json.refs && json.refs.qr_png;
  return sendJson(res, { payloadId, deepLink, qrUrl });
};
