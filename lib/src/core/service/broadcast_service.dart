import 'dart:convert';

import 'package:terminal_studio/src/plugins/terminal/terminal_plugin.dart';

/// Manages a shared broadcast group: when a terminal plugin is a participant,
/// any user input is mirrored to every other terminal in the group.
///
/// This is a static singleton; lifecycle management is done via
/// [register] / [deregister] from [TerminalPlugin].
class BroadcastService {
  BroadcastService._();

  static final instance = BroadcastService._();

  final Set<TerminalPlugin> _participants = {};

  /// Whether [plugin] is currently in the broadcast group.
  bool isParticipant(TerminalPlugin plugin) => _participants.contains(plugin);

  /// Number of terminals currently in the broadcast group.
  int get participantCount => _participants.length;

  /// Adds [plugin] to the broadcast group.
  void register(TerminalPlugin plugin) {
    _participants.add(plugin);
  }

  /// Removes [plugin] from the broadcast group.
  void deregister(TerminalPlugin plugin) {
    _participants.remove(plugin);
  }

  /// Sends [data] to all participants except [sender].
  ///
  /// No-op if [sender] is not a participant or there are no other participants.
  void broadcast(TerminalPlugin sender, String data) {
    if (!isParticipant(sender) || _participants.length < 2) return;
    final bytes = const Utf8Encoder().convert(data);
    for (final p in _participants) {
      if (p != sender) {
        p.session?.write(bytes);
      }
    }
  }
}
