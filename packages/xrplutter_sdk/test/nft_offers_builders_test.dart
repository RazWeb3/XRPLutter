import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart' as xrpl;

void main() {
  group('NftService offer builders', () {
    test('CreateOffer sell flags=1, Destination set, Amount default 0', () {
      final svc = xrpl.NftService();
      final tx = svc.buildCreateOfferTxJson(
        accountAddress: 'rSENDER',
        nftId: 'NFTID',
        destinationAddress: 'rDEST',
        amountDrops: null,
        sell: true,
      );
      expect(tx['TransactionType'], equals('NFTokenCreateOffer'));
      expect(tx['Flags'], equals(1));
      expect(tx['Destination'], equals('rDEST'));
      expect(tx['Amount'], equals('0'));
    });

    test('CreateOffer buy requires Owner and Amount', () {
      final svc = xrpl.NftService();
      expect(
        () => svc.buildCreateOfferTxJson(
          accountAddress: 'rBUYER',
          nftId: 'NFTID',
          amountDrops: null,
          sell: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
      final tx = svc.buildCreateOfferTxJson(
        accountAddress: 'rBUYER',
        nftId: 'NFTID',
        ownerAddress: 'rOWNER',
        amountDrops: '10',
        sell: false,
      );
      expect(tx['Flags'], equals(0));
      expect(tx['Owner'], equals('rOWNER'));
      expect(tx['Amount'], equals('10'));
    });

    test('AcceptOffer supports SellOffer and BuyOffer', () {
      final svc = xrpl.NftService();
      final sellTx = svc.buildAcceptOfferTxJson(
        accountAddress: 'rACCT',
        sellOfferId: 'SOFF',
      );
      expect(sellTx.containsKey('SellOffer'), isTrue);
      final buyTx = svc.buildAcceptOfferTxJson(
        accountAddress: 'rACCT',
        buyOfferId: 'BOFF',
      );
      expect(buyTx.containsKey('BuyOffer'), isTrue);
    });
  });
}