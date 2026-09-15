import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../config/supabase_client.dart';

class EstatesPage extends StatefulWidget {
  const EstatesPage({super.key});

  @override
  State<EstatesPage> createState() => _EstatesPageState();
}

class _EstatesPageState extends State<EstatesPage> {
  List<Map<String, dynamic>> _estates = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEstates();
  }

  Future<void> _loadEstates() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseConfig.client
          .from('estates')
          .select('id, name, address, created_at')
          .order('created_at', ascending: false);
      setState(() {
        _estates = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load estates: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredEstates {
    if (_searchQuery.isEmpty) return _estates;
    return _estates.where((e) =>
        (e['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (e['address'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadEstates,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estates',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage all registered estates on the platform',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                        Text('${_estates.length} estates', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: const InputDecoration(
                                hintText: 'Search estates...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Estate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                                Expanded(flex: 3, child: Text('Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                                Expanded(flex: 2, child: Text('Created', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))),
                              ],
                            ),
                          ),
                          if (_filteredEstates.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No estates found', style: TextStyle(color: Color(0xFF9CA3AF)))),
                            )
                          else
                            ..._filteredEstates.map((estate) {
                              final createdAt = estate['created_at'] != null
                                  ? DateTime.parse(estate['created_at']).toString().substring(0, 10)
                                  : 'N/A';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(estate['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1B2A4A))),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(estate['address'] ?? 'No address', style: const TextStyle(color: Color(0xFF6B7280))),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(createdAt, style: const TextStyle(color: Color(0xFF6B7280))),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
