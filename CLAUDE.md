# Terminal Studio

Flutter 跨平台桌面终端模拟器（macOS/Windows/Linux）。

## Architecture

分层架构 + 插件系统，基于 Flutter 3+ / Dart 3+ / Riverpod 3.x。

```
UI Layer → Service Layer → Core Layer → State (Riverpod + Hive) → Platform Layer
```

### Key Layers

- **Core** (`lib/src/core/`): Plugin, Host, Command, Theme 四大系统
- **Hosts** (`lib/src/hosts/`): LocalHost (PTY), SSHHost (dartssh2)
- **Plugins** (`lib/src/plugins/`): Terminal, FileManager, Starter
- **Services** (`lib/src/core/service/`): Tabs, AI, Tunnel, Window, Log, VimEdit, RemoteControl, CommandPalette, Notification
- **State** (`lib/src/core/state/`): Riverpod providers
- **UI** (`lib/src/ui/`): Pages, Tabs, Shortcuts, Shared widgets

### Key Abstractions

- `Plugin` — lifecycle: didMounted → didConnected → didDisconnected → didUnmounted
- `Host` — connection interface (shell, execute, connectFileSystem)
- `HostConnector` — state machine: initialized → connecting → connected/disconnected/aborted
- `FileSystem` — local and SSH (SFTP) implementations
- **Tab tree** (`tabsProvider → TabsDocument`): `root` → layout containers (`TabsRow`/`TabsColumn`) → `Tabs` (leaf, holds `TabItem`). Branch on `is Tabs` to collect items. `TabItem.isActivated` = `parent!.activeTab == this`. `PluginTab.plugin.title` is `ValueNotifier<String?>` (raw); `PluginTab.title` is `ValueNotifier<Widget?>` (display row).

### State Management

Riverpod providers + Hive local DB. Key providers: tabs, connector, connectorStatus, host, pluginManager, themeRegistry, activeTheme, settings, aiCopilotService.

### UI Frameworks

- macOS: `macos_ui` + custom titlebar with acrylic effect
- Windows: `fluent_ui` (Fluent Design)
- Linux: standard GTK3

## Build & Run

```bash
# Get dependencies
flutter pub get

# Code generation (Hive models)
dart run build_runner build

# Run (debug)
flutter run -d macos    # or: -d windows, -d linux

# Build release
flutter build macos
flutter build windows
flutter build linux
```

### App Icon Generation

```bash
dart run icons_launcher:create
```

### Git Submodules

项目依赖自定义 fork 的 `xterm` 和 `flex_tabs`：

```bash
git submodule update --init --recursive
```

## Git Conventions

### Commit Message Style

简短的祈使句式，小写开头，无句号：

```
add <feature>        # 新功能
fix <description>    # 修复
change <description> # 修改
remove <description> # 移除
replace <old> with <new>
```

示例：`add cursor animation`, `fix terminal input and mouse handling bugs`, `change config from hive to jsonc`

### Branch Strategy

- `master` — 主分支
- `dev` — 开发分支
- `feature/*` — 功能分支
- `upgrade/*` — 依赖升级

## CI/CD

GitHub Actions (`.github/workflows/`):

- **autotag.yml**: push to master 时自动创建 `v` 前缀的 tag
- **build.yml**: 手动触发或 release 时构建多平台包
  - macOS: DMG + ZIP
  - Windows: MSIX + ZIP
  - Linux: DEB + ZIP

## Code Review Guidelines

- 遵循 `flutter_lints` 规则
- 使用 `logger` 替代 `print`（参见 commit c52f88c）
- State management 统一使用 Riverpod providers
- 新功能优先以 Plugin 形式实现
- Host 相关功能实现 Host/HostConnector/FileSystem 接口
- 平台特定 UI 分别使用对应 UI 框架（fluent_ui/macos_ui）
- 快捷键定义在 `lib/src/ui/shortcut/` 和 `lib/src/ui/shortcuts.dart`
- 快捷键系统：`ShortcutId`(ID 常量) → `defaultKeymaps`(平台默认) → `keymapProvider`(合并用户覆盖)。消费者应通过 `keymapProvider` 读取，不直接用 `defaultKeymaps`
- `Command` 子类通过 `shortcutId` 返回 `ShortcutId` 字符串，UI 层从 `keymapProvider` 解析实际键位
- `flutter analyze lib/` — 只检查项目代码，避免 ci/tmp 目录的 avoid_print 噪音

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `hive_ce` / `hive_ce_flutter` | Local persistence |
| `xterm` (fork) | Terminal emulation |
| `flutter_pty` | Local PTY |
| `dartssh2` | SSH client |
| `fluent_ui` | Windows UI |
| `macos_ui` | macOS UI |
| `google_generative_ai` | Gemini AI |
| `dart_openai` | OpenAI |
| `window_manager` | Window control |
| `flex_tabs` (fork) | Tab management |

## Important Files

- `lib/main.dart` — 入口，初始化 window_manager + ProviderContainer（全局单例通过 initX(container) 注入）
- `lib/src/core/open_term.dart` — 全局 OO API: openTerm singleton (tabCount, tabs, activeTab, OpenTermTab, OpenTermTerminal)
- `lib/src/core/plugin.dart` — Plugin 抽象和 PluginManager
- `lib/src/core/conn.dart` — HostConnector 状态机
- `lib/src/core/host.dart` — Host 接口
- `lib/src/core/service/tabs_service.dart` — Tab 管理
- `lib/src/ui/shortcut/global_shortcuts.dart` — 全局快捷键
- `lib/src/ui/shortcuts.dart` — ShortcutId、defaultKeymaps、formatActivator、解析工具
- `lib/src/core/state/keymap.dart` — keymapProvider（合并默认+用户自定义键位）
- `lib/src/core/command/command.dart` — Command 抽象基类（shortcutId）
- `lib/src/ui/command_palette/command_palette_overlay.dart` — Command Palette UI
- `ARCHITECTURE.md` — 详细架构文档（中文）
