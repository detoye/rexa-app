import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class PropertyRepository {
  final _client = SupabaseConfig.client;

  Future<String?> getCurrentEstateId() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('members')
        .select('estate_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    return data?['estate_id'] as String?;
  }

  Future<List<Property>> getProperties(String estateId) async {
    final data = await _client
        .from('properties')
        .select()
        .eq('estate_id', estateId)
        .eq('is_available', true)
        .order('created_at', ascending: false);

    return data.map((p) => Property.fromJson(p)).toList();
  }

  Future<List<PropertyDeal>> getPropertyDeals(String estateId) async {
    final data = await _client
        .from('property_deals')
        .select()
        .eq('estate_id', estateId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return data.map((d) => PropertyDeal.fromJson(d)).toList();
  }

  Future<Property> createProperty({
    required String estateId,
    required String title,
    required String description,
    required String type,
    required double price,
    String? priceUnit,
    int? bedrooms,
    int? bathrooms,
  }) async {
    final data = await _client
        .from('properties')
        .insert({
          'estate_id': estateId,
          'owner_id': SupabaseConfig.auth.currentUser!.id,
          'title': title,
          'description': description,
          'type': type,
          'price': price,
          'price_unit': priceUnit,
          'bedrooms': bedrooms,
          'bathrooms': bathrooms,
          'is_available': true,
        })
        .select()
        .single();

    return Property.fromJson(data);
  }

  Future<PropertyDeal> createDeal({
    required String estateId,
    required String title,
    required String description,
    required String dealType,
    required double price,
    String? propertyType,
  }) async {
    final data = await _client
        .from('property_deals')
        .insert({
          'estate_id': estateId,
          'seller_id': SupabaseConfig.auth.currentUser!.id,
          'title': title,
          'description': description,
          'deal_type': dealType,
          'price': price,
          'property_type': propertyType,
          'is_active': true,
        })
        .select()
        .single();

    return PropertyDeal.fromJson(data);
  }
}
