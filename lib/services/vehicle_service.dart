import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle.dart';

class VehicleService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Get all vehicles for the current user
  Future<List<VehicleModel>> getVehicles() async {
    final response = await _client
        .from('vehicles')
        .select('*, vehicle_media(url, is_primary)')
        .order('created_at', ascending: false);
    
    List<VehicleModel> vehicles = [];
    
    for (final vehicle in response) {
      String? primaryImageUrl;
      
      // Find primary image if available
      if (vehicle['vehicle_media'] != null && vehicle['vehicle_media'].isNotEmpty) {
        for (final media in vehicle['vehicle_media']) {
          if (media['is_primary'] == true) {
            primaryImageUrl = media['url'];
            break;
          }
        }
        
        // If no primary image is set, use the first one
        if (primaryImageUrl == null && vehicle['vehicle_media'].isNotEmpty) {
          primaryImageUrl = vehicle['vehicle_media'][0]['url'];
        }
      }
      
      // Add primary image URL to vehicle data
      final vehicleData = {...vehicle};
      vehicleData['primary_image_url'] = primaryImageUrl;
      
      vehicles.add(VehicleModel.fromJson(vehicleData));
    }
    
    return vehicles;
  }
  
  // Get a single vehicle by ID
  Future<VehicleModel> getVehicle(String id) async {
    final response = await _client
        .from('vehicles')
        .select('*, vehicle_media(url, is_primary)')
        .eq('id', id)
        .single();
    
    String? primaryImageUrl;
    
    // Find primary image if available
    if (response['vehicle_media'] != null && response['vehicle_media'].isNotEmpty) {
      for (final media in response['vehicle_media']) {
        if (media['is_primary'] == true) {
          primaryImageUrl = media['url'];
          break;
        }
      }
      
      // If no primary image is set, use the first one
      if (primaryImageUrl == null && response['vehicle_media'].isNotEmpty) {
        primaryImageUrl = response['vehicle_media'][0]['url'];
      }
    }
    
    // Add primary image URL to vehicle data
    final vehicleData = {...response};
    vehicleData['primary_image_url'] = primaryImageUrl;
    
    return VehicleModel.fromJson(vehicleData);
  }
  
  // Create a new vehicle
  Future<VehicleModel> createVehicle(Map<String, dynamic> vehicleData) async {
    // Ensure user_id is set to current user
    vehicleData['user_id'] = _client.auth.currentUser!.id;
    
    final response = await _client
        .from('vehicles')
        .insert(vehicleData)
        .select()
        .single();
    
    return VehicleModel.fromJson(response);
  }
  
  // Update an existing vehicle
  Future<VehicleModel> updateVehicle(String id, Map<String, dynamic> vehicleData) async {
    // Set updated_at to current time
    vehicleData['updated_at'] = DateTime.now().toIso8601String();
    
    final response = await _client
        .from('vehicles')
        .update(vehicleData)
        .eq('id', id)
        .select()
        .single();
    
    return VehicleModel.fromJson(response);
  }
  
  // Delete a vehicle
  Future<void> deleteVehicle(String id) async {
    await _client
        .from('vehicles')
        .delete()
        .eq('id', id);
  }
  
  // Upload vehicle image
  Future<String> uploadVehicleImage(String vehicleId, List<int> fileBytes, String fileName) async {
    final String path = 'vehicles/$vehicleId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    await _client
        .storage
        .from('vehicle-images')
        .uploadBinary(path, fileBytes);
    
    final String imageUrl = _client
        .storage
        .from('vehicle-images')
        .getPublicUrl(path);
    
    // Create media record in database
    await _client
        .from('vehicle_media')
        .insert({
          'vehicle_id': vehicleId,
          'media_type': 'image',
          'url': imageUrl,
          'is_primary': true, // Set as primary by default
        });
    
    return imageUrl;
  }
  
  // Get vehicle categories (for dropdown selection)
  List<String> getVehicleCategories() {
    return [
      'Car',
      'Truck',
      'Buggy',
      'Crawler',
      'Monster Truck',
      'Plane',
      'Helicopter',
      'Drone',
      'Boat',
      'Other'
    ];
  }
  
  // Get vehicle status options (for dropdown selection)
  List<String> getVehicleStatusOptions() {
    return [
      'active',
      'in_repair',
      'retired',
      'for_sale',
      'loaned'
    ];
  }
}
