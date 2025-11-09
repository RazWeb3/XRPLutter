// -------------------------------------------------------
// 目的・役割: XRPLutter SDKの内部/公開モデル定義。Walletセッション、アカウント情報、NFT操作の結果型などを保持する。
// 作成日: 2025/11/08
//
// 更新履歴:
// 2025/11/08 23:55 NftMetadataモデルを追加。
// 理由: メタデータの標準スキーマと柔軟拡張（custom）をサポートするため。
// 2025/11/08 23:59 追記: Hard SBT（NTT）採用に伴い、結果型・ドキュメントのコメントを補足（転送可否の扱い）。
// 理由: 仕様の明確化。
// -------------------------------------------------------

class WalletProvider {
  const WalletProvider(this.name);
  final String name;
}

class WalletSession {
  WalletSession({required this.address});
  final String address;
}

class AccountInfo {
  AccountInfo({required this.address, required this.sequence});
  final String address;
  final int sequence;
}

class MintResult {
  MintResult({required this.transactionHash, required this.nftId});
  final String transactionHash;
  final String nftId;
}

class TransferResult {
  TransferResult({required this.transactionHash});
  final String transactionHash;
}

class BurnResult {
  BurnResult({required this.transactionHash});
  final String transactionHash;
}

class NftMetadata {
  NftMetadata({
    required this.name,
    required this.description,
    required this.image,
    this.externalUrl,
    this.animationUrl,
    this.attributes,
    this.custom,
  });

  final String name;
  final String description;
  final String image;
  final String? externalUrl;
  final String? animationUrl;
  final List<Map<String, dynamic>>? attributes;
  final Map<String, dynamic>? custom;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'description': description,
      'image': image,
    };
    if (externalUrl != null) json['external_url'] = externalUrl;
    if (animationUrl != null) json['animation_url'] = animationUrl;
    if (attributes != null) json['attributes'] = attributes;
    if (custom != null) json['custom'] = custom;
    return json;
  }
}