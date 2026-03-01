import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:terminal_studio/src/platform/hosts/fs.dart';
import 'package:terminal_studio/src/platform/hosts/host.dart';
import 'package:terminal_studio/src/platform/hosts/ssh_fs.dart';

class SSHHost implements Host {
  /// [onDispose] is called by [disconnect] instead of directly closing the
  /// client, allowing [SSHConnectionPool] to manage the actual TCP lifetime
  /// via reference counting.
  SSHHost(this.client, [this._onDispose]);

  final SSHClient client;
  final void Function()? _onDispose;

  @override
  Future<ExecutionResult> execute(
    String executable, {
    List<String> args = const [],
    bool root = false,
    Map<String, String>? environment,
  }) async {
    final command = [executable, ...args].join(' ');
    final result = await client.execute(command, environment: environment);
    return _collectResult(result);
  }

  @override
  Future<FileSystem> connectFileSystem() async {
    final sftp = await client.sftp();
    final currentDirectory = await sftp.absolute('.');
    return SSHFileSystem(sftp, currentDirectory);
  }

  @override
  Future<ExecutionSession> shell({
    int width = 80,
    int height = 25,
    Map<String, String>? environment,
    String? command,
    List<String>? args,
    String? workingDirectory,
  }) async {
    final session = await client.shell(
      environment: environment,
      pty: SSHPtyConfig(
        height: height,
        width: width,
      ),
    );
    return _SSHExecutionSession(session);
  }

  @override
  Future<void> disconnect() async {
    if (_onDispose != null) {
      // Pool manages the actual client lifetime via reference counting.
      _onDispose!();
    } else {
      client.close();
    }
  }

  @override
  Future<void> get done => client.done;
}

Future<_SSHExecutionResult> _collectResult(SSHSession session) async {
  final stdout = StringBuffer();
  final stderr = StringBuffer();

  final stdoutStream = session.stdout.listen(
    (data) => stdout.write(String.fromCharCodes(data)),
  );

  final stderrStream = session.stderr.listen(
    (data) => stderr.write(String.fromCharCodes(data)),
  );

  await session.done;
  await stdoutStream.asFuture();
  await stderrStream.asFuture();

  return _SSHExecutionResult(
    exitCode: session.exitCode ?? 0,
    stdout: stdout.toString(),
    stderr: stderr.toString(),
  );
}

class _SSHExecutionResult implements ExecutionResult {
  _SSHExecutionResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  @override
  final int exitCode;

  @override
  final String stderr;

  @override
  final String stdout;
}

class _SSHExecutionSession implements ExecutionSession {
  _SSHExecutionSession(this.session);

  final SSHSession session;

  @override
  Future<void> close() async {
    session.close();
  }

  @override
  Future<void> resize(int width, int height) async {
    session.resizeTerminal(width, height);
  }

  @override
  Stream<Uint8List> get output => session.stdout;

  @override
  Future<void> write(Uint8List data) async {
    session.stdin.add(data);
  }

  @override
  Future<int> get exitCode async {
    await session.done;
    return session.exitCode ?? 0;
  }
}
