// -------------------------------------------------------
// 目的・役割: XUMM/Xaman ペイロードステータス取得スタブ
// 作成日: 2025/11/10
// -------------------------------------------------------

const { handleCorsPreflight, allowCors, verifyJwt, sendJson } = require('../../../../_utils/common');
const { getStore } = require('../../../../_utils/store');

module.exports = async (req, res) => {
  allowCors(req.headers.origin, res);
  if (handleCorsPreflight(req, res)) return;
  if (!verifyJwt(req, res)) return;

  const id = req.query.payloadId;
  const store = getStore();
  const p = await store.getXummPayload(id);
  if (!p) {
    res.statusCode = 404;
    return sendJson(res, { error: 'not found' });
  }
  sendJson(res, { opened: p.state.opened, signed: p.state.signed, rejected: p.state.rejected });
};