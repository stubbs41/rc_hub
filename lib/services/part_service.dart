import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/part.dart';

class PartService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Get all parts for the current user
  Future<List<PartModel>> getParts() async {
    final response = await _client
        .from('parts')
        .select('*, part_media(url, is_primary)')
        .order('created_at', ascending: false);
    
    List<PartModel> parts = [];
    
    for (final part in response) {
      String? primaryImageUrl;
      
      // Find primary image if available
      if (part['part_media'] != null && part['part_media'].isNotEmpty) {
        for (final media in part['part_media']) {
          if (media['is_primary'] == true) {
            primaryImageUrl = media['url'];
            break;
          }
        }
        
        // If no primary image is set, use the first one
        if (primaryImageUrl == null && part['part_media'].isNotEmpty) {
          primaryImageUrl = part['part_media'][0]['url'];
        }
      }
      
      // Add primary image URL to part data
      final partData = {...part};
      partData['primary_image_url'] = primaryImageUrl;
      
      parts.add(PartModel.fromJson(partData));
    }
    
    return parts;
  }
  
  // Get a single part by ID
  Future<PartModel> getPart(String id) async {
    final response = await _client
        .from('parts')
        .select('*, part_media(url, is_primary)')
        .eq('id', id)
        .single();
    
    String? primaryImageUrl;
    
    // Find primary image if available
    if (response['part_media'] != null && response['part_media'].isNotEmpty) {
      for (final media in response['part_media']) {
        if (media['is_primary'] == true) {
          primaryImageUrl = media['url'];
          break;
        }
      }
      
      // If no primary image is set, use the first one
      if (primaryImageUrl == null && response['part_media'].isNotEmpty) {
        primaryImageUrl = response['part_media'][0]['url'];
      }
    }
    
    // Add primary image URL to part data
    final partData = {...response};
    partData['primary_image_url'] = primaryImageUrl;
    
    return PartModel.fromJson(partData);
  }
  
  // Create a new part
  Future<PartModel> createPart(Map<String, dynamic> partData) async {
    // Ensure user_id is set to current user
    partData['user_id'] = _client.auth.currentUser!.id;
    
    final response = await _client
        .from('parts')
        .insert(partData)
        .select()
        .single();
    
    return PartModel.fromJson(response);
  }
  
  // Update an existing part
  Future<PartModel> updatePart(String id, Map<String, dynamic> partData) async {
    // Set updated_at to current time
    partData['updated_at'] = DateTime.now().toIso8601String();
    
    final response = await _client
        .from('parts')
        .update(partData)
        .eq('id', id)
        .select()
        .single();
    
    return PartModel.fromJson(response);
  }
  
  // Delete a part
  Future<void> deletePart(String id) async {
    await _client
        .from('parts')
        .delete()
        .eq('id', id);
  }
  
  // Upload part image
  Future<String> uploadPartImage(String partId, List<int> fileBytes, String fileName) async {
    final String path = 'parts/$partId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    await _client
        .storage
        .from('part-images')
        .uploadBinary(path, fileBytes);
    
    final String imageUrl = _client
        .storage
        .from('part-images')
        .getPublicUrl(path);
    
    // Create media record in database
    await _client
        .from('part_media')
        .insert({
          'part_id': partId,
          'media_type': 'image',
          'url': imageUrl,
          'is_primary': true, // Set as primary by default
        });
    
    return imageUrl;
  }
  
  // Get parts for a specific vehicle
  Future<List<PartModel>> getPartsForVehicle(String vehicleId) async {
    final response = await _client
        .from('vehicle_parts')
        .select('part_id, installation_date, notes, status, parts(*, part_media(url, is_primary))')
        .eq('vehicle_id', vehicleId);
    
    List<PartModel> parts = [];
    
    for (final item in response) {
      if (item['parts'] != null) {
        final part = item['parts'];
        String? primaryImageUrl;
        
        // Find primary image if available
        if (part['part_media'] != null && part['part_media'].isNotEmpty) {
          for (final media in part['part_media']) {
            if (media['is_primary'] == true) {
              primaryImageUrl = media['url'];
              break;
            }
          }
          
          // If no primary image is set, use the first one
          if (primaryImageUrl == null && part['part_media'].isNotEmpty) {
            primaryImageUrl = part['part_media'][0]['url'];
          }
        }
        
        // Add primary image URL to part data
        final partData = {...part};
        partData['primary_image_url'] = primaryImageUrl;
        
        parts.add(PartModel.fromJson(partData));
      }
    }
    
    return parts;
  }
  
  // Add part to vehicle
  Future<void> addPartToVehicle(String vehicleId, String partId, {DateTime? installationDate, String? notes}) async {
    await _client
        .from('vehicle_parts')
        .insert({
          'vehicle_id': vehicleId,
          'part_id': partId,
          'installation_date': installationDate?.toIso8601String(),
          'notes': notes,
          'status': 'installed',
        });
  }
  
  // Remove part from vehicle
  Future<void> removePartFromVehicle(String vehicleId, String partId) async {
    await _client
        .from('vehicle_parts')
        .delete()
        .eq('vehicle_id', vehicleId)
        .eq('part_id', partId);
  }
  
  // Get part categories (for dropdown selection)
  List<String> getPartCategories() {
    return [
      'Engine',
      'Transmission',
      'Suspension',
      'Electronics',
      'Body',
      'Wheels/Tires',
      'Battery',
      'Accessories',
      'Tools',
      'Other'
    ];
  }
  
  // Get part status options (for dropdown selection)
  List<String> getPartStatusOptions() {
    return [
      'in_stock',
      'low_stock',
      'out_of_stock',
      'on_order',
      'discontinued'
    ];
  }
}
