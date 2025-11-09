<!--
目的・役割: XRPLutter NFT Kit SDKの技術仕様書。公開API、内部構成、データモデル、フロー、セキュリティ、テスト方針を定義する最新版の設計情報。
作成日: 2025/11/08
 
 更新履歴:
 2025/11/08 23:58 変更: mintNftにminterAddress/sbt/transferableを追記。Metadata/StorageProvider/SBTポリシーの記述を追加。
 理由: ユーザー要望（ミンター切替・SBT導入・柔軟ストレージ/メタデータ）への仕様反映。
 2025/11/08 23:59 変更: SBTの定義を更新。XRPLチェーンの非転送フラグ（tfTransferable）による"Hard SBT/NTT"を明記し、mintNft.transferableの意味を「チェーンフラグ制御」に更新。Soft SBT（メタデータ/SDKポリシー）との両立を追記。
 理由: XRPL公式仕様（XLS-20/NFTokenMint）でtfTransferableフラグが提供されているため、誤解を排し正確な仕様に修正。
 2025/11/08 23:59 追記: 便利API（mintRegularNft/mintNtt）を追加し、アプリ内の使い分けを容易化。非カストディアル運用で受取側の毎回署名が必要である旨を明記。
 理由: 議事録の合意（通常NFT主体＋SBTも発行可能、毎回署名）を仕様へ反映。
 2025/11/09 00:12 追記: Soft SBTは初期リリースでは「保留」とする旨を明記。NFTokenMintのtfBurnable設定時のみ発行者バーン許可である点を明記。NftServiceで署名前tx_jsonを構築する開始実装（URIのHex化等）を反映。
 理由: ユーザー要望（Soft SBT保留、tfBurnableの重要性）とSDK内部の着手状況を最新化するため。
 2025/11/09 12:00 追記: NftServiceにbuildCreateOfferTxJson/buildAcceptOfferTxJson、buildBurnTxJsonを追加し、XRPLutter.transferNft/burnNftがWalletConnector.signAndSubmitで非カストディアル署名・送信を行う設計を明文化。isTransferable（nft_infoによるlsfTransferable判定）を仕様に追加。
 理由: 実装の進捗（オーケストレーションのリファクタリングと事前チェックの導入）を最新仕様へ反映するため。
 2025/11/09 12:37 追記: Soft SBTの最小サポート（メタデータ補助: custom.sbt=true付与、判定ヘルパー）を追加。UI/SDKによる転送抑止は非強制（任意）とし、将来拡張で検討。
 理由: アプリ内限定の非転送ポリシーを柔軟に付与できるようにするため（チェーン非転送と両立）。
 2025/11/09 12:45 変更: XRPLutter.transferNftにSoft SBT運用補助を追加（`metadataJson`, `warnIfSoftSbt`, `blockIfSoftSbt`）。
 理由: メタデータ方針に基づき、アプリ内での送付時に警告/ブロックを可能にするため（任意設定、デフォルトは警告有効・ブロック無効）。
-->

# XRPLutter NFT Kit SDK 仕様書

本仕様書は、Flutter向け「XRPLutter NFT Kit SDK」の最新の技術設計を示します。用語や設計は一般公開を前提としており、広く再利用可能なコンポーネントとして提供します。

## 1. アーキテクチャ概要
- レイヤ構成:
  - WalletConnector層: 外部ウォレット（例:Xumm）と接続/署名連携を担う
  - XRPLClient層: XRPLノード（JSON-RPC/WebSocket/API）へのリクエスト送信を担う
  - NftService層: ミント/送付/バーン等のNFT操作を高レベルAPIとして提供
  - Model層: トランザクション/結果/エラーなどの型定義

## 2. 公開API（Dart）
名前や型は初期案であり、実装時にDartの慣用表現に合わせ微調整します。

```dart
class XRPLutter {
  // セッション/接続
  Future<WalletSession> connectWallet({required WalletProvider provider});
  Future<void> disconnectWallet();
  Future<AccountInfo> getAccountInfo();

  // NFT操作
  Future<MintResult> mintNft({
    required String metadataUri,
    int? taxon,
    int? transferFeeBps,
    Map<String, dynamic>? flags,
    String? minterAddress, // 署名主体の明示指定（要権限）
    bool? sbt,             // Soft SBT（アプリ/SDKポリシー）の意図。メタデータにsbt=trueを付与し、UI/SDKで転送操作を抑止。
    bool? transferable,    // チェーンレベル転送可否。true=通常NFT（tfTransferable有効）、false=NTT（非転送: tfTransferable無効）
  });

  // 便利API: 通常NFTをミント（転送可能）
  Future<MintResult> mintRegularNft({
    required String metadataUri,
    int? taxon,
    int? transferFeeBps,
    Map<String, dynamic>? flags,
    String? minterAddress,
  });

  // 便利API: 非転送トークン（NTT/Hard SBT）をミント（転送不可）
  Future<MintResult> mintNtt({
    required String metadataUri,
    int? taxon,
    Map<String, dynamic>? flags,
    String? minterAddress,
  });

  /// 所有権移転の抽象API（内部ではOffer系トランザクションを使用）
  Future<TransferResult> transferNft({
    required String nftId,
    required String destinationAddress,
    String? amountDrops, // ギフトはnull/"0"、価格管理はアプリ側で
    Map<String, dynamic>? metadataJson, // Soft SBT判定のためのメタデータ（custom.sbt=true等）
    bool warnIfSoftSbt = true,          // Soft SBT時に警告ログ出力（デフォルト有効）
    bool blockIfSoftSbt = false,        // Soft SBT時に送付をブロック（デフォルト無効）
  });

  Future<BurnResult> burnNft({
    required String nftId,
  });
}
```

