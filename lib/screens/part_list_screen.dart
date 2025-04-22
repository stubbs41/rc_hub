import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/part_service.dart';
import 'part_detail_screen.dart';
import 'part_form_screen.dart';

class PartListScreen extends StatefulWidget {
  final String? vehicleId; // Optional: If provided, shows parts for a specific vehicle

  const PartListScreen({Key? key, this.vehicleId}) : super(key: key);

  @override
  _PartListScreenState createState() => _PartListScreenState();
}

class _PartListScreenState extends State<PartListScreen> {
  final PartService _partService = PartService();
  List<PartModel> _parts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parts = widget.vehicleId != null
          ? await _partService.getPartsForVehicle(widget.vehicleId!)
          : await _partService.getParts();
      
      setState(() {
        _parts = parts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load parts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicleId != null ? 'Vehicle Parts' : 'Parts Inventory'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartFormScreen(vehicleId: widget.vehicleId),
            ),
          );
          
          if (result == true) {
            _loadParts();
          }
        },
        child: const Icon(Icons.add),
      ),
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
              onPressed: _loadParts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_parts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.build_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              widget.vehicleId != null
                  ? 'No parts added to this vehicle'
                  : 'Your parts inventory is empty',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add parts',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadParts,
      child: ListView.builder(
        itemCount: _parts.length,
        itemBuilder: (context, index) {
          final part = _parts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: part.primaryImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        part.primaryImageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.build),
                    ),
              title: Text(part.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (part.brand != null) part.brand!,
                      if (part.partNumber != null) 'PN: ${part.partNumber!}',
                      part.category,
                    ].join(' • '),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(part.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Qty: ${part.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        part.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(part.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PartDetailScreen(
                      partId: part.id,
                      vehicleId: widget.vehicleId,
                    ),
                  ),
                );
                
                if (result == true) {
                  _loadParts();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_stock':
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.red;
      case 'on_order':
        return Colors.blue;
      case 'discontinued':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
