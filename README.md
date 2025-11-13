<!--
目的・役割: XRPLutter のリポジトリ概要と主要ドキュメントへの導線をまとめた公開用README（非本番/PoC向け）。
作成日: 2025/11/14
-->

# XRPLutter

XRPL NFTのミント/送付/バーンをFlutter/Dartで扱うためのサンプルSDKと、BYOS（Bring Your Own Server）プロキシの最小テンプレートを含むリポジトリです。非本番/PoC用途を想定しています。

## リポジトリ構成（主要）
- `packages/xrplutter_sdk/` — SDK本体（導入ガイドは `packages/xrplutter_sdk/README.md`）
- `templates/byos_proxy_minimal_vercel/` — Vercel向け最小プロキシテンプレ（導入ガイドは `templates/byos_proxy_minimal_vercel/README.md`）
- `docs/specification.md` — 技術仕様書（最新版）
- `docs/onboarding_template.md` — 本番導入ガイド（簡易テンプレ）

## クイックスタート
- SDKの利用方法と実行例は `packages/xrplutter_sdk/README.md` を参照してください（`--dart-define` 例を掲載）。
- プロキシ環境の変数設定・エンドポイントは `templates/byos_proxy_minimal_vercel/README.md` を参照してください。

## セキュリティ/運用の要点
- 秘密鍵は保持しません。署名は常に外部ウォレットで行います。
- JWTは短寿命でバックエンド発行し、`Authorization: Bearer` で利用してください。
- CORSはホワイトリストで厳格管理し、ワイルドカード許可は避けてください。
- 機密情報（`.env`、鍵ファイル、非公開ドキュメント）は `.gitignore` により除外されています。

## ライセンス
- 本リポジトリは MIT ライセンスです（`LICENSE` 参照）。

## 現在のステータス
- 非本番/PoC向けの公開。APIや仕様は変更される可能性があります。
