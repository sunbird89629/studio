# Terminal Studio

Flutter 跨平台桌面终端模拟器（macOS/Windows/Linux）。

## Architecture

分层架构 + 插件系统，基于 Flutter 3+ / Dart 3+ / Riverpod 3.x。

```
UI Layer → Service Layer → Core Layer → State (Riverpod + JSONC files) → Platform Layer
```

### Key Layers

- **Core** (`lib/src/core/`): Plugin, Host, Command, Theme 四大系统
- **Hosts** (`lib/src/hosts/`): LocalHost (PTY), SSHHost (dartssh2)
- **Plugins** (`lib/src/plugins/`): Terminal, FileManager, Starter
- **Services** (`lib/src/core/service/`): Tabs, AI, Tunnel, Window, Log, VimEdit, RemoteControl, CommandPalette, Notification
- **State** (`lib/src/core/state/`): Riverpod providers
- **UI** (`lib/src/ui/`): Pages, Tabs, Shortcuts, Shared widgets

### Key Abstractions

- `Plugin` — lifecycle: onMounted → onConnected → onDisconnected → onUnmounted
- `Host` — connection interface (shell, execute, connectFileSystem)
- `HostConnector` — state machine: initialized → connecting → connected/disconnected/aborted; uses `StreamController.broadcast()` (`connector.stream`); `connector.dispose()` called via `ref.onDispose` in `connectorProvider`
- `FileSystem` — local and SSH (SFTP) implementations
- **Tab tree** (`tabsProvider` is `NotifierProvider<TabsNotifier, int>`; access document via `ref.read(tabsProvider.notifier).document`): `root` → layout containers (`TabsRow`/`TabsColumn`) → `Tabs` (leaf, holds `TabItem`). Branch on `is Tabs` to collect items. `TabItem.isActivated` = `parent!.activeTab == this`. `PluginTab.plugin.title` is `ValueNotifier<String?>` (raw); `PluginTab.title` is `ValueNotifier<Widget?>` (display row). Derived providers: `allTabsProvider` (reactive flattened tab list), `activeTabProvider` (reactive active tab), `tabsDocumentProvider` (stable doc ref for `TabsView`).

### State Management

Riverpod providers + file persistence (`~/.config/openterm/`). Key providers: tabs, connector, connectorStatus, host, pluginManager, themeRegistry, activeTheme, settings, aiCopilotService.

### UI Frameworks

- macOS: `macos_ui` + custom titlebar with acrylic effect
- Windows: `fluent_ui` (Fluent Design)
- Linux: standard GTK3

## Build & Run

```bash
# Run only core unit tests
flutter test test/core/

# Get dependencies
flutter pub get

# Code generation (freezed only — Hive removed)
dart run build_runner build --delete-conflicting-outputs

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

### Fork 本地开发工作流

`xterm` 和 `flex_tabs` 是自维护 fork，通过 pubspec.yaml git 依赖引用，不是 git submodule。

**开发阶段**（path dep，修改即生效）：
```yaml
xterm:
  path: ../xterm.dart   # ~/work/flutter/xterm.dart
```

**提交阶段**（push fork 到 GitHub，切回 git ref）：
```yaml
xterm:
  git:
    url: https://github.com/sunbird89629/xterm.dart.git
    ref: <new-commit-hash>
