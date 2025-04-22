import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diagnostic.dart';

class DiagnosticService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Create a new diagnostic request
  Future<Map<String, dynamic>> createDiagnostic({
    required String userId,
    String? vehicleId,
    required String issueDescription,
  }) async {
    final response = await _client
        .from('diagnostics')
        .insert({
          'user_id': userId,
          'vehicle_id': vehicleId,
          'issue_description': issueDescription,
          'status': 'pending',
        })
        .select()
        .single();
    
    return response;
  }
  
  // Get all diagnostics for the current user
  Future<List<Map<String, dynamic>>> getDiagnostics() async {
    final response = await _client
        .from('diagnostics')
        .select('*, vehicles(name, brand, model, category)')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // Get a single diagnostic by ID
  Future<Map<String, dynamic>> getDiagnostic(String id) async {
    final response = await _client
        .from('diagnostics')
        .select('*, vehicles(name, brand, model, category), diagnostic_media(id, url)')
        .eq('id', id)
        .single();
    
    return response;
  }
  
  // Update a diagnostic
  Future<Map<String, dynamic>> updateDiagnostic(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('diagnostics')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    
    return response;
  }
  
  // Delete a diagnostic
  Future<void> deleteDiagnostic(String id) async {
    await _client
        .from('diagnostics')
        .delete()
        .eq('id', id);
  }
  
  // Upload diagnostic image
  Future<String> uploadDiagnosticImage(String diagnosticId, List<int> fileBytes, String fileName) async {
    final String path = 'diagnostics/$diagnosticId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    await _client
        .storage
        .from('diagnostic-images')
        .uploadBinary(path, fileBytes);
    
    final String imageUrl = _client
        .storage
        .from('diagnostic-images')
        .getPublicUrl(path);
    
    // Create media record in database
    await _client
        .from('diagnostic_media')
        .insert({
          'diagnostic_id': diagnosticId,
          'media_type': 'image',
          'url': imageUrl,
        });
    
    return imageUrl;
  }
  
  // Analyze diagnostic images using AI
  Future<Map<String, dynamic>> analyzeDiagnostic(String diagnosticId) async {
    // In a real application, this would call an AI service API
    // For this demo, we'll simulate an AI response
    
    // First, get the diagnostic details
    final diagnostic = await getDiagnostic(diagnosticId);
    
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate a simulated AI response based on the issue description
    final issueDescription = diagnostic['issue_description'] as String;
    final vehicleInfo = diagnostic['vehicles'];
    
    Map<String, dynamic> aiResponse = {};
    
    if (issueDescription.toLowerCase().contains('steering')) {
      aiResponse = {
        'diagnosis_result': 'The steering issue appears to be caused by worn out steering linkage or a damaged servo. The servo gears may be stripped or there could be excessive play in the steering mechanism.',
        'suggested_parts': [
          'Steering Servo',
          'Steering Linkage Kit',
          'Servo Saver',
          'Steering Bellcrank'
        ],
        'confidence': 0.85,
      };
    } else if (issueDescription.toLowerCase().contains('motor') || 
               issueDescription.toLowerCase().contains('power')) {
      aiResponse = {
        'diagnosis_result': 'The power issue is likely related to the motor or ESC (Electronic Speed Controller). There may be damaged wiring, worn brushes in the motor, or a failing ESC.',
        'suggested_parts': [
          'Brushless Motor',
          'Electronic Speed Controller (ESC)',
          'Motor Wiring Harness',
          'Battery Connector'
        ],
        'confidence': 0.78,
      };
    } else if (issueDescription.toLowerCase().contains('suspension') || 
               issueDescription.toLowerCase().contains('shock')) {
      aiResponse = {
        'diagnosis_result': 'The suspension problem appears to be due to leaking shock absorbers or damaged suspension arms. There may also be issues with the shock mounting points or worn bushings.',
        'suggested_parts': [
          'Front Shock Absorbers',
          'Rear Shock Absorbers',
          'Suspension Arm Set',
          'Shock Oil'
        ],
        'confidence': 0.92,
      };
    } else if (issueDescription.toLowerCase().contains('wheel') || 
               issueDescription.toLowerCase().contains('tire')) {
      aiResponse = {
        'diagnosis_result': 'The wheel/tire issue is likely due to worn tires, damaged rims, or problems with the wheel bearings. There may also be issues with the wheel hexes or drive shafts.',
        'suggested_parts': [
          'Tire Set',
          'Wheel Rims',
          'Wheel Bearings',
          'Wheel Hexes'
        ],
        'confidence': 0.88,
      };
    } else {
      aiResponse = {
        'diagnosis_result': 'Based on the description and images, there appears to be general wear and tear on multiple components. A thorough inspection of the vehicle is recommended, with particular attention to the drivetrain and electronics.',
        'suggested_parts': [
          'Maintenance Kit',
          'Bearing Set',
          'Hardware Kit',
          'Lubricant Pack'
        ],
        'confidence': 0.65,
      };
    }
    
    // Update the diagnostic with the AI results
    final updatedDiagnostic = await updateDiagnostic(diagnosticId, {
      'diagnosis_result': aiResponse['diagnosis_result'],
      'suggested_parts': aiResponse['suggested_parts'],
      'status': 'diagnosed',
    });
    
    return updatedDiagnostic;
  }
}
