// -------------------------------------------------------
// 目的・役割: XRPL JSON-RPC/HTTPエンドポイントとの通信を担当する低レベルクライアント。
// 作成日: 2025/11/08
//
// 更新履歴:
// 2025/11/08 23:59 追記: 今後nft_info取得やNFTokenMint/NFTokenBurn署名送信を実装予定である旨をコメント。
// 理由: 実装計画の可視化。
// 2025/11/09 11:50 変更: タイムアウト/リトライ（指数バックオフ）と詳細エラーハンドリングを実装。エンドポイント設定を拡張。
// 理由: 仕様書（3.1 XRPLClient）に記載の非機能要件（安定性）に準拠し、ネットワーク揺らぎ時の堅牢性を高めるため。
// 2025/11/13 15:22 変更: HTTPクライアントの再利用（keep-alive）を導入し、ソケット枯渇/オーバーヘッドを低減。
// 理由: 毎回のトップレベルhttp呼び出しでクライアントを再生成せず、効率と安定性を改善するため。
// 2025/11/13 15:22 追記: エンドポイントURIのスキーム検証（http/httpsのみ許可）を追加。
// 理由: 不正スキーム（file:, data:, javascript:）混入による誤動作やセキュリティリスクを排除するため。
// -------------------------------------------------------

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class XRPLClient {
  XRPLClient({
    String? endpoint,
    Duration? timeout,
    int? maxRetries,
    int? retryBaseDelayMs,
  })  : _endpoint = endpoint ?? 'https://s.altnet.rippletest.net:51234',
        _timeout = timeout ?? const Duration(seconds: 10),
        _maxRetries = maxRetries ?? 2,
        _retryBaseDelayMs = retryBaseDelayMs ?? 300,
        _client = http.Client(),
        _endpointUri = _validateEndpointUri(endpoint ?? 'https://s.altnet.rippletest.net:51234');

  final String _endpoint;
  final Duration _timeout;
  final int _maxRetries;
  final int _retryBaseDelayMs;
  final http.Client _client;
  final Uri _endpointUri;

  Future<Map<String, dynamic>> call(String method, Map<String, dynamic> params) async {
    final body = jsonEncode({
      'method': method,
      'params': [params],
    });

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final res = await _client
            .post(
              _endpointUri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(_timeout);
        if (res.statusCode != 200) {
          throw XRPLNetworkError('HTTP ${res.statusCode}');
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final result = decoded['result'];
        if (result is Map<String, dynamic>) {
          final status = result['status'];
          final error = result['error'] ?? result['error_code'] ?? result['engine_result'];
          final errorMessage = result['error_message'] ?? result['engine_result_message'] ?? result['message'];
          if (status == 'error' || (error != null && error != 'tesSUCCESS')) {
            throw XRPLSubmitError('${error ?? 'unknown'}', errorMessage?.toString());
          }
        }
        return decoded;
      } on TimeoutException {
        if (attempt >= _maxRetries) rethrow;
        await Future.delayed(_retryDelay(attempt));
      } on SocketException {
        if (attempt >= _maxRetries) rethrow;
        await Future.delayed(_retryDelay(attempt));
      } on http.ClientException {
        if (attempt >= _maxRetries) rethrow;
        await Future.delayed(_retryDelay(attempt));
      }
    }
    // 理論上ここには来ない（上でreturnかrethrowしている）
    throw XRPLNetworkError('Unexpected retry exhaustion');
  }

  Duration _retryDelay(int attempt) {
    // 指数バックオフ: base * 2^attempt
    final ms = _retryBaseDelayMs * (1 << attempt);
    return Duration(milliseconds: ms);
  }

  static Uri _validateEndpointUri(String endpoint) {
    final uri = Uri.parse(endpoint);
    final s = uri.scheme.toLowerCase();
    if (s != 'http' && s != 'https') {
      throw ArgumentError('XRPL endpoint must use http/https scheme: ' + endpoint);
    }
    return uri;
  }

  /// 明示的にHTTPクライアントを破棄したい場合に使用（通常は不要）
  void close() {
    _client.close();
  }
}

class XRPLNetworkError implements Exception {
  XRPLNetworkError(this.message);
  final String message;
  @override
  String toString() => 'XRPLNetworkError: $message';
}

class XRPLSubmitError implements Exception {
  XRPLSubmitError(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() => 'XRPLSubmitError(code=$code, message=${message ?? ''})';
}
