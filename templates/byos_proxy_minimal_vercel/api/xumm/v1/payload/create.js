// -------------------------------------------------------
// 目的・役割: XUMM/Xaman ペイロード作成スタブ（deepLink/QR返却）
// 作成日: 2025/11/10
// -------------------------------------------------------

const { v4: uuidv4 } = require('uuid');
const { handleCorsPreflight, allowCors, verifyJwt, sendJson } = require('../../../_utils/common');
const { getStore } = require('../../../_utils/store');

module.exports = async (req, res) => {
  allowCors(req.headers.origin, res);
  if (handleCorsPreflight(req, res)) return;
  if (!verifyJwt(req, res)) return;

  const id = uuidv4();
  const deepLink = `https://xumm.app/dummy/${id}`;
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?data=${encodeURIComponent(deepLink)}&size=200x200`;

  const store = getStore();
  await store.setXummPayload(id, { deepLink, qrUrl, state: { opened: false, signed: false, rejected: false } });

  sendJson(res, { payloadId: id, deepLink, qrUrl });
};