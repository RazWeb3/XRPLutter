// -------------------------------------------------------
// 目的・役割: XUMM/Xaman ペイロード作成スタブ（deepLink/QR返却）
// 作成日: 2025/11/10
// -------------------------------------------------------

const { handleCorsPreflight, allowCors, verifyJwt, sendJson } = require('../../../_utils/common');

module.exports = async (req, res) => {
  allowCors(req.headers.origin, res);
  if (handleCorsPreflight(req, res)) return;
  if (!verifyJwt(req, res)) return;

  const key = process.env.XUMM_API_KEY;
  const secret = process.env.XUMM_API_SECRET;
  if (!key || !secret) {
    res.statusCode = 500;
    return sendJson(res, { error: 'missing xumm api credentials' });
  }

  const txJson = (req.body && req.body.tx_json) || { TransactionType: 'SignIn' };
  const r = await fetch('https://xumm.app/api/v1/platform/payload', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'X-API-Key': key,
      'X-API-Secret': secret,
    },
    body: JSON.stringify({ txjson: txJson }),
  });

  if (r.status !== 200) {
    const body = await r.text();
    res.statusCode = r.status;
    return sendJson(res, { error: 'xumm create failed', status: r.status, body });
  }

  const json = await r.json();
  const payloadId = json.uuid;
  const deepLink = json.next && (json.next.always || json.next.pushed);
  const qrUrl = json.refs && json.refs.qr_png;
  return sendJson(res, { payloadId, deepLink, qrUrl });
};
