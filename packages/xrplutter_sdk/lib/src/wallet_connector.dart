// -------------------------------------------------------
// 目的・役割: 外部ウォレットとの接続・切断・署名を仲介するコンポーネント。
// 作成日: 2025/11/08
//
// 更新履歴:
// 2025/11/08 23:59 追記: 非カストディアル運用における受取側の毎回署名が必要である旨を内部コメントに明記。
// 理由: 受取UX設計の前提を統一するため。
// 2025/11/09 00:12 追記: 署名要求APIのスタブを追加（signAndSubmit）。
// 理由: 非カストディアル運用で外部署名フローをSDKから呼び出すための入口を用意。
// -------------------------------------------------------

import 'models.dart';

class WalletConnector {
  WalletSession? _session;

  Future<WalletSession> connect({required WalletProvider provider}) async {
    // TODO: 実際のウォレット接続ロジック（WalletConnect等）を実装
    _session = WalletSession(address: 'rEXAMPLEADDRESS');
    return _session!;
  }

  Future<void> disconnect() async {
    // TODO: 実際の切断処理
    _session = null;
  }

  Future<AccountInfo> getAccountInfo() async {
    // TODO: XRPLからアカウント情報を取得
    if (_session == null) {
      throw StateError('Wallet not connected');
    }
    return AccountInfo(address: _session!.address, sequence: 1);
  }

  /// 署名要求＋送信のスタブ（今後、Xumm/WalletConnect等と連携）
  /// txJson: 署名前のトランザクションJSON（NFTokenMint/NFTokenCreateOffer/NFTokenBurn等）
  /// 戻り値: 送信結果（ダミー）
  Future<Map<String, dynamic>> signAndSubmit({required Map<String, dynamic> txJson}) async {
    if (_session == null) {
      throw StateError('Wallet not connected');
    }
    // TODO: 外部ウォレットへ署名要求→tx_blob取得→XRPL submit
    return {
      'result': {
        'tx_json': txJson,
        'hash': 'dummyHash',
      }
    };
  }
}