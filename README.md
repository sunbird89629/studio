## OpenTerm

An open-source, AI-powered, plugin-driven terminal emulator built with **Flutter**.

<img width="700px" src="https://raw.githubusercontent.com/sunbird89629/open_term/master/media/demo.png">

## Highlights

- **Open Source** — Cross-platform desktop terminal for macOS, Windows and Linux
- **AI** — Built-in AI copilot powered by Gemini / OpenAI
- **Plugins** — Extensible plugin system: Terminal, File Manager, SSH and more

## Build

```bash
git submodule update --init
git pull --recurse-submodules

flutter pub get
flutter run -d macos    # or: -d windows, -d linux
```

## Configuration

Configuration file location: `~/.config/openterm/config.jsonc`

- macOS / Linux: `~/.config/openterm/config.jsonc`
- Windows: `C:\Users\<username>\.config\openterm\config.jsonc`
