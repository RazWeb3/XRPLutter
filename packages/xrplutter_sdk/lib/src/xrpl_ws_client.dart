// -------------------------------------------------------
// 目的・役割: XRPL WebSocketイベント購読クライアント。ledger/transactions/account等のイベントを購読する。
// 作成日: 2025/11/15
//
// 更新履歴:
// 2025/11/16 10:27 変更: pingIntervalと受信サイズ上限、サニタイズ済みエラーイベントを追加。
// 理由: 接続安定性とDoS耐性の向上。
// -------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class XRPLWebSocketClient {
  XRPLWebSocketClient({String? endpoint}) : _endpoint = endpoint ?? 'wss://s.altnet.rippletest.net:51233';

  final String _endpoint;
  WebSocket? _socket;
  final StreamController<Map<String, dynamic>> _events = StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> connect() async {
    if (_socket != null) return;
    final uri = Uri.parse(_endpoint);
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      throw ArgumentError('XRPL WS endpoint must use ws/wss scheme: ' + _endpoint);
    }
    _socket = await WebSocket.connect(_endpoint);
    _socket!.pingInterval = const Duration(seconds: 30);
    const maxLen = 256 * 1024;
    _socket!.listen((data) {
      try {
        final str = data as String;
        if (str.length > maxLen) return;
        final json = jsonDecode(str) as Map<String, dynamic>;
        _events.add(json);
      } catch (_) {
        _events.add({'type': 'error', 'message': 'invalid_json'});
      }
    }, onDone: () {
      _socket = null;
    }, onError: (e) {
      _socket = null;
    });
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  Future<void> subscribe(Map<String, dynamic> request) async {
    if (_socket == null) {
      await connect();
    }
    final body = jsonEncode(request);
    _socket!.add(body);
  }

  Future<void> subscribeTransactions({List<String>? accounts}) {
    return subscribe({
      'command': 'subscribe',
      'streams': ['transactions'],
      if (accounts != null && accounts.isNotEmpty) 'accounts': accounts,
    });
  }

  Future<void> subscribeLedger() {
    return subscribe({
      'command': 'subscribe',
      'streams': ['ledger'],
    });
  }
}