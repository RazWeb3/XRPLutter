<!--
目的・役割: XRPLutter SDKの導入ガイド。Ethereumとの違い、受取側署名の前提、SBTの使い分け、アカウントリザーブなど運用上の重要事項をまとめる。
作成日: 2025/11/09
 
 更新履歴:
 2025/11/09 12:05 追記: 非カストディアル署名フローのコード例（XRPLutter.mintNft/transferNft/burnNft）を追加。FAQ（insufficient reserve/TransferFee制約/AcceptOfferの必須理由）を拡充。
 理由: 実装進捗（WalletConnector.signAndSubmitスタブとオーケストレーション）に合わせて利用者向けドキュメントを最新化。
 2025/11/09 12:22 修正: 参考欄から議事録リンクを削除（公開リポジトリ向け）。
 理由: 議事録には内部検討内容が含まれるため、公開には不向きと判断。
 2025/11/09 11:35 追記: Soft SBT運用補助の使い方（metadataフラグ付与、送付時の警告/ブロック設定）を追加。
 理由: 初期リリースでの最小実装が利用者に分かりやすいよう運用ガイドを明記。
-->

# XRPLutter SDK 導入ガイド

このドキュメントは、Flutter向けXRPLutter SDKの利用時に重要となるポイントを簡潔にまとめたものです。詳細な技術仕様は`docs/specification.md`をご参照ください。

## Ethereumとの主な違い（XRPL NFT）
- 受取方式が異なります: XRPLのNFT所有権移転は「オファー方式」で、受取側が`NFTokenAcceptOffer`を自ら署名・送信して初めて移転が成立します。
  - 非カストディアル運用では、受取のたびに受取側の署名が必要です（毎回）。
  - カストディアル運用の場合は、サーバー側が受取者の代理で署名することになりますが、法規制・セキュリティ要件に注意してください。
- トラストライン（IOU通貨用）とNFTは仕組みが異なります。NFTの受取に「一度の許可線」はありません。

## SBT（Soulbound Token）の使い分け
- Hard SBT（NTT: Non-Transferable Token）: チェーンレベルで転送不可。`mintNtt()`または`mintNft(transferable: false)`でミントします。
  - XRPLの`NFTokenMint`で`tfTransferable`フラグを未設定にすることで実現します。
- Soft SBT（保留）: メタデータやSDK/UIポリシーで転送を抑制する方式は、初期リリースでは「保留」です。今後のバージョンで実装予定です。

## フラグ（Flags）とTransferFee
- `tfTransferable`（0x00000008）: 転送可否（未設定=非転送）。
- `tfBurnable`（0x00000001）: 設定した場合、発行者（Issuer）が`NFTokenBurn`を実行可能。未設定時は発行者によるバーン不可。所有者は常にバーン可能です。
- `tfOnlyXRP`（0x00000002）、`tfMutable`（0x00000010）等も必要に応じて設定可能です。
- TransferFee（bps）は`tfTransferable`必須です。NTT（非転送）ではTransferFeeを設定できません。

## アカウントリザーブ（重要）
- XRPLではアカウントに「リザーブ（最低保有XRP量）」が存在し、NFTミント・Offer作成などで必要なリザーブが増加します。
- テストネットでの検証時も、十分なXRPを用意してください（不足すると`insufficient reserve`エラーになります）。

## 署名・送信の流れ（概要）
1. ウォレット接続（例: Xumm / WalletConnect）
2. SDKが`NFTokenMint`や`NFTokenCreateOffer`のtx_jsonを構築
3. 外部ウォレットで署名 → `tx_blob`を取得
4. XRPLノードへ`submit`（`tx_blob`）

SDKは秘密鍵を保持しません。常に外部ウォレットで署名してください。

