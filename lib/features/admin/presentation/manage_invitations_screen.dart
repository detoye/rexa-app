import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import '../../../core/utils/role_helper.dart';
import '../../../data/repositories/invitation_repository.dart';

class ManageInvitationsScreen extends StatefulWidget {
  const ManageInvitationsScreen({super.key});

  @override
  State<ManageInvitationsScreen> createState() => _ManageInvitationsScreenState();
}

class _ManageInvitationsScreenState extends State<ManageInvitationsScreen> {
  final _invitationRepo = InvitationRepository();
  List<Map<String, dynamic>> _codes = [];
  bool _isLoading = true;
  String? _estateId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _isLoading = true);
    try {
      _isAdmin = await RoleHelper.isAdmin();
      if (!_isAdmin) {
        setState(() => _isLoading = false);
        return;
      }

      final user = SupabaseConfig.auth.currentUser;
      if (user == null) return;

      final member = await SupabaseConfig.client
          .from('members')
          .select('estate_id')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      if (member != null) {
        _estateId = member['estate_id'];
        final codes = await _invitationRepo.getActiveCodes(_estateId!);
        setState(() {
          _codes = codes;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCode() async {
    if (_estateId == null) return;

    String selectedRole = 'tenant';
    int expiryDays = 30;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: RezaColors.cardDark,
              title: const Text('Generate Invitation Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(hintText: 'Role for invitee'),
                    items: const [
                      DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                      DropdownMenuItem(value: 'landlord', child: Text('Landlord')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedRole = v ?? 'tenant'),
                  ),
                  if (selectedRole == 'admin') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RezaColors.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: RezaColors.errorRed, size: 16),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Admin codes grant full platform access',
                              style: TextStyle(color: RezaColors.errorRed, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: expiryDays,
                    decoration: const InputDecoration(hintText: 'Expires in'),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                      DropdownMenuItem(value: 90, child: Text('90 days')),
                    ],
                    onChanged: (v) => setDialogState(() => expiryDays = v ?? 30),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {'role': selectedRole, 'expiry': expiryDays}),
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      try {
        final code = await _invitationRepo.generateCode(
          estateId: _estateId!,
          role: result['role'],
          expiryDays: result['expiry'],
        );
        _loadCodes();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: RezaColors.cardDark,
              title: const Text('Code Generated'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: RezaColors.accentGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share this code with the person you want to invite',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RezaColors.textGray),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Copy Code'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin && !_isLoading) {
      return Scaffold(
        backgroundColor: RezaColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: RezaColors.backgroundDark,
          title: const Text('Invitation Codes'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: RezaColors.textGray.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text('Access Denied', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Only admins can manage invitation codes', style: TextStyle(color: RezaColors.textGray)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Invitation Codes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _generateCode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : _codes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key_outlined, size: 64, color: RezaColors.textGray.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No active codes', style: TextStyle(color: RezaColors.textGray, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Generate a code to invite members', style: TextStyle(color: RezaColors.textGray.withValues(alpha: 0.6), fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _codes.length,
                  itemBuilder: (context, index) {
                    final code = _codes[index];
                    return _buildCodeTile(code);
                  },
                ),
    );
  }

  Widget _buildCodeTile(Map<String, dynamic> code) {
    final expiresAt = code['expires_at'] != null ? DateTime.parse(code['expires_at']) : null;
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RezaColors.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              code['code'],
              style: const TextStyle(
                color: RezaColors.accentGold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role: ${code['role']}'.toUpperCase(),
                  style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  isExpired ? 'Expired' : 'Expires: ${expiresAt?.day}/${expiresAt?.month}/${expiresAt?.year}',
                  style: TextStyle(
                    color: isExpired ? RezaColors.errorRed : RezaColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: RezaColors.textGray, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code['code']));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: RezaColors.errorRed, size: 20),
            onPressed: () async {
              await _invitationRepo.revokeCode(code['id']);
              _loadCodes();
            },
          ),
        ],
      ),
    );
  }
}
