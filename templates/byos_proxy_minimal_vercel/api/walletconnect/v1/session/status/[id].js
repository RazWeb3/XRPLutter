// -------------------------------------------------------
// 目的・役割: WalletConnect v2 セッションステータス取得スタブ
// 作成日: 2025/11/10
// -------------------------------------------------------

const { handleCorsPreflight, allowCors, verifyJwt, sendJson } = require('../../../../_utils/common');
const { getStore } = require('../../../../_utils/store');

module.exports = async (req, res) => {
  allowCors(req.headers.origin, res);
  if (handleCorsPreflight(req, res)) return;
  if (!verifyJwt(req, res)) return;

  const id = req.query.id;
  const store = getStore();
  const s = await store.getWcSession(id);
  if (!s) {
    res.statusCode = 404;
    return sendJson(res, { error: 'not found' });
  }
  sendJson(res, { opened: s.state.opened, signed: s.state.signed, rejected: s.state.rejected });
};