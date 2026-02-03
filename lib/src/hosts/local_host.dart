import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:terminal_studio/src/core/fs.dart' hide File, Directory, Link;
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/hosts/local_fs.dart';

class LocalHost implements Host {
  @override
  Future<ExecutionResult> execute(
    String executable, {
    List<String> args = const [],
    bool root = false,
    Map<String, String>? environment,
  }) async {
    final result =
        await io.Process.run(executable, args, environment: environment);
    return LocalExecutionResult(result);
  }

  @override
  Future<FileSystem> connectFileSystem() async {
    return LocalFileSystem();
  }

  @override
  Future<LocalExecutionSession> shell({
    int width = 80,
    int height = 25,
    Map<String, String>? environment,
    String? command,
    List<String>? args,
  }) async {
    final shellCommand =
        command != null ? _ShellCommand(command, args ?? []) : _platformShell;

    final resolvedCommand = _resolveCommand(shellCommand.command);
    if (!io.File(resolvedCommand).existsSync()) {
      throw StateError('Shell executable not found at $resolvedCommand. '
          'Please ensure your shell is correctly configured.');
    }

    print('Starting shell: $resolvedCommand ${shellCommand.args}');
    print('Environment USER: ${io.Platform.environment['USER']}');

    try {
      final env = {
        'TERM': 'xterm-256color',
        ...io.Platform.environment,
        ...environment ?? {},
      };

      final String? home = io.Platform.environment['HOME'];
      final pty = Pty.start(
        resolvedCommand,
        arguments: shellCommand.args,
        environment: env,
        workingDirectory: home,
        rows: height,
        columns: width,
      );
      print('Pty started successfully: $pty');
      return LocalExecutionSession(pty);
    } catch (e) {
      print('Failed to start Pty: $e');
      rethrow;
    }
  }

  final _doneCompleter = Completer<void>();

  @override
  Future<void> disconnect() async {
    _doneCompleter.complete();
  }

  @override
  Future<void> get done => _doneCompleter.future;

  String _resolveCommand(String command) {
    if (command.startsWith('/') ||
        command.startsWith('./') ||
        command.startsWith('../') ||
        io.Platform.isWindows) {
      return command;
    }

    // Try common locations for Unix systems
    final searchPaths = [
      '/bin/$command',
      '/usr/bin/$command',
      '/usr/local/bin/$command',
      '/opt/homebrew/bin/$command',
    ];

    for (final path in searchPaths) {
      if (io.File(path).existsSync()) {
        return path;
      }
    }

    return command;
  }
}

class LocalExecutionResult implements ExecutionResult {
  final io.ProcessResult _result;

  LocalExecutionResult(this._result);

  @override
  int get exitCode => _result.exitCode;

  @override
  String get stderr => _result.stderr;

  @override
  String get stdout => _result.stdout;
}

class LocalExecutionSession implements ExecutionSession {
  final Pty _pty;

  LocalExecutionSession(this._pty);

  @override
  Future<int> get exitCode => _pty.exitCode;

  @override
  Stream<Uint8List> get output {
    return _pty.output.map((data) {
      print('Pty output: ${data.length} bytes: ${String.fromCharCodes(data)}');
      return data;
    });
  }

  @override
  Future<void> close() async {
    _pty.kill();
  }

  @override
  Future<void> resize(int width, int height) async {
    _pty.resize(height, width);
  }

  @override
  Future<void> write(Uint8List data) async {
    _pty.write(data);
  }
}

class _ShellCommand {
  final String command;

  final List<String> args;

  _ShellCommand(this.command, this.args);
}

_ShellCommand get _platformShell {
  if (io.Platform.isMacOS || io.Platform.isLinux) {
    final shellEnv = io.Platform.environment['SHELL'];
    final shell = shellEnv ?? (io.Platform.isMacOS ? 'zsh' : 'bash');
    return _ShellCommand(shell, ['-l']);
  }

  if (io.Platform.isWindows) {
    return _ShellCommand('powershell.exe', []);
  }

  // Fallback
  return _ShellCommand('sh', []);
}
