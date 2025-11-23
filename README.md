
# XRPLutter NFT Kit SDK

## 概要
XRPL（XRP Ledger）上でNFTのミント／送付／バーンをFlutter/Dartから安全かつ簡潔に扱えるSDKです。開発者が高レベルAPIで運用可能なよう、トランザクション構築・外部署名・送信・検証までを一貫して提供します。

## 主な機能
- NFT操作の高レベルAPI（ミント／オファー作成・受諾／バーン）
- 送信フローの安定化（`autofill` による Fee/Sequence/LastLedgerSequence 充足、`awaitTransaction` による検証待ち）
- Xaman 連携（バックエンドプロキシ方式）とWeb拡張（Crossmark / GemWallet）対応の骨子
- BYOS（Bring Your Own Server）最小プロキシテンプレート（Vercel向け）

## インストール
外部プロジェクトからの導入例（Git依存、サブディレクトリ指定）:

```yaml
dependencies:
  xrplutter_sdk:
    git:
      url: https://github.com/RazWeb3/XRPLutter.git
      path: packages/xrplutter_sdk
      # ref: v0.1.x  # 推奨: タグまたはコミットで固定
```

## クイックスタート（最短）
```dart
import 'package:xrplutter_sdk/xrplutter.dart';

final sdk = XRPLutter();
await sdk.connectWallet(provider: WalletProvider.xaman);

// 通常NFTミント（転送可能）
final mint = await sdk.mintRegularNft(
  metadataUri: 'ipfs://.../metadata.json',
  taxon: 0,
);

// ギフト送付（CreateOfferを送信。実所有権移転は受取側Acceptが必要）
final tr = await sdk.transferNft(
  nftId: mint.nftId,
  destinationAddress: 'rDEST...',
  amountDrops: '0',
);

// バーン
final br = await sdk.burnNft(nftId: mint.nftId);
```

詳細な設定・運用ガイドは `packages/xrplutter_sdk/README.md` を参照してください。

## リポジトリ構成（主要）
- `packages/xrplutter_sdk/` — SDK本体（導入ガイドは `packages/xrplutter_sdk/README.md`）
- `templates/byos_proxy_minimal_vercel/` — Vercel向け最小プロキシテンプレ（導入ガイドは `templates/byos_proxy_minimal_vercel/README.md`）
- `docs/specification.md` — 技術仕様書（最新版）
- `docs/onboarding_template.md` — 本番導入ガイド（簡易テンプレ）

## セキュリティガイドライン
- 秘密鍵は保持しません。署名は常に外部ウォレットで行います。
- JWTは短寿命でバックエンド発行し、`Authorization: Bearer` で利用します。
- CORSはホワイトリストで厳格管理し、ワイルドカード許可は避けます。
- 機密情報（`.env`、鍵ファイル、非公開ドキュメント）は `.gitignore` で除外します。

## 互換性
- Dart 3系／Flutter最新安定版に対応
- XRPL（XLS-20）準拠。Mainnet/Testnetの切替はアプリ設定（環境変数）で運用可能

## ライセンス
- 本リポジトリは MIT ライセンスです（`LICENSE` 参照）

## サポート
- 仕様・導入に関する質問は、Issueまたはディスカッションをご利用ください
