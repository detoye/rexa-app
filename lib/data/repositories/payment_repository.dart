import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class PaymentRepository {
  final _client = SupabaseConfig.client;

  Future<double> getTotalCollected(String estateId) async {
    final data = await _client
        .from('payments')
        .select('amount')
        .eq('estate_id', estateId)
        .eq('status', 'success');

    return data.fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());
  }

  Future<double> getOutstanding(String estateId) async {
    final data = await _client
        .from('invoices')
        .select('amount')
        .eq('estate_id', estateId)
        .eq('is_paid', false);

    return data.fold<double>(0, (sum, i) => sum + (i['amount'] as num).toDouble());
  }

  Future<double> getMonthlyRevenue(String estateId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final data = await _client
        .from('payments')
        .select('amount')
        .eq('estate_id', estateId)
        .eq('status', 'success')
        .gte('created_at', startOfMonth.toIso8601String());

    return data.fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());
  }

  Future<List<Payment>> getPaymentsByMember(String memberId) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('member_id', memberId)
        .order('created_at', ascending: false);

    return data.map((p) => Payment.fromJson(p)).toList();
  }

  Future<List<Payment>> getPaymentsByEstate(String estateId) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('estate_id', estateId)
        .order('created_at', ascending: false)
        .limit(20);

    return data.map((p) => Payment.fromJson(p)).toList();
  }

  Future<Payment> createPayment({
    required String estateId,
    required String memberId,
    required String dueId,
    required double amount,
    required String method,
    String? reference,
  }) async {
    final platformFee = amount * 0.015;
    final netAmount = amount - platformFee;

    final data = await _client
        .from('payments')
        .insert({
          'estate_id': estateId,
          'member_id': memberId,
          'due_id': dueId,
          'amount': amount,
          'platform_fee': platformFee,
          'net_amount': netAmount,
          'status': 'success',
          'payment_method': method,
          'reference': reference,
        })
        .select()
        .single();

    return Payment.fromJson(data);
  }

  Stream<List<Payment>> watchPayments(String estateId) {
    return _client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('estate_id', estateId)
        .order('created_at', ascending: false)
        .map((data) => data.map((p) => Payment.fromJson(p)).toList());
  }

  Future<List<Map<String, dynamic>>> getDueSummary(String estateId) async {
    final data = await _client
        .from('dues')
        .select('title, amount, is_active')
        .eq('estate_id', estateId);
    return data;
  }

  Future<List<Map<String, dynamic>>> getRecentPayments(String estateId, {int limit = 10}) async {
    final data = await _client
        .from('payments')
        .select('id, amount, status, payment_method, created_at, member_id')
        .eq('estate_id', estateId)
        .order('created_at', ascending: false)
        .limit(limit);
    return data;
  }

  Future<Map<String, dynamic>> getCollectionStats(String estateId) async {
    final totalCollected = await getTotalCollected(estateId);
    final outstanding = await getOutstanding(estateId);
    final monthlyRevenue = await getMonthlyRevenue(estateId);
    return {
      'totalCollected': totalCollected,
      'outstanding': outstanding,
      'monthlyRevenue': monthlyRevenue,
    };
  }
}
