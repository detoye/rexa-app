import 'package:flutter/material.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
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
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddMemberDialog(context),
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
        hintText: 'Search by role, house, street...',
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

    return Container(
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
              member.role[0].toUpperCase(),
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
                    Text(
                      member.role[0].toUpperCase() + member.role.substring(1),
                      style: const TextStyle(
                        color: RezaColors.textWhite,
                        fontWeight: FontWeight.w600,
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
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final houseController = TextEditingController();
    String selectedRole = 'tenant';

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
                  Text(
                    'Add New Member',
                    style: Theme.of(context).headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      hintText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                      DropdownMenuItem(value: 'landlord', child: Text('Landlord')),
                      DropdownMenuItem(value: 'security', child: Text('Security')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setModalState(() => selectedRole = value ?? 'tenant');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: houseController,
                    decoration: const InputDecoration(
                      hintText: 'House Number',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_estateId != null && nameController.text.isNotEmpty) {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _memberRepo.addMember(
                              estateId: _estateId!,
                              userId: SupabaseConfig.auth.currentUser!.id,
                              role: selectedRole,
                              houseNumber: houseController.text.isNotEmpty ? houseController.text : null,
                            );
                            navigator.pop();
                            _loadMembers();
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Member added successfully')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to add member: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Add Member'),
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
