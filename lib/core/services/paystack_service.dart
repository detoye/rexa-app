import 'dart:math';

class PaystackService {
  /// Initialize a Paystack transaction
  /// Returns a reference that should be used to verify the transaction
  static String initializeTransaction({
    required String email,
    required double amount,
    String? reference,
  }) {
    final ref = reference ?? _generateReference();
    // In production, this would call Paystack's API:
    // POST https://api.paystack.co/transaction/initialize
    // {
    //   "email": email,
    //   "amount": amount * 100, // Paystack uses kobo
    //   "reference": ref,
    //   "callback_url": "your-callback-url"
    // }
    return ref;
  }

  /// Verify a Paystack transaction
  /// Returns true if the transaction was successful
  static Future<bool> verifyTransaction(String reference) async {
    // In production, this would call:
    // GET https://api.paystack.co/transaction/verify/{reference}
    // and check if status == 'success'
    return true;
  }

  /// Calculate platform fee (1.5%)
  static double calculateFee(double amount) {
    return amount * 0.015;
  }

  /// Calculate net amount after fee deduction
  static double calculateNet(double amount) {
    return amount - calculateFee(amount);
  }

  static String _generateReference() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'REXA_$timestamp${random.nextInt(10000).toString().padLeft(4, '0')}';
  }
}
