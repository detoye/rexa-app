class AppConstants {
  static const String appName = 'ResidentZ';
  static const String appTagline = 'Nigeria\'s Premier Estate Standard';
  
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static const List<String> estateTypes = [
    'Residential Estate',
    'Commercial Estate',
    'Mixed Use Estate',
    'CDA (Community Development Association)',
  ];
  
  static const List<String> memberRoles = [
    'Landlord',
    'Tenant',
    'Estate Manager',
    'Security',
  ];
  
  static const List<String> dueTypes = [
    'Monthly Dues',
    'Annual Dues',
    'Special Levy',
    'Service Charge',
    'Security Levy',
    'Development Levy',
  ];
  
  static const List<String> propertyTypes = [
    'Apartment',
    'Detached Duplex',
    'Semi-Detached Duplex',
    'Terrace',
    'Penthouse',
    'Bungalow',
    'Land',
  ];
  
  static const List<String> dealTypes = [
    'Rent',
    'Sale',
    'Lease',
  ];
}
