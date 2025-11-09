// -------------------------------------------------------
// 目的・役割: XRPL JSON-RPC/HTTPエンドポイントとの通信を担当する低レベルクライアント。
// 作成日: 2025/11/08
//
// 更新履歴:
// 2025/11/08 23:59 追記: 今後nft_info取得やNFTokenMint/NFTokenBurn署名送信を実装予定である旨をコメント。
// 理由: 実装計画の可視化。
// -------------------------------------------------------

import 'dart:convert';
import 'package:http/http.dart' as http;

class XRPLClient {
  XRPLClient({String? endpoint}) : _endpoint = endpoint ?? 'https://s.altnet.rippletest.net:51234';
  final String _endpoint;

  Future<Map<String, dynamic>> call(String method, Map<String, dynamic> params) async {
    final body = jsonEncode({
      'method': method,
      'params': [params],
    });
    final res = await http.post(Uri.parse(_endpoint), headers: {
      'Content-Type': 'application/json',
    }, body: body);
    if (res.statusCode != 200) {
      throw StateError('XRPL call failed: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}