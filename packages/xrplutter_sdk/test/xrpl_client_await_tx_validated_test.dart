import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:xrplutter_sdk/src/xrpl_client.dart';

void main() {
  group('XRPLClient.awaitTransaction validated flow', () {
    late HttpServer server;
    late Uri endpoint;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      endpoint = Uri.parse('http://localhost:${server.port}');
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('returns validated after not_found retries', () async {
      int calls = 0;
      server.listen((HttpRequest req) async {
        final body = await utf8.decoder.bind(req).join();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final method = decoded['method'];
        Map<String, dynamic> response;
        if (method == 'tx') {
          calls += 1;
          if (calls < 2) {
            response = {
              'result': {
                'status': 'error',
                'error': 'txnNotFound'
              }
            };
          } else {
            response = {
              'result': {
                'status': 'success',
                'validated': true,
                'meta': {}
              }
            };
          }
        } else {
          response = {'result': {'status': 'success'}};
        }
        final text = jsonEncode(response);
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(text);
        await req.response.close();
      });

      final client = XRPLClient(endpoint: endpoint.toString(), timeout: const Duration(seconds: 2));
      final res = await client.awaitTransaction('DUMMY', timeout: const Duration(seconds: 5), pollInterval: const Duration(milliseconds: 200));
      expect(res['result']?['validated'], equals(true));
    });
  });
}