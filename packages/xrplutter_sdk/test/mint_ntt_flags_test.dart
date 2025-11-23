import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';
import 'package:xrplutter_sdk/xrplutter.dart' as xrpl;

class _FakeWalletConnector extends WalletConnector {
  Map<String, dynamic>? lastTx;
  @override
  Future<AccountInfo> getAccountInfo() async {
    return AccountInfo(address: 'rTEST', sequence: 1);
  }

  @override
  Future<Map<String, dynamic>> signAndSubmit({required Map<String, dynamic> txJson}) async {
    lastTx = txJson;
    return {
      'result': {
        'tx_json': txJson,
        'hash': 'DUMMYHASH',
      }
    };
  }
}

class _FakeXRPLClient extends XRPLClient {
  @override
  Future<Map<String, dynamic>> call(String method, Map<String, dynamic> params) async {
    if (method == 'fee') {
      return {
        'result': {
          'drops': {'median': '10'}
        }
      };
    }
    if (method == 'ledger_current') {
      return {
        'result': {'ledger_current_index': 1000}
      };
    }
    if (method == 'account_info') {
      return {
        'result': {
          'account_data': {'Sequence': 1}
        }
      };
    }
    if (method == 'submit') {
      return {
        'result': {
          'tx_json': {'hash': 'DUMMYHASH'},
          'txid': 'DUMMYHASH'
        }
      };
    }
    if (method == 'tx') {
      return {
        'result': {'validated': true}
      };
    }
    return {'result': {}};
  }
  @override
  Future<Map<String, dynamic>> awaitTransaction(String hash, {Duration timeout = const Duration(seconds: 20), Duration pollInterval = const Duration(milliseconds: 800)}) async {
    return {
      'result': {
        'validated': true,
        'meta': {}
      }
    };
  }
}

void main() {
  group('NTT flags and TransferFee', () {
    test('buildMintTxJson transferable=false has no tfTransferable', () {
      final svc = xrpl.NftService();
      final tx = svc.buildMintTxJson(
        accountAddress: 'rTEST',
        metadataUri: 'ipfs://meta.json',
        taxon: 0,
        transferFeeBps: null,
        flags: const {},
        minterAddress: null,
        sbt: null,
        transferable: false,
      );
      final flags = tx['Flags'] as int;
      expect((flags & 0x00000008) == 0, isTrue);
      expect(tx.containsKey('TransferFee'), isFalse);
    });

    test('buildMintTxJson transferable=false with TransferFee throws', () {
      final svc = xrpl.NftService();
      expect(
        () => svc.buildMintTxJson(
          accountAddress: 'rTEST',
          metadataUri: 'ipfs://meta.json',
          taxon: 0,
          transferFeeBps: 100,
          flags: const {},
          minterAddress: null,
          sbt: null,
          transferable: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('XRPLutter.mintNtt builds NTT tx without TransferFee and tfTransferable', () async {
      final fakeConnector = _FakeWalletConnector();
      final sdk = XRPLutter(walletConnector: fakeConnector, client: _FakeXRPLClient());
      final res = await sdk.mintNtt(metadataUri: 'ipfs://meta.json');
      expect(res.transactionHash.isNotEmpty, isTrue);
      final tx = fakeConnector.lastTx!;
      final flags = tx['Flags'] as int;
      expect((flags & 0x00000008) == 0, isTrue);
      expect(tx.containsKey('TransferFee'), isFalse);
    });
  });
}