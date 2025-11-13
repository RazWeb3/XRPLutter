// -------------------------------------------------------
// 目的・役割: XUMM/Xaman ペイロードステータス取得スタブ
// 作成日: 2025/11/10
// -------------------------------------------------------

const { handleCorsPreflight, allowCors, verifyJwt, sendJson } = require('../../../../_utils/common');

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

  const id = req.query.payloadId;
  const r = await fetch(`https://xumm.app/api/v1/platform/payload/${encodeURIComponent(id)}`, {
    method: 'GET',
    headers: {
      'X-API-Key': key,
      'X-API-Secret': secret,
    },
  });
  if (r.status !== 200) {
    const body = await r.text();
    res.statusCode = r.status;
    return sendJson(res, { error: 'xumm status failed', status: r.status, body });
  }
  const json = await r.json();
  const meta = json.meta || {};
  const resp = json.response || {};
  const opened = resp.opened === true;
  const signed = resp.signed === true;
  const rejected = meta.resolved === true && signed !== true;
  const txHash = resp.txid || undefined;
  const tx_blob = resp.tx_blob || undefined;
  return sendJson(res, { opened, signed, rejected, txHash, tx_blob });
};
