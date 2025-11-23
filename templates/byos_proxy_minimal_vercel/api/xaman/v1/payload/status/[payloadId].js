// -------------------------------------------------------
// 目的・役割: Xaman ペイロードステータス取得スタブ
// 作成日: 2025/11/10
// 更新履歴:
// 2025/11/13 15:25 追記: payloadIdの形式検証（UUID v4）を追加し、不正IDによる外部API叩きを抑止。
// 理由: 入力検証不足による不要な外部呼び出し・診断困難の防止。
// 2025/11/23 10:28 変更: 環境変数名をXAMAN_*へ統一。
// 理由: リブランド後の名称整合のため。
// -------------------------------------------------------

const { handleCorsPreflight, allowCors, rateLimit, verifyJwt, sendJson } = require('../../../../_utils/common');

module.exports = async (req, res) => {
  allowCors(req.headers.origin, res);
  if (handleCorsPreflight(req, res)) return;
  if (!(await rateLimit(req, res))) return;
  if (!verifyJwt(req, res)) return;

  const key = process.env.XAMAN_API_KEY;
  const secret = process.env.XAMAN_API_SECRET;
  if (!key || !secret) {
    res.statusCode = 500;
    return sendJson(res, { error: 'missing xaman api credentials' });
  }

  const id = req.query.payloadId;
  const uuidV4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!id || !uuidV4.test(String(id))) {
    res.statusCode = 400;
    return sendJson(res, { error: 'invalid payloadId' });
  }
  const apiBase = process.env.XAMAN_API_BASE || 'https://xaman.app/api/v1/platform';
  const r = await fetch(apiBase + `/payload/${encodeURIComponent(id)}`, {
    method: 'GET',
    headers: {
      'accept': 'application/json',
      'X-API-Key': key,
      'X-API-Secret': secret,
    },
    signal: (() => { const ac = new AbortController(); setTimeout(() => ac.abort(), 10000); return ac.signal; })(),
  });
  if (r.status !== 200) {
    const body = await r.text();
    res.statusCode = r.status;
    return sendJson(res, { error: 'xaman status failed', status: r.status, body });
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