### 2.1 戻り値モデル（例）
```dart
class WalletSession { String address; String provider; }
class AccountInfo { String address; int sequence; int reserve; }
class MintResult { String nftId; String txHash; }
class TransferResult { String offerId; String txHash; }
class BurnResult { String txHash; }
```

## 3. 内部仕様
### 3.1 XRPLClient
- JSON-RPC/WebSocketにて以下のメソッドを利用（例）:
  - submit, tx, account_info, nft_info など
- HTTP(S)通信時はタイムアウト/リトライを実装（指数バックオフ）

### 3.2 NftService
- ミント: NFTokenMintを生成
  - 必須: metadataUri
  - 任意: taxon, transferFee（bps）, flags
  - フラグ: transferable=true の場合 tfTransferable を設定。transferable=false（NTT）の場合は tfTransferable 未設定。
  - 注意: TransferFeeを設定する場合は tfTransferable が必須（仕様）。NTTでは TransferFee を設定できない。
  - flagsのキー例: `burnable`（tfBurnable）, `onlyXrp`（tfOnlyXRP）, `mutable`（tfMutable）
  - 署名前のtx_json構築: URIはHexへエンコードして`URI`に設定。`Issuer`は「代理発行」時に指定（NFTokenMinter設定が必要）。
  - 公開ビルダーAPI: `buildMintTxJson({...})` を提供し、外部ウォレットでの署名前にtx_jsonを構築・検証（TransferFee範囲とtfTransferable整合）する。
- 送付（所有権移転）:
  - NFTokenCreateOfferで目的地（destination）を指定
  - ギフト: 価格0（amount=0）
  - 売買: 価格あり（amount>0）だが価格管理/通貨はアプリ側ロジック
  - NFTokenAcceptOfferは受取側が署名して実行（受取UXはサンプルアプリで提示）
  - 非カストディアル運用では、受取のたびに受取側の署名が必要（毎回）。
  - 公開ビルダーAPI: `buildCreateOfferTxJson({...})`（送付側）, `buildAcceptOfferTxJson({...})`（受取側）を提供。
  - 事前チェック: `isTransferable(nftId)` を提供。`nft_info`からNFTokenのFlagsを取得し、`lsfTransferable`有無でユーザー間移転可否を判定。
  - Soft SBT運用補助: `XRPLutter.transferNft` に `metadataJson` を渡すと `MetadataUtils.isSoftSbtJson` により判定し、`warnIfSoftSbt`（ログ警告）/`blockIfSoftSbt`（例外で送付抑止）を選択可能（任意設定、デフォルトは警告有効・ブロック無効）。
- バーン: NFTokenBurnを生成（所有者のみ実行可能）
  - バーンは「バーンアドレスへ送付」ではなく NFTokenBurn トランザクション。発行者に戻さなくても所有者が直接バーンできる。
  - 公開ビルダーAPI: `buildBurnTxJson({...})` を提供（外部署名前のtx_json）。
  - デバッグ/確認用プレビュー: 直近構築tx_jsonを`lastMintTxPreview`/`lastBurnTxPreview`として参照可能（SDK内部フィールド）。

### 3.3 WalletConnector
- 外部ウォレットへ署名要求を送る（Deep Link/QR等）
- SDKは秘密鍵を保持しない
- 署名拒否/タイムアウトをハンドリング
 - 署名API（案）:
   - `Future<Map<String, dynamic>> signAndSubmit({required Map<String, dynamic> txJson})`
   - 署名前のtx_jsonを受け取り、外部ウォレットで署名→`tx_blob`送信までを仲介（初期リリースはスタブ）。
 - オーケストレーション: XRPLutterの`mintNft/transferNft/burnNft`は、各NftServiceビルダーでtx_jsonを構築し、WalletConnectorの`signAndSubmit`へ渡す流れを採用。

### 3.4 メタデータとストレージ（Metadata/StorageProvider）
- メタデータは推奨スキーマ（`name`, `description`, `image`, `external_url`, `attributes`, `animation_url`, `custom`）を示しつつ、自由拡張を許容。
- 型付きモデル `NftMetadata` を提供（`custom`で任意拡張）。同時に `Map<String, dynamic>` をそのまま渡せる柔軟APIも許可。
- ストレージは抽象インターフェース `StorageProvider` を介して扱う。
  - `uploadAsset(bytes, filename?, mimeType?) -> imageUri`
  - `uploadJson(json, filename?) -> metadataUri`
  - 実装例: `IpfsStorageProvider`, `HttpStorageProvider`（自社サーバー対応）
