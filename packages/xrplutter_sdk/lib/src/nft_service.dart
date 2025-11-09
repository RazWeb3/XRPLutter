// -------------------------------------------------------
// 目的・役割: NFTの発行・送付・バーンなどの高レベル操作を提供するサービス層。
// 作成日: 2025/11/08
//
// 更新履歴:
// 2025/11/08 23:55 mintのパラメータにminterAddress/sbt/transferableを追加。
// 理由: 指定アドレスでの発行とSBT（非転送）表現に対応するための拡張。
// 2025/11/08 23:59 追記: tfTransferable（チェーンレベル転送可否）の方針を反映。TransferFeeとtransferableの整合性チェックを追加（仕様メモ）。
// 理由: Hard SBT/NTTの採用に伴い、ミント時のフラグ生成と注意点を明確化するため。
// 2025/11/09 00:12 mintにaccountAddress必須引数を追加し、_buildMintTxJsonを実装。
// 理由: 非カストディアル運用での外部署名フローに合わせ、署名前のトランザクションJSON構築を開始するため。
// 2025/11/09 00:25 追記: buildMintTxJson/buildBurnTxJsonの公開APIを追加。transfer用CreateOffer/Acceptのtx_jsonビルダーと転送可否チェック（nft_info）を準備。
// 理由: XRPLutter側で外部署名（WalletConnector）をオーケストレーションするための下支え。
// -------------------------------------------------------

import 'models.dart';
import 'xrpl_client.dart';

class NftService {
  NftService({XRPLClient? client}) : _client = client ?? XRPLClient();
  final XRPLClient _client;
  // 直近で構築したミント用tx_jsonプレビュー（外部署名前の参考情報）
  Map<String, dynamic>? lastMintTxPreview;
  Map<String, dynamic>? get lastMintTxPreviewView => lastMintTxPreview;

  // NFTokenMint Flags（XLS-20）
  // 参考: tfBurnable=0x00000001, tfOnlyXRP=0x00000002, tfTrustLine(deprecated)=0x00000004, tfTransferable=0x00000008, tfMutable=0x00000010
  static const int _tfBurnable = 0x00000001;
  static const int _tfOnlyXRP = 0x00000002;
  static const int _tfTransferable = 0x00000008;
  static const int _tfMutable = 0x00000010;
  // NFTokenオブジェクト Flags（推定値、要検証）
  static const int _lsfTransferable = 0x00000008;

  Future<MintResult> mint({
    required String accountAddress,
    required String metadataUri,
    int? taxon,
    int? transferFeeBps,
    Map<String, dynamic>? flags,
    String? minterAddress,
    bool? sbt,
    bool? transferable,
  }) async {
    // TODO: 実際の NFTokenMint を組み立てて署名・送信
    // 注意: minterAddressが指定された場合、現在の署名者がそのアドレスの署名権限を持つ必要がある（Issuer/NFTokenMinter設定）

    // フラグ生成（チェーンレベル転送可否）
    int mintFlags = 0;
    // Burnable や OnlyXRP は必要に応じて flags から受け取る設計にする（暫定）
    if (flags != null) {
      if (flags['burnable'] == true) mintFlags |= _tfBurnable;
      if (flags['onlyXrp'] == true) mintFlags |= _tfOnlyXRP;
      if (flags['mutable'] == true) mintFlags |= _tfMutable;
    }
    if (transferable == true) {
      mintFlags |= _tfTransferable;
    }
    // TransferFee指定時の注意: tfTransferableが必須
    if (transferFeeBps != null) {
      if ((mintFlags & _tfTransferable) == 0) {
        throw ArgumentError('TransferFeeを設定する場合、transferable=true（tfTransferable）である必要があります。');
      }
    }

    // メタデータにSoft SBT意図を埋め込む場合の処理（暫定: 実メタデータアップロード側で付与する想定）
    // if (sbt == true) { /* metadata.custom.sbt = true を推奨 */ }

    // トランザクションJSONの構築（署名前）
    final tx = _buildMintTxJson(
      accountAddress: accountAddress,
      metadataUri: metadataUri,
      taxon: taxon ?? 0,
      transferFeeBps: transferFeeBps,
      issuerAddress: (minterAddress != null && minterAddress != accountAddress) ? minterAddress : null,
      flagsValue: mintFlags,
    );
    // デバッグ/確認用に保持（仕様: 署名前のtx_jsonプレビュー）
    lastMintTxPreview = tx;

    // 署名は外部ウォレットで行う必要があるため、ここではダミー送信
    final response = await _client.call('submit', {
      'tx_blob': '00', // TODO: 外部署名で得たtx_blobを送信
    });
    return MintResult(transactionHash: response['result']?['tx_json']?['hash'] ?? 'dummyHash', nftId: 'dummyNftId');
  }

  Future<TransferResult> transfer({
    required String nftId,
    required String destinationAddress,
    String? amountDrops,
  }) async {
    // TODO: チェーン情報からlsfTransferable（NTTかどうか）を確認し、NTTの場合はアプリ側に例外/警告を返す
    // TODO: Offer作成＆受諾のシーケンスを実装
    final response = await _client.call('submit', {
      'tx_blob': '00', // ダミー
    });
    return TransferResult(transactionHash: response['result']?['tx_json']?['hash'] ?? 'dummyHash');
  }

