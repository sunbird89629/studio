import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_studio/src/core/command/command.dart';
import 'package:terminal_studio/src/core/command/command_registry.dart';
import 'package:terminal_studio/src/core/conn.dart';
import 'package:terminal_studio/src/core/exceptions.dart';
import 'package:terminal_studio/src/core/fs.dart';
import 'package:terminal_studio/src/core/host.dart';
import 'package:terminal_studio/src/core/plugin.dart';

// ── Minimal fakes ─────────────────────────────────────────────────────────────

class _FakeHost extends Host {
  @override
  Future<ExecutionResult> execute(String executable,
          {List<String> args = const [],
          bool root = false,
          Map<String, String>? environment}) =>
      throw UnimplementedError();

  @override
  Future<ExecutionSession> shell(
          {Map<String, String>? environment,
          int height = 25,
          int width = 80,
          String? command,
          List<String>? args,
          String? workingDirectory}) =>
      throw UnimplementedError();

  @override
  Future<FileSystem> connectFileSystem() => throw UnimplementedError();

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> get done => Completer<void>().future;
}

class _FakeHostSpec extends HostSpec {
  @override
  String get name => 'Fake';

  @override
  HostConnector createConnector() => throw UnimplementedError();
}

/// Records the order of lifecycle method calls.
class _SpyPlugin extends Plugin {
  final List<String> calls = [];

  /// Whether [manager] is non-null when [didMounted] is invoked.
  bool? managerAvailableOnMount;

  @override
  void didMounted() {
    // `mounted` is the public equivalent of `_manager != null`
    managerAvailableOnMount = mounted;
    calls.add('mounted');
  }

  @override
  void didConnected() => calls.add('connected');

  @override
  void didDisconnected() => calls.add('disconnected');

  @override
  void didUnmounted() => calls.add('unmounted');

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}

/// Plugin whose [didUnmounted] always throws.
class _ThrowOnUnmountPlugin extends Plugin {
  @override
  void didUnmounted() => throw PluginException('intentional failure');

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}

// Provide a real Ref via a Provider so PluginManager can be constructed.
final _managerProvider = Provider<PluginManager>(
  (ref) => PluginManager(_FakeHostSpec(), ref),
);

PluginManager _makeManager() =>
    ProviderContainer().read(_managerProvider);

// ── Plugin lifecycle tests ─────────────────────────────────────────────────────

void main() {
  group('PluginManager.add() ordering', () {
    test('manager is assigned before didMounted() is called', () {
      final manager = _makeManager();
      final plugin = _SpyPlugin();

      manager.add(plugin);

      expect(plugin.managerAvailableOnMount, isTrue,
          reason: 'plugin._manager must be set before didMounted() fires');
    });

    test('plugin appears in plugins list after add()', () {
      final manager = _makeManager();
      final plugin = _SpyPlugin();

      manager.add(plugin);

      expect(manager.plugins, contains(plugin));
      expect(plugin.calls, ['mounted']);
    });

    test('throws PluginException when plugin already mounted', () {
      final manager = _makeManager();
      final plugin = _SpyPlugin();

      manager.add(plugin);

      expect(() => manager.add(plugin), throwsA(isA<PluginException>()));
    });
  });

  group('PluginManager.remove() safety', () {
    test('plugin is fully detached even when didUnmounted() throws', () {
      final manager = _makeManager();
      final plugin = _ThrowOnUnmountPlugin();

      manager.add(plugin);

      // remove() re-throws from the try/finally but still detaches the plugin.
      expect(() => manager.remove(plugin), throwsA(isA<PluginException>()));

      // Plugin should be fully detached: mounted=false, plugins list clear.
      expect(plugin.mounted, isFalse);
      expect(manager.plugins, isNot(contains(plugin)));
    });

    test('throws PluginException when plugin not mounted to this manager', () {
      final m1 = _makeManager();
      final m2 = _makeManager();
      final plugin = _SpyPlugin();

      m1.add(plugin);

      expect(() => m2.remove(plugin), throwsA(isA<PluginException>()));
    });

    test('lifecycle order: mounted → connected → disconnected → unmounted', () {
      final manager = _makeManager();
      final plugin = _SpyPlugin();
      final host = _FakeHost();

      manager.add(plugin);
      manager.didConnected(host);
      manager.didDisconnected();
      manager.remove(plugin);

      expect(plugin.calls,
          ['mounted', 'connected', 'disconnected', 'unmounted']);
    });
  });

  group('Plugin accessors throw PluginException when not mounted', () {
    test('manager getter throws when not mounted', () {
      final plugin = _SpyPlugin();
      expect(() => plugin.manager, throwsA(isA<PluginException>()));
    });

    test('hostSpec getter throws when not mounted', () {
      final plugin = _SpyPlugin();
      expect(() => plugin.hostSpec, throwsA(isA<PluginException>()));
    });

    test('host getter throws when not connected', () {
      final manager = _makeManager();
      final plugin = _SpyPlugin();

      manager.add(plugin);

      expect(() => plugin.host, throwsA(isA<PluginException>()));
    });
  });

  // ── CommandRegistry ──────────────────────────────────────────────────────────

  group('CommandRegistry search', () {
    late CommandRegistry registry;

    _FakeCommand cmd(String id, String label, {String? category}) =>
        _FakeCommand(id: id, label: label, category: category);

    setUp(() {
      registry = CommandRegistry();
      registry.registerAll([
        cmd('file.new', 'New File', category: 'File'),
        cmd('file.open', 'Open File', category: 'File'),
        cmd('edit.copy', 'Copy', category: 'Edit'),
        cmd('view.toggle', 'Toggle Sidebar', category: 'View'),
      ]);
    });

    test('empty query returns all commands', () {
      expect(registry.search('').length, 4);
    });

    test('exact label prefix match scores highest', () {
      final results = registry.search('New');
      expect(results.first.id, 'file.new');
    });

    test('label contains match', () {
      final ids = registry.search('File').map((c) => c.id);
      expect(ids, containsAll(['file.new', 'file.open']));
    });

    test('category match included', () {
      expect(registry.search('Edit').map((c) => c.id), contains('edit.copy'));
    });

    test('no match returns empty list', () {
      expect(registry.search('zzz'), isEmpty);
    });

    test('register duplicate id throws StateError', () {
      expect(
        () => registry.register(cmd('file.new', 'Duplicate')),
        throwsA(isA<StateError>()),
      );
    });

    test('unregister removes command', () {
      registry.unregister('edit.copy');
      expect(registry.get('edit.copy'), isNull);
    });
  });
}

// ── Fake command ──────────────────────────────────────────────────────────────

class _FakeCommand extends Command {
  @override
  final String id;
  @override
  final String label;
  @override
  final String? category;

  _FakeCommand({required this.id, required this.label, this.category});

  @override
  void execute(BuildContext context, WidgetRef ref) {}
}