- SDKはURIをNFTokenMintの`URI`に設定（バイト列へエンコード）。

### 3.5 SBT（Soulbound Token）/ 非転送トークン（NTT）

- 用語整理:
  - Hard SBT（NTT: Non-Transferable Token）: チェーンレベルで転送不可。XRPLのNFTokenMintでtfTransferableフラグを無効（未設定）としてミントすることで達成。ミント後はNFTokenオブジェクトにlsfTransferableが付与されず、ユーザー間の転送ができません（ただし「発行者⇔所有者」間の直接移転は制限の対象外）。
  - Soft SBT: メタデータやSDK/UIポリシーにより転送を抑止。外部ツールでは転送できてしまう可能性があるため、アプリ内限定の運用に適します。

- SDKの挙動:
  - `mintNft.transferable`: チェーンフラグを制御。`true`=通常NFT（tfTransferable設定）、`false`=NTT（tfTransferable未設定）。
  - Soft SBT（最小サポート）: メタデータ補助として `MetadataUtils.addSoftSbtFlag(json)` を提供し、`custom.sbt=true`（トップレベル `sbt=true` も許容）を付与可能。UI/SDKによる転送抑止はデフォルト非強制（任意）。
  - 併用例: `MetadataUtils.addSoftSbtFlag(json)` でSoft SBT意図を付与しつつ、`transferable=false`でHard SBT（チェーン制御）を採用可能。

- 解除ポリシー:
  - Soft SBTのみの場合: メタデータとアプリ設定の更新で解除可能（URIがHTTP/IPNS等の可変参照であることを推奨）。
  - Hard SBT（NTT）の場合: チェーンフラグは不変のため、解除には burn→re-mint が必要（新たなNFTIDになります）。

- 参考（XRPL公式仕様）:
  - NFTokenMintのFlagsに`tfTransferable`（0x00000008）。未設定でミントすると非転送トークン（NTT）になり、ユーザー間では転送不可。発行者へ／からの移転のみ許容。
  - TransferFeeを設定する場合は`tfTransferable`が必須（XRPLライブラリ仕様による）。
  - `tfBurnable`（0x00000001）を設定した場合、発行者がNFTokenBurnを実行可能（誤発行・不正利用時の是正が可能）。未設定の場合、発行者はバーンできず、所有者のみがバーン可能。

（注意）所有権移転はXRPLのオファー方式に基づき、受取側による`NFTokenAcceptOffer`署名が必要です（非カストディアル運用）。

## 4. エラー設計
- エラー分類:
  - WalletNotConnected
  - SignRejected / SignTimeout
  - NetworkError (timeout, unreachable)
  - InvalidParameter (metadataUri, nftId 等)
  - XRPLSubmitError (insufficient reserve, sequence mismatch 等)
- 例外/戻り値: DartのResult型または例外で提供（実装時に選定）

## 5. セキュリティ
- 秘密鍵非保持（必須）
- 入力検証の徹底（アドレス形式、URI、数値範囲）
- 署名は常に外部ウォレットで実行
- ネットワーク通信のTLS、署名要求のオリジン情報提示

## 6. 設定
- ネットワーク: mainnet/testnetの切替
- エンドポイント: 優先/フォールバックノードの設定
- タイムアウト/リトライ/レート制限
- ログレベル/イベントフック

## 7. サンプルコード（案）
```dart
final sdk = XRPLutter();
await sdk.connectWallet(provider: WalletProvider.xumm);

// Mint
final mint = await sdk.mintNft(
  metadataUri: 'ipfs://.../metadata.json',
  taxon: 10,
  transferFeeBps: null,
);

// Transfer (gift)
final tr = await sdk.transferNft(
  nftId: mint.nftId,
  destinationAddress: 'r....',
  amountDrops: '0',
);

// Burn
final br = await sdk.burnNft(nftId: mint.nftId);
```

## 8. テスト方針
- 単体テスト: 生成ペイロード、入力検証、エラーパス
- 統合テスト: WalletConnector, XRPLClientとの連携（testnet推奨）
- サンプルアプリE2E: UI操作→ウォレット署名→取引完了まで

## 9. バージョニング/互換性
- バージョン: SemVer（例: 0.x系で初期公開、将来1.0へ）
- Dart 3系、Flutter最新安定版に対応

## 10. ライセンス（案）
- OSSライセンス（例: MIT）を想定。最終決定はプロジェクトオーナーと協議。

## 11. 非機能要件（再掲）
- セキュリティ、信頼性、パフォーマンス、可観測性、互換性

## 12. 今後の拡張（例）
- NFTメタデータ支援（IPFSアップロード補助）
- Offer一覧取得/管理API
- KYC/AMLフックのための拡張ポイント

本仕様書は常に最新版を維持し、SDKの設計/実装変更が発生した場合は速やかに更新します。