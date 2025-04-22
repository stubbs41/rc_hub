import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/part.dart';

class PartDiagramService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Get diagrams for a specific part
  Future<List<Map<String, dynamic>>> getPartDiagrams(String partId) async {
    final response = await _client
        .from('part_diagrams')
        .select('*')
        .eq('part_id', partId)
        .order('created_at');
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // Get a specific diagram by ID
  Future<Map<String, dynamic>> getDiagram(String diagramId) async {
    final response = await _client
        .from('part_diagrams')
        .select('*')
        .eq('id', diagramId)
        .single();
    
    return response;
  }
  
  // Create a new diagram
  Future<Map<String, dynamic>> createDiagram(Map<String, dynamic> diagramData) async {
    final response = await _client
        .from('part_diagrams')
        .insert(diagramData)
        .select()
        .single();
    
    return response;
  }
  
  // Update an existing diagram
  Future<Map<String, dynamic>> updateDiagram(String diagramId, Map<String, dynamic> diagramData) async {
    final response = await _client
        .from('part_diagrams')
        .update(diagramData)
        .eq('id', diagramId)
        .select()
        .single();
    
    return response;
  }
  
  // Delete a diagram
  Future<void> deleteDiagram(String diagramId) async {
    await _client
        .from('part_diagrams')
        .delete()
        .eq('id', diagramId);
  }
  
  // Upload diagram image
  Future<String> uploadDiagramImage(String partId, List<int> fileBytes, String fileName) async {
    final String path = 'diagrams/$partId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    await _client
        .storage
        .from('part-diagrams')
        .uploadBinary(path, fileBytes);
    
    final String imageUrl = _client
        .storage
        .from('part-diagrams')
        .getPublicUrl(path);
    
    return imageUrl;
  }
  
  // Add hotspot to diagram
  Future<Map<String, dynamic>> addHotspot(String diagramId, Map<String, dynamic> hotspot) async {
    // Get current diagram
    final diagram = await getDiagram(diagramId);
    
    // Get current hotspots or initialize empty array
    List<dynamic> hotspots = [];
    if (diagram['hotspots'] != null) {
      hotspots = List<dynamic>.from(diagram['hotspots']);
    }
    
    // Add new hotspot
    hotspots.add(hotspot);
    
    // Update diagram with new hotspots
    final updatedDiagram = await updateDiagram(diagramId, {
      'hotspots': hotspots,
    });
    
    return updatedDiagram;
  }
  
  // Update hotspot in diagram
  Future<Map<String, dynamic>> updateHotspot(String diagramId, String hotspotId, Map<String, dynamic> updatedHotspot) async {
    // Get current diagram
    final diagram = await getDiagram(diagramId);
    
    // Get current hotspots
    List<dynamic> hotspots = List<dynamic>.from(diagram['hotspots'] ?? []);
    
    // Find and update the hotspot
    final index = hotspots.indexWhere((h) => h['id'] == hotspotId);
    if (index != -1) {
      hotspots[index] = updatedHotspot;
      
      // Update diagram with modified hotspots
      final updatedDiagram = await updateDiagram(diagramId, {
        'hotspots': hotspots,
      });
      
      return updatedDiagram;
    } else {
      throw Exception('Hotspot not found');
    }
  }
  
  // Remove hotspot from diagram
  Future<Map<String, dynamic>> removeHotspot(String diagramId, String hotspotId) async {
    // Get current diagram
    final diagram = await getDiagram(diagramId);
    
    // Get current hotspots
    List<dynamic> hotspots = List<dynamic>.from(diagram['hotspots'] ?? []);
    
    // Remove the hotspot
    hotspots.removeWhere((h) => h['id'] == hotspotId);
    
    // Update diagram with modified hotspots
    final updatedDiagram = await updateDiagram(diagramId, {
      'hotspots': hotspots,
    });
    
    return updatedDiagram;
  }
  
  // Get diagram types (for dropdown selection)
  List<String> getDiagramTypes() {
    return [
      'exploded_view',
      'schematic',
      '3d_model',
      'wiring_diagram',
      'assembly_guide',
    ];
  }
}
