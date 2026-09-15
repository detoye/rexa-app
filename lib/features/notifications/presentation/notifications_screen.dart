import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifRepo = NotificationRepository();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  Stream<List<AppNotification>>? _notifStream;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _notifStream = _notifRepo.watchNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notifRepo.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'payment': return Icons.payment;
      case 'announcement': return Icons.campaign_outlined;
      case 'alert': return Icons.warning_amber_outlined;
      case 'guest': return Icons.person_add_outlined;
      case 'meeting': return Icons.groups_outlined;
      case 'comment': return Icons.comment_outlined;
      case 'like': return Icons.favorite_outline;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'payment': return RezaColors.successGreen;
      case 'announcement': return RezaColors.accentGold;
      case 'alert': return RezaColors.errorRed;
      case 'guest': return RezaColors.accentGold;
      case 'meeting': return RezaColors.primaryNavy;
      default: return RezaColors.textGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () async {
                await _notifRepo.markAllAsRead();
                _loadNotifications();
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: StreamBuilder<List<AppNotification>>(
                stream: _notifStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _notifications = snapshot.data!;
                  }
                  if (_notifications.isEmpty) {
                    return _buildEmptyState(Icons.notifications, 'No notifications');
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) => _buildNotificationTile(_notifications[index]),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: RezaColors.textGray, size: 40),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: RezaColors.textGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    final color = _getColor(notification.type);
    final icon = _getIcon(notification.type);

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await _notifRepo.markAsRead(notification.id);
          _loadNotifications();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? RezaColors.cardDark
              : RezaColors.accentGold.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead
              ? null
              : Border.all(color: RezaColors.accentGold.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: RezaColors.textWhite,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (notification.body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body!,
                      style: Theme.of(context).bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(_formatTime(notification.createdAt), style: const TextStyle(color: RezaColors.textGray, fontSize: 12)),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: RezaColors.accentGold,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
