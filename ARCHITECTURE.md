# Terminal Studio 架构分析

## 目录
1. [整体架构](#整体架构)
2. [核心层次](#核心层次)
3. [关键设计模式](#关键设计模式)
4. [数据流](#数据流)
5. [模块详解](#模块详解)

---

## 整体架构

Terminal Studio 采用 **分层架构 + 插件系统** 的设计，基于 Flutter + Riverpod 构建。

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (视图层)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Tabs     │  │ Command  │  │ Copilot  │  │ Menus   │ │
│  │ System   │  │ Palette  │  │ Sidebar  │  │ Context │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Service Layer (服务层)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Tabs     │  │ AI       │  │ Tunnel   │  │ Window  │ │
│  │ Service  │  │ Service  │  │ Service  │  │ Service │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Core Layer (核心层)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Plugin   │  │ Host     │  │ Command  │  │ Theme   │ │
│  │ System   │  │ Connector│  │ Registry │  │ System  │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                State Management (状态管理)                │
│              Riverpod Providers + Hive DB                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                 Platform Layer (平台层)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ Local    │  │ SSH      │  │ File     │              │
│  │ PTY      │  │ Client   │  │ System   │              │
│  └──────────┘  └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘
```

---

## 核心层次

### 1. **UI Layer (视图层)**
负责用户界面展示和交互。

**关键组件：**
- **Tabs System** (`flex_tabs`): 多标签页管理
- **Command Palette**: 命令面板，快速执行命令
- **Copilot Sidebar**: AI 辅助侧边栏
- **Context Menu**: 右键菜单
- **Platform Menu**: 平台原生菜单（macOS/Windows）
- **Shortcuts**: 全局快捷键系统

**平台适配：**
- macOS: `macos_ui` + `flutter_acrylic` (毛玻璃效果)
- Windows: `fluent_ui` (Fluent Design)
- 通用: Material Design

---

### 2. **Service Layer (服务层)**
提供业务逻辑和功能服务。

| 服务 | 职责 |
|------|------|
| `TabsService` | 管理标签页的创建、打开、关闭 |
| `AICopilotService` | AI 功能（通过 OpenRouter API） |
| `TunnelService` | Cloudflared 隧道管理 |
| `RemoteControlService` | 远程控制 WebSocket 服务 |
| `CommandPaletteService` | 命令面板状态管理 |
| `VimEditService` | Vim 编辑模式 |
| `NotificationService` | 通知系统 |
| `WindowService` | 窗口管理 |

---

### 3. **Core Layer (核心层)**
系统的核心抽象和实现。

#### 3.1 Plugin System (插件系统)

**核心类：**
```dart
abstract class Plugin {
  PluginManager? _manager;
  HostSpec? _hostSpec;
  Host? _host;
  
  // 生命周期钩子
  void didMounted() {}
  void didUnmounted() {}
  void didConnected() {}
  void didDisconnected() {}
  
  Widget build(BuildContext context);
}
```

**设计思想：**
- 插件是功能的最小单元
- 每个插件绑定到一个 `Host`（本地或远程）
- 通过 `PluginManager` 管理生命周期
- 支持动态加载/卸载

**内置插件：**
- `TerminalPlugin`: 终端模拟器
- `FileManagerPlugin`: 文件管理器
- `StarterPlugin`: 启动器

#### 3.2 Host System (主机系统)

**三层抽象：**

```
HostSpec (配置)
    ↓
HostConnector (连接器)
    ↓
Host (实际主机)
```

**接口定义：**
```dart
abstract class Host {
  Future<FileSystem> connectFileSystem();
  Future<ExecutionResult> execute(String executable, ...);
  Future<ExecutionSession> shell(...);
  Future<void> disconnect();
}
```

**实现类：**
- `LocalHost`: 本地主机（使用 `flutter_pty`）
- `SSHHost`: SSH 远程主机（使用 `dartssh2`）

**状态管理：**
```dart
enum HostConnectorStatus {
  initialized,
  connecting,
  connected,
  disconnected,
  aborted,
}
```

#### 3.3 Command System (命令系统)

**架构：**
```
Command (抽象命令)
    ↓
CommandRegistry (命令注册表)
    ↓
CommandPalette (命令面板 UI)
```

**命令类型：**
- `Command`: 基础命令接口
- `IntentCommand`: 基于 Flutter Intent 的命令
- `ThemeCommands`: 主题切换命令
- `BuiltinCommands`: 内置命令（新建标签、关闭等）

**搜索算法：**
- 完全匹配开头: 100 分
- 包含查询: 80 分
- 分类匹配: 60 分
- 模糊匹配: 40 分

#### 3.4 Theme System (主题系统)

**架构：**
```
ThemePlugin (主题插件)
    ↓
ThemeRegistry (主题注册表)
    ↓
ThemeService (主题服务)
```

**内置主题：**
- Light / Dark
- Monokai
- Dracula
- One Dark
- Nord
- Solarized (Dark/Light)
- GitHub (Dark/Light)

---

### 4. **State Management (状态管理)**

使用 **Riverpod** 作为状态管理方案。

**核心 Providers：**

| Provider | 类型 | 职责 |
|----------|------|------|
| `tabsProvider` | Provider | 标签页文档 |
| `connectorProvider` | Family | 主机连接器 |
| `connectorStatusProvider` | StreamProvider | 连接状态流 |
| `hostProvider` | Family | 主机实例 |
| `pluginManagerProvider` | Family | 插件管理器 |
| `themeRegistryProvider` | Provider | 主题注册表 |
| `activeThemeProvider` | Provider | 当前主题 |
| `settingsProvider` | FutureProvider | 用户设置 |
| `aiCopilotServiceProvider` | Provider | AI 服务 |

**数据持久化：**
使用 **Hive** 本地数据库：
- `ssh_hosts`: SSH 主机配置
- `ssh_keys`: SSH 密钥
- `settings`: 用户设置（主题、字体、AI API Key 等）

---

### 5. **Platform Layer (平台层)**

#### 5.1 本地终端
- **库**: `flutter_pty`
- **功能**: 创建本地 PTY (伪终端)
- **平台**: macOS, Linux, Windows

#### 5.2 SSH 客户端
- **库**: `dartssh2`
- **功能**: SSH 连接、命令执行、SFTP
- **认证**: 密码 / 密钥

#### 5.3 文件系统
- **抽象**: `FileSystem` 接口
- **实现**: 
  - `LocalFileSystem`: 本地文件系统
  - `SSHFileSystem`: 远程 SFTP

---

## 关键设计模式

### 1. **插件模式 (Plugin Pattern)**
- 核心功能通过插件扩展
- 插件生命周期由 `PluginManager` 管理
- 支持热插拔

### 2. **策略模式 (Strategy Pattern)**
- `Host` 接口定义统一行为
- `LocalHost` / `SSHHost` 实现不同策略

### 3. **观察者模式 (Observer Pattern)**
- Riverpod 的 Provider 系统
- `ChangeNotifier` 用于状态通知

### 4. **注册表模式 (Registry Pattern)**
- `CommandRegistry`: 命令注册
- `ThemeRegistry`: 主题注册

### 5. **工厂模式 (Factory Pattern)**
- `HostSpec.createConnector()`: 创建连接器
- `HostConnector.createHost()`: 创建主机实例

---

## 数据流

### 1. **终端启动流程**

```
用户点击 "新建终端"
    ↓
TabsService.openTerminal(hostSpec)
    ↓
创建 TerminalPlugin 实例
    ↓
PluginManager.add(plugin)
    ↓
plugin.didMounted() - 初始化终端
    ↓
HostConnector.connect() - 连接主机
    ↓
plugin.didConnected() - 启动 shell
    ↓
ExecutionSession 创建
    ↓
数据流：
  用户输入 → Terminal.onOutput → session.write()
  Shell 输出 → session.output → Terminal.write()
```

### 2. **主机连接流程**

```
HostSpec (配置)
    ↓
connectorProvider(spec) - 创建 Connector
    ↓
connector.connect()
    ↓
state = connecting
    ↓
createHost() - 创建 Host 实例
    ↓
state = connected
    ↓
notifyListeners() - 通知所有监听者
    ↓
connectorStatusProvider 发出新状态
    ↓
hostProvider 返回 Host 实例
    ↓
PluginManager.didConnected(host)
    ↓
所有插件收到 didConnected() 回调
```

### 3. **命令执行流程**

```
用户按下快捷键 (Cmd+P)
    ↓
GlobalShortcuts 触发 Intent
    ↓
GlobalActions 执行 Action
    ↓
CommandPaletteService.show()
    ↓
显示 CommandPaletteOverlay
    ↓
用户输入搜索
    ↓
CommandRegistry.search(query)
    ↓
返回匹配的命令列表
    ↓
用户选择命令
    ↓
command.execute(context)
```

### 4. **主题切换流程**

```
用户选择主题
    ↓
ThemeService.setTheme(themeId)
    ↓
验证主题是否存在
    ↓
更新 Hive 数据库
    ↓
settings.themeId = themeId
    ↓
settingsProvider 自动刷新
    ↓
themeIdProvider 返回新 ID
    ↓
activeThemeProvider 重新计算
    ↓
UI 重建，应用新主题
```

---

## 模块详解

### 1. **标签页系统**

**核心组件：**
- `TabsDocument`: 标签页文档（来自 `flex_tabs`）
- `TabItem`: 标签页项
- `PluginTab`: 插件标签页
- `CodeEditorTab`: 代码编辑器标签页

**特性：**
- 多标签页
- 拖拽重排
- 分组管理
- 持久化（TODO）

### 2. **AI 集成**

**架构：**
```
AICopilotService
    ↓
OpenRouter API
    ↓
支持多种模型：
  - Google Gemini
  - OpenAI GPT
  - Anthropic Claude
  - 等
```

**功能：**
- 命令生成（TODO）
- 错误解释（TODO）
- 代码补全（TODO）

**日志系统：**
- `AILogger`: 结构化日志
- 支持上下文（component, operation）
- 日志级别：debug, info, warning, error

### 3. **远程控制**

**架构：**
```
RemoteControlService
    ↓
Shelf + WebSocket
    ↓
Cloudflared Tunnel
    ↓
公网访问
```

**功能：**
- 远程查看终端输出
- 远程输入命令（TODO）
- 多客户端同步

### 4. **快捷键系统**

**层次：**
```
GlobalShortcuts (Widget)
    ↓
Intent (意图)
    ↓
GlobalActions (Widget)
    ↓
Action (动作)
```

**内置快捷键：**
- `Cmd/Ctrl + T`: 新建终端
- `Cmd/Ctrl + W`: 关闭标签
- `Cmd/Ctrl + P`: 命令面板
- `Cmd/Ctrl + ,`: 设置
- `Cmd/Ctrl + Shift + P`: Copilot

---

## 扩展点

### 如何添加新插件？

1. 继承 `Plugin` 类
2. 实现生命周期方法
3. 实现 `build()` 方法
4. 在 `TabsService` 中添加打开方法

```dart
class MyPlugin extends Plugin {
  @override
  void didConnected() {
    // 连接后的初始化
  }
  
  @override
  Widget build(BuildContext context) {
    return MyPluginUI();
  }
}
```

### 如何添加新主题？

1. 继承 `ThemePlugin`
2. 实现 `id`, `name`, `terminalTheme`, `fluentTheme`
3. 在 `themeRegistryProvider` 中注册

```dart
class MyTheme extends ThemePlugin {
  @override
  String get id => 'my-theme';
  
  @override
  String get name => 'My Theme';
  
  @override
  TerminalTheme get terminalTheme => TerminalTheme(...);
  
  @override
  FluentThemeData get fluentTheme => FluentThemeData(...);
}
```

### 如何添加新命令？

1. 实现 `Command` 接口
2. 在 `CommandRegistry` 中注册

```dart
class MyCommand implements Command {
  @override
  String get id => 'my.command';
  
  @override
  String get label => 'My Command';
  
  @override
  Future<void> execute(BuildContext context) async {
    // 执行逻辑
  }
}
```

---

## 技术栈总结

| 层次 | 技术 |
|------|------|
| UI 框架 | Flutter 3.0+ |
| 状态管理 | Riverpod |
| 本地数据库 | Hive |
| 终端模拟 | xterm.dart |
| 本地 PTY | flutter_pty |
| SSH 客户端 | dartssh2 |
| AI 服务 | OpenRouter API |
| 窗口管理 | window_manager |
| 标签页 | flex_tabs |
| 平台 UI | macos_ui, fluent_ui |
| 特效 | flutter_acrylic |
| 代码编辑 | code_text_field, flutter_highlight |
| Web 服务 | shelf, shelf_web_socket |

---

## 待完善功能

根据 `TODO.md`：

1. **可视化设置页面**
   - 字体、字号、透明度配置
   - 快捷键自定义
   - 默认 Shell 配置

2. **AI Copilot 完善**
   - 命令生成
   - 错误解释
   - 智能补全

3. **用户引导**
   - 欢迎页
   - 快捷键提示
   - 功能介绍

4. **标签页持久化**
   - 保存会话
   - 恢复会话

5. **文件管理器**
   - 完善 UI
   - 文件操作

---

## 总结

Terminal Studio 是一个架构清晰、设计优雅的现代化终端模拟器：

**优势：**
✅ 插件化架构，易于扩展  
✅ 跨平台支持完整  
✅ 状态管理清晰（Riverpod）  
✅ 主题系统灵活  
✅ AI 集成具备竞争力  
✅ 代码结构良好，职责分明  

**改进方向：**
🔧 完善用户设置 UI  
🔧 增强 AI 功能  
🔧 添加用户引导  
🔧 完善文档和测试  
🔧 优化性能和内存占用  

这是一个具有良好基础和发展潜力的项目！
