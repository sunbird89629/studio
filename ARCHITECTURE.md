# Terminal Studio 架构文档

## 1. 概览

Terminal Studio 当前采用 **Modular Monolith（模块化单体）** 架构，核心目录分为三层：

- `features/`：按业务能力拆分（设置、终端、标签、SSH、命令面板等）
- `platform/`：底层运行时与平台抽象（Host、Plugin Runtime）
- `shared/`：跨模块复用能力（日志、主题、模型、通用状态与工具）

状态管理使用 **Riverpod**；桌面能力基于 Flutter 桌面生态（`flutter_pty`、`window_manager`、`dartssh2` 等）。

---

## 2. 目录结构

当前 `lib/src` 结构：

```text
lib/src/
  features/
    command_palette/
      application/
      presentation/
    copilot/
      application/
      infrastructure/
      presentation/
    file_manager/
      application/
      presentation/
    remote_control/
      application/
    settings/
      application/
      domain/
      infrastructure/
      presentation/
    ssh/
      infrastructure/
      presentation/
    tabs/
      application/
      presentation/
    terminal/
      application/
      presentation/
      runtime/
    tunnel/
      application/

  platform/
    hosts/
    plugins/

  shared/
    constants/
    logging/
    models/
    state/
    theme/
    utils/
    widgets/
```

---

## 3. 分层职责

### 3.1 `features/`（业务层）

按业务能力组织代码，每个 feature 内遵循轻量分层：

- `application/`：Riverpod providers、notifier、用例编排
- `domain/`：纯业务模型与规则（如 `effective_settings`）
- `infrastructure/`：外部系统访问（文件、网络、API）
- `presentation/`：Widget/UI 与交互
- `runtime/`：纯终端运行时能力（输入输出、会话能力接口、状态读模型）

核心 feature：

- `tabs`：标签页管理、主页面布局、平台菜单、日志面板
- `terminal`：终端插件、输入跟踪、终端菜单
  - 现已拆分为：
    - `application/terminal_plugin.dart`：插件生命周期与组装
    - `presentation/terminal_tab_view.dart`：终端 UI 与 overlays
    - `runtime/terminal_runtime.dart`：跨 feature 的运行时能力接口
- `settings`：配置加载/保存、快捷键、主题与配置导入导出
- `ssh`：SSH 主机编辑与持久化
- `command_palette`：命令模型、注册、搜索、执行
- `copilot`：AI 对话与模型选择
- `remote_control`：远程控制服务（WebSocket）
- `tunnel`：Cloudflared 隧道状态管理

### 3.2 `platform/`（平台核心）

- `platform/hosts/`
  - `HostSpec -> HostConnector -> Host` 三层抽象
  - 本地与 SSH 两套实现（`Local*` / `Ssh*`）
- `platform/plugins/`
  - `Plugin` 抽象
  - `PluginManager` 生命周期管理
  - 插件 Provider 绑定（按 Host 维度）

插件生命周期方法：

- `onMounted()`
- `onConnected()`
- `onDisconnected()`
- `onUnmounted()`
- `onConnectionStatus(...)`

### 3.3 `shared/`（共享层）

- `shared/logging`：统一日志模型与输出
- `shared/theme`：主题注册、主题 Provider、主题插件
- `shared/models`：跨 feature 复用数据结构
- `shared/state`：跨域事件与状态（通知、日志可见性等）
- `shared/utils`：工具函数
- `shared/widgets`：复用 UI 组件

---

## 4. 状态管理（Riverpod）

系统以 Riverpod 为主，典型 provider：

- 终端与连接
  - `connectorProvider`
  - `connectorStatusProvider`
  - `hostProvider`
  - `pluginManagerProvider`
- 标签与导航
  - `tabsProvider`
  - `tabsServiceProvider`
  - `activeTabServiceProvider`
- 设置与主题
  - `settingsProvider`
  - `profilesProvider`
  - `keymapProvider`
  - `themeRegistryProvider`
  - `activeThemeProvider`
- 功能状态
  - `commandPaletteServiceProvider`
  - `vimEditServiceProvider`
  - `remoteControlServiceProvider`
  - `tunnelServiceProvider`

说明：历史命名中仍有少量 `*ServiceProvider` 保留（实际可能是 Notifier），属于兼容命名。

---

## 5. 数据持久化

当前持久化方式为 **文件存储**（非 Hive）：

- `~/.config/openterm/config.jsonc`
  - 全局设置、profiles、keymaps、snippets
- `~/.config/openterm/hosts.json`
  - SSH 主机列表
- `~/.config/openterm/keys.json`
  - SSH 密钥列表

`settings` 相关配置支持文件监听与热刷新（Provider 失效重载）。

---

## 6. 关键流程

### 6.1 打开终端

1. UI 触发 `tabsServiceProvider.openTerminal(...)`
2. 构建 `TerminalPlugin`
3. 通过 `pluginManagerProvider(hostSpec)` 绑定插件管理器
4. `HostConnector.connect()` 建立连接
5. 插件收到 `onConnected()`，启动 shell 会话
6. 输入输出通过 `ExecutionSession` 与终端组件双向流转

### 6.2 命令面板执行

1. 快捷键触发显示 `CommandPalette`
2. `CommandPaletteNotifier` 根据 query 搜索 `CommandRegistry`
3. 用户选择命令后执行 `command.execute(context, ref)`
4. 命令通过 provider 调用对应 feature 服务

### 6.3 主题切换

1. 调用 `ThemeService.setTheme(themeId)`
2. 写入 `config.jsonc`
3. `settingsProvider` 失效重建
4. `themeIdProvider`/`activeThemeProvider` 重新计算
5. MaterialApp 主题热更新

---

## 7. 设计原则

- **按业务组织**：优先 feature 内聚，而非全局 service 堆积
- **平台抽象稳定**：Host/Plugin Runtime 作为核心能力边界
- **共享最小化**：`shared` 只放真正跨域复用内容
- **渐进重构友好**：通过 Riverpod provider 边界降低迁移风险

---

## 8. 扩展指南

### 8.1 新增插件

1. 在对应 feature 创建插件类并继承 `Plugin`
2. 实现生命周期与 `build()`
3. 在 `TabsService` 或对应入口增加打开路径

### 8.2 新增命令

1. 实现 `Command`
2. 在 `CommandPaletteNotifier` 的注册流程加入新命令

### 8.3 新增主题

1. 实现 `ThemePlugin`
2. 在 `themeRegistryProvider` 中注册

---

## 9. 当前已知技术债（非阻断）

- 少量 provider 命名沿用历史 `*ServiceProvider`，语义可进一步统一
- `features/*/(domain|infrastructure)` 存在空目录（为后续扩展预留）
- `flutter analyze` 仍有若干 info/warning（不影响编译与测试）
