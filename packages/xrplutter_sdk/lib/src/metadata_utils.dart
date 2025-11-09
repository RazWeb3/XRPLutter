// -------------------------------------------------------
// 目的・役割: NFTメタデータにSoft SBT意図（custom.sbt=true）を付与する補助と、メタデータからSoft SBT判定を行うヘルパー。
// 作成日: 2025/11/09
//
// 更新履歴:
// 2025/11/09 12:35 初版: addSoftSbtFlag/isSoftSbtJsonを追加（UI/SDK抑止は非強制、メタデータ補助のみ）。
// 理由: Hard SBTに加え、アプリ内限定の非転送ポリシーを簡易に付与できるようにするため。
// -------------------------------------------------------

class MetadataUtils {
  /// メタデータJSONに Soft SBT を示すフラグを付与する。
  /// 既存のcustomを保持しつつ、`custom.sbt = true` を設定する。
  static Map<String, dynamic> addSoftSbtFlag(Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);
    final custom = Map<String, dynamic>.from(result['custom'] ?? <String, dynamic>{});
    custom['sbt'] = true;
    result['custom'] = custom;
    // top-level sbtも許容しておく（外部ツールとの互換）
    result['sbt'] = true;
    return result;
  }

  /// メタデータJSONが Soft SBT を示唆しているかを判定する。
  /// `custom.sbt == true` または top-level `sbt == true` を検出。
  static bool isSoftSbtJson(Map<String, dynamic> json) {
    final custom = json['custom'];
    final customSbt = custom is Map<String, dynamic> ? custom['sbt'] == true : false;
    final topLevelSbt = json['sbt'] == true;
    return customSbt || topLevelSbt;
  }
}