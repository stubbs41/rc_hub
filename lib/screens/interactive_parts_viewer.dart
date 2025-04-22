import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/part.dart';
import '../services/part_service.dart';

class InteractivePartsViewer extends StatefulWidget {
  final String partId;

  const InteractivePartsViewer({Key? key, required this.partId}) : super(key: key);

  @override
  _InteractivePartsViewerState createState() => _InteractivePartsViewerState();
}

class _InteractivePartsViewerState extends State<InteractivePartsViewer> {
  final PartService _partService = PartService();
  PartModel? _part;
  bool _isLoading = true;
  String? _errorMessage;
  
  // For diagram interaction
  double _scale = 1.0;
  Offset _position = Offset.zero;
  Offset? _startingFocalPoint;
  Offset? _previousOffset;
  double _previousScale = 1.0;
  
  // Selected component
  String? _selectedComponentId;
  Map<String, dynamic>? _selectedComponent;

  // Sample hotspots data (in a real app, this would come from the database)
  final List<Map<String, dynamic>> _hotspots = [
    {
      'id': '1',
      'name': 'Front Shock Tower',
      'description': 'Aluminum front shock tower for improved durability',
      'x': 150.0,
      'y': 100.0,
      'width': 60.0,
      'height': 40.0,
      'part_number': 'TRX1234',
    },
    {
      'id': '2',
      'name': 'Front Shock',
      'description': 'Oil-filled front shock absorber',
      'x': 130.0,
      'y': 150.0,
      'width': 30.0,
      'height': 80.0,
      'part_number': 'TRX5678',
    },
    {
      'id': '3',
      'name': 'Steering Servo',
      'description': 'High-torque waterproof steering servo',
      'x': 200.0,
      'y': 120.0,
      'width': 50.0,
      'height': 40.0,
      'part_number': 'TRX9012',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPart();
  }

  Future<void> _loadPart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final part = await _partService.getPart(widget.partId);
      setState(() {
        _part = part;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load part: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _startingFocalPoint = details.focalPoint;
    _previousOffset = _position;
    _previousScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_startingFocalPoint != null) {
      final Offset delta = details.focalPoint - _startingFocalPoint!;
      final double newScale = _previousScale * details.scale;
      
      // Limit scale to reasonable bounds
      final scale = newScale.clamp(0.5, 3.0);
      
      setState(() {
        _scale = scale;
        _position = _previousOffset! + delta / scale;
      });
    }
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _position = Offset.zero;
      _selectedComponentId = null;
      _selectedComponent = null;
    });
  }

  void _selectComponent(String id) {
    final component = _hotspots.firstWhere((h) => h['id'] == id, orElse: () => {});
    
    setState(() {
      _selectedComponentId = id;
      _selectedComponent = component.isNotEmpty ? component : null;
    });
  }

  bool _isPointInHotspot(Offset point, Map<String, dynamic> hotspot) {
    final x = hotspot['x'] as double;
    final y = hotspot['y'] as double;
    final width = hotspot['width'] as double;
    final height = hotspot['height'] as double;
    
    return point.dx >= x && 
           point.dx <= x + width && 
           point.dy >= y && 
           point.dy <= y + height;
  }

  void _handleTap(TapUpDetails details) {
    // Convert tap position to diagram coordinates
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final Offset adjustedPosition = (localPosition - _position * _scale) / _scale;
    
    // Check if tap is within any hotspot
    for (final hotspot in _hotspots) {
      if (_isPointInHotspot(adjustedPosition, hotspot)) {
        _selectComponent(hotspot['id']);
        return;
      }
    }
    
    // If tap is not on any hotspot, deselect
    setState(() {
      _selectedComponentId = null;
      _selectedComponent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_part?.name ?? 'Interactive Parts Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetView,
            tooltip: 'Reset View',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPart,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_part == null) {
      return const Center(
        child: Text('Part not found'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onTapUp: _handleTap,
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Transform.scale(
                  scale: _scale,
                  child: Transform.translate(
                    offset: _position * _scale,
                    child: Stack(
                      children: [
                        // Sample diagram image (in a real app, this would be loaded from the database)
                        Image.network(
                          _part!.primaryImageUrl ?? 'https://via.placeholder.com/400x300?text=No+Diagram',
                          width: 400,
                          height: 300,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 400,
                              height: 300,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text('No diagram available'),
                              ),
                            );
                          },
                        ),
                        
                        // Hotspots
                        ..._hotspots.map((hotspot) {
                          final isSelected = hotspot['id'] == _selectedComponentId;
                          return Positioned(
                            left: hotspot['x'],
                            top: hotspot['y'],
                            child: Container(
                              width: hotspot['width'],
                              height: hotspot['height'],
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? Colors.red : Colors.blue,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                color: isSelected 
                                    ? Colors.red.withOpacity(0.3) 
                                    : Colors.blue.withOpacity(0.1),
                              ),
                              child: Center(
                                child: Text(
                                  hotspot['id'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.red : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Component details panel
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _selectedComponent != null ? 200 : 0,
          color: Colors.white,
          child: _selectedComponent != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedComponent!['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Part #: ${_selectedComponent!['part_number']}',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedComponent!['description'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // In a real app, this would navigate to the part detail screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('View details for ${_selectedComponent!['name']}'),
                                ),
                              );
                            },
                            child: const Text('View Details'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        
        // Instructions
        if (_selectedComponent == null)
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[50],
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pinch to zoom, drag to pan, and tap on a component to view details.',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
