import 'package:flutter/widgets.dart';

/// AI 相关图标常量类
/// 包含 OpenAI、Claude、OpenCode 等 AI 工具的图标
class AIIcons {
  /// 字体家族名称
  static const String fontFamily = 'MyIconFont';

  /// OpenAI 图标 (Unicode: \uE501)
  static const IconData openai = IconData(
    0xe501,
    fontFamily: fontFamily,
    fontPackage: null,
  );

  /// Claude 图标 (Unicode: \uE675)
  static const IconData claude = IconData(
    0xe675,
    fontFamily: fontFamily,
    fontPackage: null,
  );

  /// OpenCode 图标 (Unicode: \uE507)
  static const IconData opencode = IconData(
    0xe507,
    fontFamily: fontFamily,
    fontPackage: null,
  );
}