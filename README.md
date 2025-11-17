<!--
目的・役割: XRPLutter のリポジトリ概要と主要ドキュメントへの導線をまとめた公開用README（非本番/PoC向け）。
作成日: 2025/11/14
-->

<!--
更新履歴:
2025/11/17 10:19 変更: XRPL Hackathon OSAKA提出要件に準拠する章構成へ更新（WebアプリURLの後日追加、審査基準適合の記載、プレゼン資料の扱い、出典/AI利用の開示を追記）。
理由: 提出物のREADME要件（プロジェクト名/概要/URL/審査基準適合/プレゼン資料）への対応。
-->

# XRPLutter

XRPL NFTのミント/送付/バーンをFlutter/Dartで扱うためのサンプルSDKと、BYOS（Bring Your Own Server）プロキシの最小テンプレートを含むリポジトリです。非本番/PoC用途を想定しています。

## WebアプリケーションURL
後日追加（提出後に確定次第、URLを記載します）

## リポジトリ構成（主要）
- `packages/xrplutter_sdk/` — SDK本体（導入ガイドは `packages/xrplutter_sdk/README.md`）
- `templates/byos_proxy_minimal_vercel/` — Vercel向け最小プロキシテンプレ（導入ガイドは `templates/byos_proxy_minimal_vercel/README.md`）
- `docs/specification.md` — 技術仕様書（最新版）
- `docs/onboarding_template.md` — 本番導入ガイド（簡易テンプレ）

## クイックスタート
- SDKの利用方法と実行例は `packages/xrplutter_sdk/README.md` を参照してください（`--dart-define` 例を掲載）。
- プロキシ環境の変数設定・エンドポイントは `templates/byos_proxy_minimal_vercel/README.md` を参照してください。

## 審査基準への適合（サマリ）
- 技術的完成度: SDK/デモを通じてウォレット連携、署名フロー、イベント可視化を提供。詳細は `docs/specification.md` を参照。
- 革新性・有用性: Flutter/WebでXRPLの操作体験を統一し、WalletConnect互換の相互運用を強化。
- ユーザー価値・UX: デモUI（`apps/wallet_connector_demo`）で接続/イベントの進捗を可視化し、導入の敷居を低減。
- セキュリティ/信頼性: 秘密鍵を保持せず外部ウォレット署名のみを採用。機密情報は `.gitignore` 管理、エラーハンドリングは仕様書準拠。
- ドキュメント整備: 要件定義（`docs/requirement_definition.md`）と仕様書（`docs/specification.md`）を継続更新。

各観点の証跡（スクリーンショット/動画/ログ抜粋）は提出時点の成果に合わせて追記予定です。

## プレゼン資料（任意）
- プロジェクト提出時点では任意です。
- ファイナリスト選出時にはピッチ用資料の準備が必須となるため、外部共有可能な資料リンクを後日追記します。

## 出典・AI利用の開示
- 既存コード/サードパーティの再利用箇所は、該当ディレクトリのREADME/コメントで明示します。
- 本プロジェクトはGitHubでオープンソースとして提出します（MITライセンス）。
- AIツールの使用については、生成支援（コード補助/ドキュメント整備）を行っており、適切な引用・帰属・著作権表示に配慮します。

## セキュリティ/運用の要点
- 秘密鍵は保持しません。署名は常に外部ウォレットで行います。
- JWTは短寿命でバックエンド発行し、`Authorization: Bearer` で利用してください。
- CORSはホワイトリストで厳格管理し、ワイルドカード許可は避けてください。
- 機密情報（`.env`、鍵ファイル、非公開ドキュメント）は `.gitignore` により除外されています。

## ライセンス
- 本リポジトリは MIT ライセンスです（`LICENSE` 参照）。

## 現在のステータス
- 非本番/PoC向けの公開。APIや仕様は変更される可能性があります。
