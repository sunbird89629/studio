import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:terminal_studio/src/core/service/remote_control_service.dart';
import 'package:terminal_studio/src/core/service/tunnel_service.dart';
import 'package:terminal_studio/src/core/log/app_logger.dart';

class NotificationService {
  final _logger = AppLogger.forComponent('NotificationService');

  Future<void> sendLarkNotification(String webhookUrl, String content) async {
    if (webhookUrl.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'msg_type': 'text',
          'content': {
            'text': content,
          },
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logger.i('Lark notification sent successfully');
      } else {
        _logger.e('Failed to send Lark notification: ${response.body}');
      }
    } catch (e) {
      _logger.e('Error sending Lark notification: $e');
    }
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());

/// Provider that listens to tunnel status changes and triggers notifications.
final tunnelObserverProvider = Provider<void>((ref) {
  final notificationService = ref.read(notificationServiceProvider);

  ref.listen<TunnelState>(tunnelServiceProvider, (previous, next) {
    // Only notify if status has changed
    if (previous?.status == next.status) return;

    final remoteState = ref.read(remoteControlServiceProvider);
    final webhookUrl = remoteState.larkWebhookUrl;

    if (webhookUrl == null || webhookUrl.isEmpty) return;

    String? message;

    switch (next.status) {
      case TunnelStatus.connected:
        if (next.publicUrl != null) {
          message =
              '🚀 Cloudflare Tunnel 已上线！\n访问地址: ${next.publicUrl}?token=${remoteState.authToken}';
        } else if (next.tunnelId != null) {
          message = '✅ Cloudflare Tunnel (持久化) 已连接！\nID: ${next.tunnelId}';
        }
        break;
      case TunnelStatus.error:
        message = '⚠️ Cloudflare Tunnel 异常！\n错误信息: ${next.error ?? "未知错误"}';
        break;
      case TunnelStatus.reconnecting:
        message = '🔄 Cloudflare Tunnel 连接中断，正在尝试重新连接...';
        break;
      default:
        break;
    }

    if (message != null) {
      // Add timestamp to avoid Lark message deduplication if same message sent rapidly
      final now = DateTime.now().toLocal();
      final timestamp = '${now.hour}:${now.minute}:${now.second}';
      notificationService.sendLarkNotification(
        webhookUrl,
        '[$timestamp] $message',
      );
    }
  });
});
