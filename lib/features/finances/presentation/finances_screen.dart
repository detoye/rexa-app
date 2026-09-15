import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import '../../../core/utils/role_helper.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/member_repository.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  final _paymentRepo = PaymentRepository();
  final _memberRepo = MemberRepository();

  double _totalCollected = 0;
  double _outstanding = 0;
  double _monthlyRevenue = 0;
  List<Map<String, dynamic>> _dues = [];
  List<Map<String, dynamic>> _recentPayments = [];
  List<Map<String, dynamic>> _myPayments = [];
  double _myOutstanding = 0;
  bool _isLoading = true;
  String? _estateId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadFinances();
  }

  Future<void> _loadFinances() async {
    setState(() => _isLoading = true);
    try {
      _isAdmin = await RoleHelper.canManageFinances();
      _estateId = await _memberRepo.getCurrentEstateId();
      if (_estateId != null) {
        final stats = await _paymentRepo.getCollectionStats(_estateId!);
        final dues = await _paymentRepo.getDueSummary(_estateId!);
        final payments = await _paymentRepo.getRecentPayments(_estateId!);
        setState(() {
          _totalCollected = stats['totalCollected'];
          _outstanding = stats['outstanding'];
          _monthlyRevenue = stats['monthlyRevenue'];
          _dues = dues;
          _recentPayments = payments;
          _isLoading = false;
        });

        // Load tenant-specific data
        if (!_isAdmin) {
          final user = SupabaseConfig.auth.currentUser;
          if (user != null && _estateId != null) {
            final memberData = await SupabaseConfig.client
                .from('members')
                .select('id')
                .eq('user_id', user.id)
                .eq('estate_id', _estateId!)
                .limit(1)
                .maybeSingle();
            
            if (memberData != null) {
              final payments = await SupabaseConfig.client
                  .from('payments')
                  .select('id, amount, status, payment_method, created_at, due_id, dues(name)')
                  .eq('member_id', memberData['id'])
                  .order('created_at', ascending: false)
                  .limit(20);
              
              final unpaidInvoices = await SupabaseConfig.client
                  .from('invoices')
                  .select('id, amount, due_id, dues(name), due_date')
                  .eq('member_id', memberData['id'])
                  .eq('is_paid', false);
              
              setState(() {
                _myPayments = payments;
                _myOutstanding = unpaidInvoices.fold<double>(0, (sum, i) => sum + (i['amount'] as num).toDouble());
              });
            }
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load finances: $e')),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '₦${(amount / 1000).toStringAsFixed(1)}K';
    return '₦${amount.toStringAsFixed(0)}';
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Finances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _isAdmin
                ? () => _showAddDueDialog(context)
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin access required')),
                    ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadFinances,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards - admin sees estate-wide, tenant sees personal
                    if (_isAdmin) ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Collected',
                              value: _formatAmount(_totalCollected),
                              icon: Icons.trending_up,
                              iconColor: RezaColors.successGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Outstanding',
                              value: _formatAmount(_outstanding),
                              icon: Icons.trending_down,
                              iconColor: RezaColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'This Month',
                              value: _formatAmount(_monthlyRevenue),
                              icon: Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Due Types',
                              value: '${_dues.length}',
                              icon: Icons.receipt_long,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Tenant: personal balance card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [RezaColors.primaryNavy, Color(0xFF2A3A5A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('My Outstanding', style: TextStyle(color: RezaColors.textGray)),
                                if (_myOutstanding > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: RezaColors.errorRed.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('₦${_formatAmount(_myOutstanding)}', style: const TextStyle(color: RezaColors.errorRed, fontSize: 12)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _myOutstanding > 0 ? '₦${_formatAmount(_myOutstanding)}' : 'All clear!',
                              style: Theme.of(context).headlineMedium?.copyWith(
                                color: _myOutstanding > 0 ? RezaColors.errorRed : RezaColors.successGreen,
                              ),
                            ),
                            if (_myOutstanding > 0) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.go('/wallet'),
                                  icon: const Icon(Icons.payment, size: 18),
                                  label: const Text('Pay Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: RezaColors.accentGold,
                                    foregroundColor: RezaColors.primaryNavy,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isAdmin ? 'Due Types' : 'My Dues', style: Theme.of(context).headlineMedium),
                        if (_isAdmin)
                          TextButton(
                            onPressed: () => _showAddDueDialog(context),
                            child: const Text('+ Add Due'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_dues.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: RezaColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('No dues configured yet', style: TextStyle(color: RezaColors.textGray)),
                        ),
                      )
                    else
                      ..._dues.map((due) => _buildDueItem(
                            due['name'] ?? 'Unnamed',
                            _formatAmount((due['amount'] as num).toDouble()),
                            due['is_active'] == true,
                          )),
                    const SizedBox(height: 24),
                    Text(_isAdmin ? 'Recent Payments' : 'My Payment History', style: Theme.of(context).headlineMedium),
                    const SizedBox(height: 12),
                    if (_isAdmin ? _recentPayments.isEmpty : _myPayments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: RezaColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('No payments yet', style: TextStyle(color: RezaColors.textGray)),
                        ),
                      )
                    else if (_isAdmin)
                      ..._recentPayments.map((payment) => _buildPaymentItem(
                            payment['member_id']?.substring(0, 8) ?? 'User',
                            _formatAmount((payment['amount'] as num).toDouble()),
                            payment['status'] == 'success',
                            _formatDate(payment['created_at']),
                          ))
                    else
                      ..._myPayments.map((payment) {
                        final dueName = (payment['dues'] as Map<String, dynamic>?)?['name'] ?? 'Due';
                        return _buildPaymentItem(
                          dueName,
                          _formatAmount((payment['amount'] as num).toDouble()),
                          payment['status'] == 'success',
                          _formatDate(payment['created_at']),
                        );
                      }),
                    // Tenant: Pay outstanding button
                    if (!_isAdmin && _myOutstanding > 0) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/wallet'),
                          icon: const Icon(Icons.payment, size: 18),
                          label: Text('Pay Outstanding — ₦${_formatAmount(_myOutstanding)}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RezaColors.accentGold,
                            foregroundColor: RezaColors.primaryNavy,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDueItem(String name, String amount, bool isActive) {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RezaColors.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: RezaColors.accentGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? RezaColors.successGreen.withValues(alpha: 0.2)
                      : RezaColors.textGray.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(color: isActive ? RezaColors.successGreen : RezaColors.textGray, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(String memberName, String amount, bool isPaid, String timeAgo) {
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
            radius: 20,
            backgroundColor: RezaColors.accentGold.withValues(alpha: 0.2),
            child: Text(
              memberName[0].toUpperCase(),
              style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memberName, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
                Text(timeAgo, style: Theme.of(context).bodyMedium),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid
                      ? RezaColors.successGreen.withValues(alpha: 0.2)
                      : RezaColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    color: isPaid ? RezaColors.successGreen : RezaColors.accentGold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDueDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create New Due', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Due Name', prefixIcon: Icon(Icons.receipt_long))),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount (₦)', prefixIcon: Icon(Icons.money)),
              ),
              const SizedBox(height: 16),
              TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Icon(Icons.description))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_estateId == null) return;
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                    if (name.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name and valid amount')),
                      );
                      return;
                    }
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _paymentRepo.createDue(
                        estateId: _estateId!,
                        name: name,
                        amount: amount,
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                      );
                      navigator.pop();
                      _loadFinances();
                      messenger.showSnackBar(const SnackBar(content: Text('Due created')));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  child: const Text('Create Due'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
