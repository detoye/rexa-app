import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/invitation_repository.dart';

class JoinEstateScreen extends StatefulWidget {
  const JoinEstateScreen({super.key});

  @override
  State<JoinEstateScreen> createState() => _JoinEstateScreenState();
}

class _JoinEstateScreenState extends State<JoinEstateScreen> {
  final _invitationRepo = InvitationRepository();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isPreviewing = false;

  String? _previewedRole;
  String? _previewedEstateName;
  String? _previewError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _previewCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-character code')),
      );
      return;
    }

    setState(() {
      _isPreviewing = true;
      _previewError = null;
      _previewedRole = null;
    });

    try {
      final result = await _invitationRepo.previewCode(code);
      if (mounted) {
        setState(() {
          _previewedRole = result['role'];
          _previewedEstateName = result['estate_name'];
          _isPreviewing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewError = e.toString().replaceFirst('Exception: ', '');
          _isPreviewing = false;
        });
      }
    }
  }

  Future<void> _joinEstate() async {
    final code = _codeController.text.trim().toUpperCase();

    setState(() => _isLoading = true);
    try {
      await _invitationRepo.joinWithCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined estate!')),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPreview() {
    setState(() {
      _previewedRole = null;
      _previewedEstateName = null;
      _previewError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveLayout.isDesktop(context);
    final isAdminInvite = _previewedRole == 'admin';

    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Join Estate'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 480 : 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: RezaColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.vpn_key_outlined,
                      color: RezaColors.accentGold,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Enter Invitation Code',
                    style: TextStyle(
                      color: RezaColors.textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Get the 6-character code from your estate admin',
                    style: TextStyle(color: RezaColors.textGray, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Code input
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  enabled: _previewedRole == null,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: RezaColors.textWhite,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: TextStyle(
                      color: RezaColors.textGray.withValues(alpha: 0.4),
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: RezaColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: RezaColors.accentGold, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Preview error
                if (_previewError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RezaColors.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RezaColors.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: RezaColors.errorRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_previewError!, style: const TextStyle(color: RezaColors.errorRed)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Preview result — role confirmation
                if (_previewedRole != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isAdminInvite
                          ? RezaColors.errorRed.withValues(alpha: 0.1)
                          : RezaColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAdminInvite
                            ? RezaColors.errorRed.withValues(alpha: 0.3)
                            : RezaColors.successGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isAdminInvite ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                          color: isAdminInvite ? RezaColors.errorRed : RezaColors.successGreen,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAdminInvite ? 'Admin Invitation' : 'Member Invitation',
                          style: TextStyle(
                            color: isAdminInvite ? RezaColors.errorRed : RezaColors.successGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estate: $_previewedEstateName',
                          style: const TextStyle(color: RezaColors.textWhite, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Role: ${_previewedRole!.toUpperCase()}',
                          style: const TextStyle(color: RezaColors.textGray, fontSize: 13),
                        ),
                        if (isAdminInvite) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RezaColors.errorRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber, color: RezaColors.errorRed, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'This code grants full platform admin access. Only use if you were invited by an existing admin.',
                                    style: TextStyle(color: RezaColors.errorRed, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Buttons
                if (_previewedRole == null)
                  // Step 1: Look up code
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isPreviewing ? null : _previewCode,
                      child: _isPreviewing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: RezaColors.primaryNavy, strokeWidth: 2),
                            )
                          : const Text('Look Up Code', style: TextStyle(fontSize: 16)),
                    ),
                  )
                else ...[
                  // Step 2: Confirm join
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _joinEstate,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: RezaColors.primaryNavy, strokeWidth: 2),
                            )
                          : Text(
                              isAdminInvite ? 'Accept Admin Invite' : 'Join Estate',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _resetPreview,
                      child: const Text('Use Different Code', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: RezaColors.textGray),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