```

**禁止直接修改 `~/.pub-cache/`**，改动不会被提交，且会被 `flutter pub get` 覆盖。

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
- `AppLogger.forComponent('Name')` — 用缓存工厂（不要直接用 `AppLogger(context: LogContext(...))`）
- 抛出 `exceptions.dart` 中的类型化异常（如 `SSHConnectionException`），不用裸字符串 throw
- State management 统一使用 Riverpod providers
- 新功能优先以 Plugin 形式实现
- Host 相关功能实现 Host/HostConnector/FileSystem 接口
- 平台特定 UI 分别使用对应 UI 框架（fluent_ui/macos_ui）
- 快捷键定义在 `lib/src/ui/shortcut/` 和 `lib/src/ui/shortcuts.dart`
- 快捷键系统：`ShortcutId`(ID 常量) → `defaultKeymaps`(平台默认) → `keymapProvider`(合并用户覆盖)。消费者应通过 `keymapProvider` 读取，不直接用 `defaultKeymaps`
- `Command` 子类通过 `shortcutId` 返回 `ShortcutId` 字符串，UI 层从 `keymapProvider` 解析实际键位
- `flutter analyze lib/` — 只检查项目代码，避免 ci/tmp 目录的 avoid_print 噪音
- 非 UI 状态用静态单例（`ClassName._()`），参考 `SessionManager`、`SSHConnectionPool`、`LogService.instance`
- Event sealed class 建模参考 `ShellCommandEvent`（同 `CloudflaredEvent` 模式）
- Plugin 中的 `StreamSubscription` 必须显式存储，在 `onDisconnected()` 和 `onUnmounted()` 两处 cancel

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `xterm` (fork) | Terminal emulation |
| `flutter_pty` | Local PTY |
| `dartssh2` | SSH client |
| `fluent_ui` | Windows UI |
| `macos_ui` | macOS UI |
| `google_generative_ai` | Gemini AI |
| `dart_openai` | OpenAI |
| `window_manager` | Window control |
| `flex_tabs` (fork) | Tab management |

## Dependency Gotchas

- Riverpod 3.x: `WidgetRef` is `sealed class WidgetRef implements MutationTarget` — does NOT extend `Ref`; functions taking `Ref` will reject `WidgetRef` from ConsumerWidget. Inline save logic in `Ref` contexts instead of calling a shared helper that takes `WidgetRef`
- Riverpod 3.x: `ChangeNotifierProvider` is NOT in the default `flutter_riverpod` export — it lives in `flutter_riverpod/legacy.dart`; prefer `NotifierProvider<T, StateType>` instead
- `flex_tabs` `TabsView`: constructing `TabsView(document)` internally calls `document.notifyListeners()` during widget init, BEFORE `setRoot()` — any listener checking `document.root` at this point will see `null`; use a two-level listener (watch document changes → switch to watching root.children) to avoid premature `exit(0)`
- `LogicalKeyboardKey` cannot be a `const` map key (overrides `==`/`hashCode`); use `final` map
- `part` directives must appear after all `import` statements in Dart files
- `terminal_plugin.dart` uses `import 'package:flutter/material.dart' show ...` (named show list) alongside `cupertino.dart` — any new Material widget used in this file must be added to the `show` list explicitly
- `xterm` fork: `TerminalGestureDetector.onTapUp` was dead code — fixed in `~/work/flutter/xterm.dart` (adds `widget.onTapUp?.call(details)` after `widget.onSingleTapUp?.call(details)` in `gesture_detector.dart`). Use path dep during dev, push to GitHub and update pubspec ref to release.
- xterm `CellOffset.y` from `onTapUp` is buffer-absolute (includes scroll offset) — confirmed in `render.dart`
- xterm `Terminal.scrollUp/scrollDown` are **buffer scroll operations** (escape sequences), NOT viewport scroll — to programmatically scroll the view, pass `scrollController` to `TerminalView`; compute target pixel as `(bufferLine / (buffer.height - viewHeight)) * scrollController.position.maxScrollExtent`
- No `url_launcher` dep — use `LauncherService` (`Process.run('open'/'xdg-open'/'start')`) for platform-native file/URL opening
- `riverpod_lint 3.x` does NOT depend on `custom_lint` — migrated to `analysis_server_plugin`; add only to `dev_dependencies`, register in `analysis_options.yaml` as `plugins:\n  riverpod_lint:` (map format, not a list item); IDE picks it up automatically, no `dart run custom_lint` needed
- Riverpod async anti-patterns to avoid: (1) `ref.read(provider).value ?? []` in async methods may silently return empty before data loads — use `await ref.read(provider.future)` instead; (2) `FutureBuilder(future: ref.read(...).loadX())` inside `build()` recreates the Future on every rebuild — cache in `initState` using a `ConsumerStatefulWidget`; (3) `Future.microtask(() => ref.read(notifier).set(...))` in `build()` is a side-effect anti-pattern — move auto-init logic into `Notifier.build()` using `ref.listen`

## Testing Gotchas

- `@visibleForTesting` methods must not be called from non-test production code — test generic abstractions (e.g. `ConnectionPool<T>`) directly, not via wrappers
- `Provider((_) => null)` infers type `Null`; always write `Provider<YourType>((ref) => ...)` with explicit type
- Library-private fields (`_field`) are inaccessible from test files even via `dynamic` cast — expose public getters for testable state
- All `import` directives must precede declarations; appending at file bottom causes `directive_after_declaration` error

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
- `lib/src/ui/shared/fluent_form.dart` — FluentFormHeader(style?)/Separator/Divider form layout widgets
- `lib/src/ui/shared/shortcut_label.dart` — ShortcutLabel(shortcutId) widget, looks up keymapProvider, renders key-cap badges
- `lib/src/core/service/terminal_event_bus.dart` — TerminalEventBus, decouples TerminalPlugin output from RemoteControlService
- `lib/src/core/service/broadcast_service.dart` — BroadcastService singleton; terminals join/leave a broadcast group; input from one member is mirrored to all others
- `lib/src/core/command/snippet_commands.dart` — SnippetCommand: executes snippet.command via openTerm.activeTab?.terminal?.write()
- `lib/src/core/record/snippet_record.dart` — SnippetRecord{id, name, command}; stored in SettingsRecord.snippets, persisted to config.jsonc
- `lib/src/plugins/terminal/terminal_input_tracker.dart` — TerminalInputTracker: tracks currentInput + commandHistory; processInput() is @visibleForTesting
- `lib/src/core/service/ssh_storage_service.dart` — SSH hosts/keys CRUD to `hosts.json` / `keys.json`; injectable `configDir` for testing
- `lib/src/core/state/database.dart` — `sshHostsProvider`, `sshKeysProvider`, `profilesProvider` (file-backed FutureProviders)
- `persistSettings(WidgetRef, SettingsRecord)` in `settings.dart` — replaces `record.save()`; writes `config.jsonc` + invalidates providers; only for widget (`WidgetRef`) context; `Ref` contexts must inline `configFileService.saveToFile()` + `ref.invalidate(settingsProvider)`
- `_persistKeymaps(WidgetRef, Map<String,String>)` in `keymap.dart` — shared helper for all keymap save operations; updates config.jsonc and invalidates `keymapProvider`
- `lib/src/core/model/terminal_session.dart` — TerminalSession domain object + SessionStatus enum + SessionManager singleton
- `lib/src/core/model/shell_command_event.dart` — ShellCommandEvent sealed class (PromptStart/CommandStart/CommandExecute/CommandDone), OSC 133 events
- `lib/src/core/service/terminal_output_event.dart` — TerminalOutputEvent{sessionId, data, timestamp}, typed EventBus payload
- `lib/src/core/utils/osc_parser.dart` — OscParser.parse(String) → OscParseResult{cleanData, events}, strips OSC 133 from raw PTY output
- `lib/src/core/utils/shell_integration.dart` — ShellIntegration.zsh/bash/fish static script constants (not auto-injected; for Settings UI display)
- `lib/src/hosts/ssh_connection_pool.dart` — SSHConnectionPool singleton, reference-counted by "user@host:port" key
- `lib/src/core/exceptions.dart` — AppException hierarchy: SSHConnectionException, SSHAuthException, PluginException, ConfigException
- `lib/src/core/constants/log_channels.dart` — LogChannels string constants; use instead of hardcoded channel strings
- `lib/src/hosts/connection_pool.dart` — Generic ConnectionPool<T>(getDone, doClose): ref-counted pool, injectable for testing
- `lib/src/core/utils/link_detector.dart` — detects URLs/file paths in terminal line text at a given column
- `lib/src/core/service/launcher_service.dart` — platform-native open via Process.run (macOS: open, Linux: xdg-open, Windows: start)
- `ARCHITECTURE.md` — 详细架构文档（中文）

## Terminal Plugin — Inline Image Protocol

Implements iTerm2 Inline Image Protocol (OSC 1337) for image preview in yazi and similar tools.

- `lib/src/plugins/terminal/inline_image.dart` — `InlineImageEntry` data class
- `lib/src/plugins/terminal/terminal_plugin.dart` — OSC 1337 parser, `inlineImages` ValueNotifier, Stack overlay
- `onConnected()` injects `TERM_PROGRAM=iTerm.app` → yazi detects iTerm2 support
- Clear triggers: `onEraseDisplay` (ESC[2J), `onWriteChar` bounding-box overwrite detection, alt→main buffer switch
- **`Terminal.notifyListeners()` fires once per `write()` call, at the very end** — `cursorY` in a listener reflects the frame's final position; intermediate cursor movements are invisible. Cursor-position-based clear logic does NOT work.
- `_imageFullyRendered` flag: prevents `onWriteChar` from clearing the image the moment it arrives (before `notifyListeners` fires)
- xterm.dart callback pattern: declare field → add constructor param → call `callback?.call(...)` inside the relevant method (see `onEraseDisplay` commit f8ac18b, `onWriteChar` commit 6d78f3f)

## Persistence Layout

| File | Owner | Contents |
|------|-------|----------|
| `~/.config/openterm/config.jsonc` | `ConfigFileService` | Settings, Profiles, Keymaps |
| `~/.config/openterm/hosts.json` | `SshStorageService` | SSH host list |
| `~/.config/openterm/keys.json` | `SshStorageService` | SSH key list |
| `~/.config/openterm/state.json` | `ReleaseNotesService` | App state (e.g. `last_seen_version`) |
