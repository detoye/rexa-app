import '../../config/supabase_client.dart';

class RoleHelper {
  static Future<String?> getCurrentUserRole() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return null;

    final data = await SupabaseConfig.client
        .from('members')
        .select('role')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    return data?['role'] as String?;
  }

  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'super_admin';
  }

  static Future<bool> isSuperAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'super_admin';
  }

  static Future<bool> canManageMembers() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'super_admin';
  }

  static Future<bool> canManageFinances() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'super_admin';
  }

  static Future<bool> canManageGovernance() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'super_admin';
  }

  static Future<bool> canSendAlerts() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'super_admin' || role == 'security';
  }

  static Future<bool> canManageSecurity() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'super_admin' || role == 'security';
  }
}
