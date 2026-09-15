import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../core/services/paystack_service.dart';
import '../../../data/repositories/wallet_repository.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _walletRepo = WalletRepository();
  Wallet? _wallet;
  List<Invoice> _unpaidInvoices = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _walletRepo.getWallet(),
        _walletRepo.getInvoices(unpaidOnly: true),
        _walletRepo.getWalletTransactions(),
      ]);
      setState(() {
        _wallet = results[0] as Wallet?;
        _unpaidInvoices = results[1] as List<Invoice>;
        _transactions = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wallet: $e')),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    return '₦${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Wallet'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildActionButton(Icons.add, 'Fund Wallet', RezaColors.successGreen, () => _showFundSheet(context))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton(Icons.send, 'Pay Invoice', RezaColors.accentGold, () => _showPayInvoiceSheet(context))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_unpaidInvoices.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Outstanding Invoices', style: Theme.of(context).headlineMedium),
                          Text('${_unpaidInvoices.length}', style: const TextStyle(color: RezaColors.errorRed, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._unpaidInvoices.map((inv) => _buildInvoiceCard(inv)),
                      const SizedBox(height: 24),
                    ],
                    Text('Recent Transactions', style: Theme.of(context).headlineMedium),
                    const SizedBox(height: 12),
                    if (_transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: RezaColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('No transactions yet', style: TextStyle(color: RezaColors.textGray)),
                        ),
                      )
                    else
                      ..._transactions.map((tx) => _buildTransactionTile(tx)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _wallet?.balance ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [RezaColors.primaryNavy, Color(0xFF2A3A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet Balance', style: TextStyle(color: RezaColors.textGray)),
          const SizedBox(height: 8),
          Text(
            _formatAmount(balance),
            style: const TextStyle(color: RezaColors.accentGold, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat('Funded', _formatAmount(_wallet?.totalFunded ?? 0)),
              const SizedBox(width: 24),
              _buildMiniStat('Spent', _formatAmount(_wallet?.totalSpent ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RezaColors.textGray, fontSize: 12)),
        Text(value, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final dueDateStr = invoice.dueDate != null ? _formatDate(invoice.dueDate!.toIso8601String()) : 'No due date';
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RezaColors.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: RezaColors.errorRed, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.type.toUpperCase(), style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
                Text('Due: $dueDateStr', style: Theme.of(context).bodyMedium),
              ],
            ),
          ),
          Text(_formatAmount(invoice.amount), style: const TextStyle(color: RezaColors.errorRed, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final isCredit = tx['type'] == 'credit';
    final amount = (tx['amount'] as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              color: (isCredit ? RezaColors.successGreen : RezaColors.errorRed).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? RezaColors.successGreen : RezaColors.errorRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] ?? 'Transaction', style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w500)),
                Text(_formatDate(tx['created_at']), style: const TextStyle(color: RezaColors.textGray, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${_formatAmount(amount)}',
            style: TextStyle(
              color: isCredit ? RezaColors.successGreen : RezaColors.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showFundSheet(BuildContext context) {
    final amountController = TextEditingController();
    final emailController = TextEditingController();

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
              const Text('Fund Wallet', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Fee: ${PaystackService.calculateFee(1000).toStringAsFixed(0)}% per transaction',
                style: TextStyle(color: RezaColors.textGray, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount (₦)', prefixIcon: Icon(Icons.money)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email for receipt', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isNotEmpty && emailController.text.isNotEmpty) {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) return;

                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      // Initialize Paystack transaction
                      final txResult = await PaystackService.initializeTransaction(
                        email: emailController.text,
                        amount: amount,
                      );
                      final reference = txResult['reference'] as String;

                      // In production: open Paystack checkout WebView
                      // For now, simulate successful payment
                      try {
                        await PaystackService.verifyTransaction(reference);
                        await _walletRepo.fundWallet(amount, reference: reference);
                        navigator.pop();
                        _loadWalletData();
                        messenger.showSnackBar(
                          SnackBar(content: Text('${_formatAmount(amount)} added to wallet')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Payment failed: $e')));
                      }
                    }
                  },
                  child: const Text('Fund via Paystack'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPayInvoiceSheet(BuildContext context) {
    if (_unpaidInvoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No outstanding invoices')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pay Invoice', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Wallet balance: ${_formatAmount(_wallet?.balance ?? 0)}', style: TextStyle(color: RezaColors.textGray, fontSize: 13)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: _unpaidInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _unpaidInvoices[index];
                        final canPay = (_wallet?.balance ?? 0) >= invoice.amount;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: RezaColors.backgroundDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(invoice.type.toUpperCase(), style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
                                    Text(_formatAmount(invoice.amount), style: const TextStyle(color: RezaColors.accentGold)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: canPay
                                    ? () async {
                                        final navigator = Navigator.of(context);
                                        final messenger = ScaffoldMessenger.of(context);
                                        try {
                                          await _walletRepo.payInvoice(invoice.id, invoice.amount);
                                          navigator.pop();
                                          _loadWalletData();
                                          messenger.showSnackBar(const SnackBar(content: Text('Invoice paid')));
                                        } catch (e) {
                                          messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                                        }
                                      }
                                    : null,
                                child: const Text('Pay'),
                              ),
                            ],
                          ),
                        );
                      },
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
