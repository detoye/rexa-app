import 'package:flutter/material.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../data/repositories/ad_repository.dart';

class BusinessAdsScreen extends StatefulWidget {
  const BusinessAdsScreen({super.key});

  @override
  State<BusinessAdsScreen> createState() => _BusinessAdsScreenState();
}

class _BusinessAdsScreenState extends State<BusinessAdsScreen> {
  final _adRepo = AdRepository();
  List<MemberAd> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    try {
      final estateId = await _adRepo.getCurrentEstateId();
      if (estateId != null) {
        final ads = await _adRepo.getActiveAds(estateId);
        setState(() {
          _ads = ads;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ads: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Business Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            onPressed: () => _showCreateAdSheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadAds,
              child: _ads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_outlined, size: 64, color: RezaColors.textGray.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No businesses yet', style: TextStyle(color: RezaColors.textGray, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Post your business to the community', style: TextStyle(color: RezaColors.textGray.withValues(alpha: 0.6), fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ads.length,
                      itemBuilder: (context, index) => _buildAdCard(_ads[index]),
                    ),
            ),
    );
  }

  Widget _buildAdCard(MemberAd ad) {
    final isOwner = ad.memberId == SupabaseConfig.auth.currentUser?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: RezaColors.borderDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.store, color: RezaColors.textGray, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(ad.title, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    if (isOwner)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: RezaColors.textGray, size: 20),
                        onSelected: (value) async {
                          if (value == 'deactivate') {
                            await _adRepo.deactivateAd(ad.id);
                            _loadAds();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'deactivate', child: Text('Remove')),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ad.description, style: Theme.of(context).bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: RezaColors.textGray),
                    const SizedBox(width: 4),
                    Text(ad.memberId.substring(0, 8), style: const TextStyle(color: RezaColors.textGray, fontSize: 12)),
                    const Spacer(),
                    Text(_formatTime(ad.createdAt), style: const TextStyle(color: RezaColors.textGray, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateAdSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Post Your Business', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Reach residents in your estate', style: TextStyle(color: RezaColors.textGray, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Business Name', prefixIcon: Icon(Icons.store_outlined))),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Describe your business, services, contact info...', prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _adRepo.createAd(
                          title: titleController.text,
                          description: descController.text,
                        );
                        navigator.pop();
                        _loadAds();
                        messenger.showSnackBar(const SnackBar(content: Text('Business posted')));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  child: const Text('Post Business'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
