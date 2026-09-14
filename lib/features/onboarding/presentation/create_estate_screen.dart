import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/estate_repository.dart';

class CreateEstateScreen extends StatefulWidget {
  const CreateEstateScreen({super.key});

  @override
  State<CreateEstateScreen> createState() => _CreateEstateScreenState();
}

class _CreateEstateScreenState extends State<CreateEstateScreen> {
  final _estateRepo = EstateRepository();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createEstate() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter an estate name');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter an address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _estateRepo.createEstateWithAdmin(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        context.go('/subscription');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 480 : 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: RezaColors.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.apartment_outlined,
                        color: RezaColors.accentGold,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Create Your Estate',
                      style: TextStyle(
                        color: RezaColors.textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Set up your estate to get started',
                      style: TextStyle(color: RezaColors.textGray, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: RezaColors.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: RezaColors.errorRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: RezaColors.errorRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: RezaColors.errorRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Estate Name',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.description_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createEstate,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: RezaColors.primaryNavy,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Estate', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/role-selection'),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: RezaColors.textGray),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
