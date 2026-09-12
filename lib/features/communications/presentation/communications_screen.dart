import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../data/repositories/announcement_repository.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> {
  final _announcementRepo = AnnouncementRepository();
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _estateId;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      _estateId = await _announcementRepo.getCurrentEstateId();
      if (_estateId != null) {
        final announcements = await _announcementRepo.getAnnouncements(_estateId!);
        setState(() {
          _announcements = announcements;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load announcements: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Communications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () => _showCreateAnnouncementSheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: RezaColors.accentGold),
            )
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: RezaColors.textGray.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No announcements yet',
                        style: TextStyle(color: RezaColors.textGray, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create an announcement to get started',
                        style: TextStyle(color: RezaColors.textGray.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = _announcements[index];
                      return _buildAnnouncementTile(announcement);
                    },
                  ),
                ),
    );
  }

  Widget _buildAnnouncementTile(Announcement announcement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RezaColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ANNOUNCEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: RezaColors.accentGold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(announcement.createdAt),
                style: const TextStyle(color: RezaColors.textGray, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.title,
            style: const TextStyle(
              color: RezaColors.textWhite,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            announcement.content,
            style: Theme.of(context).bodyMedium,
          ),
          if (announcement.authorId != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: RezaColors.textGray),
                const SizedBox(width: 4),
                Text(
                  'Posted by ${announcement.authorId!.substring(0, 8)}...',
                  style: const TextStyle(color: RezaColors.textGray, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showCreateAnnouncementSheet(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool isPinned = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Announcement', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'Title', prefixIcon: Icon(Icons.title)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Message', prefixIcon: Icon(Icons.message_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Pin to top', style: TextStyle(color: RezaColors.textWhite)),
                      const SizedBox(width: 8),
                      Switch(
                        value: isPinned,
                        onChanged: (v) => setModalState(() => isPinned = v),
                        activeThumbColor: RezaColors.accentGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_estateId != null && titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _announcementRepo.createAnnouncement(
                              estateId: _estateId!,
                              title: titleController.text,
                              content: bodyController.text,
                              isPinned: isPinned,
                            );
                            navigator.pop();
                            _loadAnnouncements();
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Announcement created')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Post Announcement'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
