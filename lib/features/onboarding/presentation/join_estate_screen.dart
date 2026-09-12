import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinEstate() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-character code')),
      );
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Join Estate'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _joinEstate,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: RezaColors.primaryNavy,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Join Estate', style: TextStyle(fontSize: 16)),
              ),
            ),
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
    );
  }
}