## クイックスタート（コード例）
```dart
final sdk = XRPLutter();
// 1) ウォレット接続
await sdk.connectWallet(provider: WalletProvider.xumm);

// 2) 通常NFTミント（転送可能）
final mint = await sdk.mintRegularNft(
  metadataUri: 'ipfs://.../metadata.json',
  taxon: 0,
  transferFeeBps: null, // 任意。設定する場合はチェーン転送可能が必須
);

// 3) ギフト送付（CreateOfferを送信。実際の所有権移転は受取側のAccept署名が必要）
final tr = await sdk.transferNft(
  nftId: mint.nftId,
  destinationAddress: 'rDESTINATION...',
  amountDrops: '0',
);

// 4) バーン（所有者がNFTokenBurnを送信）
final br = await sdk.burnNft(nftId: mint.nftId);
```

非カストディアル運用では、SDK内部で`NftService.build*TxJson`によりtx_jsonを構築し、`WalletConnector.signAndSubmit`へ渡して外部署名→送信が行われます。受取側の`NFTokenAcceptOffer`は受取者のウォレットで別途署名してください。

## Soft SBT運用補助（警告/ブロック）
- 目的: アプリ内で「送付抑止」を図りたい場合に、メタデータの`custom.sbt=true`フラグを基に転送操作時に警告/ブロックを行います（任意設定）。
- 最小実装: SDKはメタデータ補助と送付時の運用補助のみを提供（チェーン非転送は`mintNtt()`をご利用）。

使い方例:
```dart
import 'package:xrplutter_sdk/src/metadata_utils.dart';

// 1) メタデータにSoft SBTフラグを付与（任意）
final meta = {
  'name': 'Example',
  'description': '...',
};
final softMeta = MetadataUtils.addSoftSbtFlag(meta);

// 2) 送付時にmetadataJsonを渡し、警告/ブロックポリシーを指定
await sdk.transferNft(
  nftId: '...',
  destinationAddress: 'rDEST...',
  amountDrops: '0',
  metadataJson: softMeta,      // custom.sbt=true を判定
  warnIfSoftSbt: true,         // デフォルト: 警告のみ（ログ）
  blockIfSoftSbt: false,       // 必要ならtrueで例外にして送付抑止
);
```

注意:
- Soft SBTはアプリ/UXポリシーでの抑止です。外部ツールでは送付可能です。アプリ外の流通リスクを許容できない場合はHard SBT（NTT）をご利用ください。
- `metadataJson`が未指定の場合、Soft SBT判定は実行されません（外部フェッチは初期リリースでは非対応）。

## 参考
- 詳細仕様: `docs/specification.md`

---
このREADMEはガイドであり、正本は仕様書（`docs/specification.md`）です。最新情報は仕様書をご確認ください。

## FAQ（よくある質問）
- Q: `insufficient reserve` が出ます。どうすれば？
  - A: アカウントのXRP残高が最低リザーブを下回っています。NFTミントやOffer作成はリザーブを消費するため、十分なXRPを用意してください（Testnetでも必要）。
- Q: TransferFeeをNTT（非転送）で設定できますか？
  - A: できません。XRPLの仕様上、TransferFeeを設定する場合は`tfTransferable`（チェーン転送可能）が必須です。非転送のミントではTransferFeeは未設定にしてください。
- Q: なぜ受取側の`NFTokenAcceptOffer`が必要なの？
  - A: XRPLのNFT移転はオファー方式です。送付側の`NFTokenCreateOffer`だけでは所有権は移転せず、受取側が`Accept`を署名したときに移転が成立します。
- Q: Soft SBTは使えますか？
  - A: 最小サポートとして、メタデータに `sbt=true` を付与する補助（`MetadataUtils.addSoftSbtFlag`）と、送付時の警告/ブロック設定（`XRPLutter.transferNft(metadataJson, warnIfSoftSbt, blockIfSoftSbt)`）を提供します。チェーンレベルの非転送（Hard SBT/NTT）は`mintNtt()`をご利用ください。Soft SBTはアプリ外では送付可能であるため、プロダクションでは警告/ブロックの利用を推奨します。