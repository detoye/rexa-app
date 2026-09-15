import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class PaystackService {
  // TODO: Set your Paystack secret key here or load from environment
  static const String _secretKey = 'sk_live-placeholder';
  static const String _baseUrl = 'https://api.paystack.co';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

  /// Initialize a Paystack transaction
  /// Returns a reference and access_code for the frontend
  static Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required double amount,
    String? reference,
  }) async {
    final ref = reference ?? _generateReference();
    final response = await http.post(
      Uri.parse('$_baseUrl/transaction/initialize'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'amount': (amount * 100).toInt(), // Paystack uses kobo
        'reference': ref,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return {
          'reference': ref,
          'access_code': data['data']['access_code'],
        };
      }
    }
    throw Exception('Failed to initialize Paystack transaction: ${response.body}');
  }

  /// Verify a Paystack transaction
  /// Returns true if the transaction was successful
  static Future<bool> verifyTransaction(String reference) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/transaction/verify/$reference'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return data['data']['status'] == 'success';
      }
    }
    return false;
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
