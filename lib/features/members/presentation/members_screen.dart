import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/role_helper.dart';
import '../../../data/repositories/member_repository.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _memberRepo = MemberRepository();
  final _searchController = TextEditingController();
  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = true;
  String? _estateId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      _isAdmin = await RoleHelper.isAdmin();
      _estateId = await _memberRepo.getCurrentEstateId();
      if (_estateId != null) {
        final members = await _memberRepo.getMembersByEstate(_estateId!);
        setState(() {
          _members = members;
          _filteredMembers = members;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load members: $e')),
        );
      }
    }
  }

  void _filterMembers(String query) {
    setState(() {
      _filteredMembers = _members.where((m) {
        final searchLower = query.toLowerCase();
        return m.role.toLowerCase().contains(searchLower) ||
            (m.fullName?.toLowerCase().contains(searchLower) ?? false) ||
            (m.houseNumber?.toLowerCase().contains(searchLower) ?? false) ||
            (m.street?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Members'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.mail_outline),
              onPressed: () => context.go('/manage-invitations'),
              tooltip: 'Invite Members',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: RezaColors.accentGold),
            )
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: RezaColors.textGray.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No members yet',
                        style: TextStyle(color: RezaColors.textGray, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Invite members to get started',
                        style: TextStyle(color: RezaColors.textGray.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 8),
                    Text(
                      '${_filteredMembers.length} members',
                      style: const TextStyle(color: RezaColors.textGray, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ..._filteredMembers.map((member) => _buildMemberTile(member)),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _filterMembers,
      decoration: InputDecoration(
        hintText: 'Search by name, role, house, street...',
        prefixIcon: const Icon(Icons.search, color: RezaColors.textGray),
        filled: true,
        fillColor: RezaColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMemberTile(Member member) {
    final addressParts = <String>[];
    if (member.houseNumber != null) addressParts.add('House ${member.houseNumber}');
    if (member.street != null) addressParts.add(member.street!);
    final address = addressParts.isNotEmpty ? addressParts.join(', ') : 'No address';
    final displayName = member.fullName?.isNotEmpty == true
        ? member.fullName!
        : member.role[0].toUpperCase() + member.role.substring(1);

    return GestureDetector(
      onTap: () => _showMemberDetail(member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RezaColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: RezaColors.accentGold.withValues(alpha: 0.2),
              child: Text(
                displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: RezaColors.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: RezaColors.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: RezaColors.successGreen,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${member.role.toUpperCase()} • $address',
                    style: Theme.of(context).bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: member.isVerified
                    ? RezaColors.successGreen.withValues(alpha: 0.2)
                    : RezaColors.textGray.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.isVerified ? 'Verified' : 'Pending',
                style: TextStyle(
                  fontSize: 11,
                  color: member.isVerified ? RezaColors.successGreen : RezaColors.textGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberDetail(Member member) {
    final addressParts = <String>[];
    if (member.houseNumber != null) addressParts.add('House ${member.houseNumber}');
    if (member.street != null) addressParts.add(member.street!);
    final address = addressParts.isNotEmpty ? addressParts.join(', ') : 'No address';
    final displayName = member.fullName?.isNotEmpty == true
        ? member.fullName!
        : member.role[0].toUpperCase() + member.role.substring(1);

    showModalBottomSheet(
      context: context,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: RezaColors.accentGold.withValues(alpha: 0.2),
              child: Text(
                displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: RezaColors.accentGold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: RezaColors.textWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (member.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: RezaColors.successGreen, size: 20),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              member.role[0].toUpperCase() + member.role.substring(1),
              style: const TextStyle(color: RezaColors.accentGold, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Divider(color: RezaColors.textGray, height: 1),
            const SizedBox(height: 16),
            _detailRow(Icons.home_outlined, 'Address', address),
            const SizedBox(height: 12),
            _detailRow(Icons.badge_outlined, 'Role', member.role[0].toUpperCase() + member.role.substring(1)),
            const SizedBox(height: 12),
            _detailRow(
              Icons.verified_outlined,
              'Status',
              member.isVerified ? 'Verified' : 'Pending verification',
            ),
            const SizedBox(height: 12),
            _detailRow(Icons.calendar_today, 'Joined', '${member.createdAt.day}/${member.createdAt.month}/${member.createdAt.year}'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: RezaColors.textGray, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: RezaColors.textGray.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: RezaColors.textWhite, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

}