  Future<BurnResult> burn({required String nftId}) async {
    // 注意: バーンは「NFTokenBurn」トランザクションを所有者が署名して送信する（いわゆるバーンアドレスへの送付ではない）
    // 発行者バーンは、ミント時にtfBurnableを設定している場合に限り許可（チェーン側で検証）。
    // 署名前のtx_jsonプレビューを構築（実装開始）
    final preview = _buildBurnTxJson(
      accountAddress: 'rSIGNER_ADDRESS_TBD', // TODO: 呼び出し元から受け取り（WalletConnector.getAccountInfo）
      nftId: nftId,
    );
    _lastBurnTxPreview = preview;
    // TODO: nft_infoで所有者/フラグ状態を確認するプリチェックを追加
    final response = await _client.call('submit', {
      'tx_blob': '00', // ダミー（外部署名後のtx_blobを送信）
    });
    return BurnResult(transactionHash: response['result']?['tx_json']?['hash'] ?? 'dummyHash');
  }

  Map<String, dynamic> _buildMintTxJson({
    required String accountAddress,
    required String metadataUri,
    required int taxon,
    int? transferFeeBps,
    String? issuerAddress,
    required int flagsValue,
  }) {
    final tx = <String, dynamic>{
      'TransactionType': 'NFTokenMint',
      'Account': accountAddress,
      'NFTokenTaxon': taxon,
      'Flags': flagsValue,
      'URI': _stringToHex(metadataUri),
      'Fee': '10',
    };
    if (transferFeeBps != null) {
      // 範囲チェック（0..50000）
      if (transferFeeBps < 0 || transferFeeBps > 50000) {
        throw ArgumentError('TransferFeeは0〜50000の範囲で指定してください。');
      }
      tx['TransferFee'] = transferFeeBps;
    }
    if (issuerAddress != null) {
      tx['Issuer'] = issuerAddress;
    }
    return tx;
  }

  String _stringToHex(String input) {
    final codeUnits = input.codeUnits;
    final buffer = StringBuffer();
    for (final cu in codeUnits) {
      buffer.write(cu.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  // 公開API: Mint用tx_jsonを構築して返す（外部ウォレットでの署名前）
  Map<String, dynamic> buildMintTxJson({
    required String accountAddress,
    required String metadataUri,
    int? taxon,
    int? transferFeeBps,
    Map<String, dynamic>? flags,
    String? minterAddress,
    bool? sbt,
    bool? transferable,
  }) {
    // フラグ生成（チェーンレベル転送可否）
    int mintFlags = 0;
    if (flags != null) {
      if (flags['burnable'] == true) mintFlags |= _tfBurnable;
      if (flags['onlyXrp'] == true) mintFlags |= _tfOnlyXRP;
      if (flags['mutable'] == true) mintFlags |= _tfMutable;
    }
    if (transferable == true) {
      mintFlags |= _tfTransferable;
    }
    if (transferFeeBps != null) {
      if ((mintFlags & _tfTransferable) == 0) {
        throw ArgumentError('TransferFeeを設定する場合、transferable=true（tfTransferable）である必要があります。');
      }
    }

    final tx = _buildMintTxJson(
      accountAddress: accountAddress,
      metadataUri: metadataUri,
      taxon: (taxon ?? 0),
      transferFeeBps: transferFeeBps,
      issuerAddress: (minterAddress != null && minterAddress != accountAddress) ? minterAddress : null,
      flagsValue: mintFlags,
    );
    lastMintTxPreview = tx;
    return tx;
  }

  // 公開API: Burn用tx_jsonを構築して返す（外部ウォレットでの署名前）
  Map<String, dynamic> buildBurnTxJson({
    required String accountAddress,
    required String nftId,
  }) {
    final tx = {
      'TransactionType': 'NFTokenBurn',
      'Account': accountAddress,
      'NFTokenID': nftId,
      'Fee': '10',
    };
    _lastBurnTxPreview = tx;
    return tx;
  }

  // 公開API: CreateOffer用tx_jsonを構築（ギフト/売買両対応）
  Map<String, dynamic> buildCreateOfferTxJson({
    required String accountAddress,
    required String nftId,
    required String destinationAddress,
    String? amountDrops, // null/"0"でギフト
  }) {
    final tx = <String, dynamic>{
      'TransactionType': 'NFTokenCreateOffer',
      'Account': accountAddress,
      'NFTokenID': nftId,
      'Destination': destinationAddress,
      'Fee': '10',
    };
    tx['Amount'] = amountDrops ?? '0';
    return tx;
  }

  // 公開API: AcceptOffer用tx_jsonを構築（受取側が署名）
  Map<String, dynamic> buildAcceptOfferTxJson({
    required String accountAddress,
    required String offerId,
  }) {
    return {
      'TransactionType': 'NFTokenAcceptOffer',
      'Account': accountAddress,
      'SellOffer': offerId, // TODO: BuyOffer対応（必要に応じて）
      'Fee': '10',
    };
  }

  // チェーン上の転送可否を確認（nft_infoを利用）
  Future<bool> isTransferable({required String nftId}) async {
    final info = await _client.call('nft_info', {
      'nft_id': nftId,
    });
    // TODO: 実レスポンス構造に合わせてパースを調整
    final flags = info['result']?['nft']?['Flags'] ?? info['result']?['nft']?['flags'] ?? 0;
    if (flags is int) {
      return (flags & _lsfTransferable) != 0;
    }
    return true; // 不明時は許容（後続で失敗する可能性あり）
  }

  // 直近で構築したバーン用tx_jsonプレビュー
  Map<String, dynamic>? _lastBurnTxPreview;
  Map<String, dynamic>? get lastBurnTxPreview => _lastBurnTxPreview;

  Map<String, dynamic> _buildBurnTxJson({
    required String accountAddress,
    required String nftId,
  }) {
    return {
      'TransactionType': 'NFTokenBurn',
      'Account': accountAddress,
      'NFTokenID': nftId,
      'Fee': '10',
    };
  }
}