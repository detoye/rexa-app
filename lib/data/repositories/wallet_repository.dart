import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class WalletRepository {
  final _client = SupabaseConfig.client;

  Future<String?> getCurrentMemberId() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('members')
        .select('id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    return data?['id'] as String?;
  }

  Future<Wallet?> getWallet() async {
    final memberId = await getCurrentMemberId();
    if (memberId == null) return null;

    final data = await _client
        .from('wallets')
        .select()
        .eq('member_id', memberId)
        .maybeSingle();

    if (data == null) {
      // Create wallet if it doesn't exist
      final newWallet = await _client
          .from('wallets')
          .insert({'member_id': memberId, 'balance': 0})
          .select()
          .single();
      return Wallet.fromJson(newWallet);
    }

    return Wallet.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions({int limit = 20}) async {
    final wallet = await getWallet();
    if (wallet == null) return [];

    final data = await _client
        .from('wallet_transactions')
        .select()
        .eq('wallet_id', wallet.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return data;
  }

  Future<double> getBalance() async {
    final wallet = await getWallet();
    return wallet?.balance ?? 0;
  }

  Future<Wallet> fundWallet(double amount, {String? reference}) async {
    final wallet = await getWallet();
    if (wallet == null) throw Exception('Wallet not found');

    // Record the funding transaction
    await _client.from('wallet_transactions').insert({
      'wallet_id': wallet.id,
      'amount': amount,
      'type': 'credit',
      'description': 'Wallet funding via Paystack',
    });

    // Update wallet balance
    final data = await _client
        .from('wallets')
        .update({
          'balance': wallet.balance + amount,
          'total_funded': wallet.totalFunded + amount,
        })
        .eq('id', wallet.id)
        .select()
        .single();

    return Wallet.fromJson(data);
  }

  Future<Wallet> debitWallet(double amount, String description) async {
    final wallet = await getWallet();
    if (wallet == null) throw Exception('Wallet not found');
    if (wallet.balance < amount) throw Exception('Insufficient balance');

    // Record the debit transaction
    await _client.from('wallet_transactions').insert({
      'wallet_id': wallet.id,
      'amount': amount,
      'type': 'debit',
      'description': description,
    });

    // Update wallet balance
    final data = await _client
        .from('wallets')
        .update({
          'balance': wallet.balance - amount,
          'total_spent': wallet.totalSpent + amount,
        })
        .eq('id', wallet.id)
        .select()
        .single();

    return Wallet.fromJson(data);
  }

  Future<List<Invoice>> getInvoices({bool unpaidOnly = false}) async {
    final memberId = await getCurrentMemberId();
    if (memberId == null) return [];

    var query = _client
        .from('invoices')
        .select()
        .eq('member_id', memberId);

    if (unpaidOnly) {
      query = query.eq('is_paid', false);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((i) => Invoice.fromJson(i)).toList();
  }

  Future<void> payInvoice(String invoiceId, double amount) async {
    final wallet = await getWallet();
    if (wallet == null) throw Exception('Wallet not found');
    if (wallet.balance < amount) throw Exception('Insufficient wallet balance');

    // Debit wallet
    await debitWallet(amount, 'Invoice payment');

    // Mark invoice as paid
    await _client.from('invoices').update({
      'is_paid': true,
      'paid_date': DateTime.now().toIso8601String(),
    }).eq('id', invoiceId);

    // Record payment
    final memberId = await getCurrentMemberId();
    final invoice = await _client.from('invoices').select().eq('id', invoiceId).single();

    await _client.from('payments').insert({
      'estate_id': invoice['estate_id'],
      'member_id': memberId,
      'invoice_id': invoiceId,
      'due_id': invoice['due_id'],
      'amount': amount,
      'net_amount': amount,
      'status': 'success',
      'payment_method': 'wallet',
    });
  }
}
