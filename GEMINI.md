# TerminalStudio Project Context

## Overview
TerminalStudio is a cross-platform terminal emulator built with **Flutter**. It is designed to be extensible and feature-rich, supporting local and SSH connections. The application uses a plugin-based architecture to manage different functionalities and host interactions.

### Architecture
*   **Framework:** Flutter (Mobile, Desktop, Web - though primarily targeted at Desktop).
*   **State Management:** `flutter_riverpod`.
*   **UI Library:** `fluent_ui` (Windows-style UI), `macos_ui` (macOS adaptations), and custom widgets.
*   **Terminal Engine:** Custom fork of `xterm.dart`.
*   **Core Concepts:**
    *   **Host:** Represents a connection target (e.g., Local machine, SSH server).
    *   **Plugin:** Modular units of functionality attached to a host manager (e.g., Terminal, File Manager).
    *   **Tabs:** Managed via `flex_tabs` and `TabsService`.

## Key Directories & Files

### Root
*   `pubspec.yaml`: Project dependencies and metadata. Notable dependencies include `dartssh2`, `xterm`, `flutter_pty`, `window_manager`.
*   `analysis_options.yaml`: Linting configuration using `flutter_lints: ^6.0.0`.
*   `README.md`: Basic setup instructions.

### Source Code (`lib/`)
*   `main.dart`: Application entry point. Initializes `window_manager`, sets up the `ProviderScope`, and launches the main `FluentApp`.
*   **`src/core/`**: Core abstractions and business logic.
    *   `plugin.dart`: Defines the `Plugin` abstract class and `PluginManager`. Plugins have lifecycles (`didMounted`, `didConnected`, etc.) and interactions with `Host`.
    *   `host.dart`: (Inferred) Defines the `Host` interface.
    *   **`service/`**: Application-level services (e.g., `TabsService`, `WindowService`).
    *   **`state/`**: State definitions (e.g., `Tabs`, `Database`).
*   **`src/hosts/`**: Implementations of connection types.
    *   `local_host.dart`, `ssh_host.dart`: Specific logic for different connection protocols.
    *   `local_spec.dart`: Specification for local connections.
*   **`src/plugins/`**: Concrete plugin implementations.
    *   `terminal/`: The actual terminal emulator plugin.
    *   `file_manager/`: File management capabilities.
*   **`src/ui/`**: UI components and pages.
    *   `shared/`: Reusable widgets.
    *   `platform_menu.dart`: Platform-specific menu handling.

## Build & Run

### Prerequisites
1.  **Flutter SDK:** Version constraint `>=3.0.0 <4.0.0` (as per `pubspec.yaml`, verify compatibility with modern Flutter if needed).
2.  **Git Submodules:** The project relies on submodules (likely for `xterm.dart`).

### Setup Commands
```bash
# Initialize submodules
git submodule update --init

# Update submodules
git pull --recurse-submodules

# Get dependencies
flutter pub get
```

### Running the App
```bash
# Run on the current platform (macOS/Windows/Linux)
flutter run -d macos
# or
flutter run -d windows
# or
flutter run -d linux
```

## Development Conventions

*   **Linting:** Adheres to `flutter_lints`. Run `flutter analyze` to check for issues.
*   **Formatting:** Use `dart format .` to maintain code style.
*   **Structure:**
    *   Keep core logic in `src/core`.
    *   Implement specific features as plugins in `src/plugins`.
    *   UI components should ideally be separated from business logic.
*   **Platform Specifics:** The app explicitly handles platform differences (e.g., Titlebars, Window controls) in `main.dart` and `ui/`. Respect these checks when adding new UI features.

## Tasks & TODOs
*   **Submodules:** Ensure `xterm` submodule is checked out correctly before building.
*   **Platform Support:** Check `linux/` and `windows/` directories for platform-specific configurations if working on those OSs.
