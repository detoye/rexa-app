import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/supabase_client.dart';
import 'reza_app.dart';
import 'features/admin/presentation/platform_admin_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  if (kIsWeb) {
    runApp(
      const PlatformAdminApp(),
    );
  } else {
    runApp(
      const ProviderScope(
        child: RezaApp(),
      ),
    );
  }
}
