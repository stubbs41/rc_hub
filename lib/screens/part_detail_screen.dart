import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/part_service.dart';
import 'part_form_screen.dart';

class PartDetailScreen extends StatefulWidget {
  final String partId;
  final String? vehicleId; // Optional: If provided, shows part in context of a vehicle

  const PartDetailScreen({Key? key, required this.partId, this.vehicleId}) : super(key: key);

  @override
  _PartDetailScreenState createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  final PartService _partService = PartService();
  PartModel? _part;
  bool _isLoading = true;
  String? _errorMessage;

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

  Future<void> _deletePart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Part'),
        content: const Text('Are you sure you want to delete this part? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _partService.deletePart(widget.partId);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate part was deleted
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to delete part: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromVehicle() async {
    if (widget.vehicleId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Part'),
        content: const Text('Are you sure you want to remove this part from the vehicle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _partService.removePartFromVehicle(widget.vehicleId!, widget.partId);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate part was removed
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to remove part: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_part?.name ?? 'Part Details'),
        actions: [
          if (_part != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PartFormScreen(part: _part),
                  ),
                );
                
                if (result == true) {
                  _loadPart();
                }
              },
            ),
          if (_part != null && widget.vehicleId != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _removeFromVehicle,
              tooltip: 'Remove from vehicle',
            )
          else if (_part != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePart,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part Image
          if (_part!.primaryImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _part!.primaryImageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 64),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build, size: 64),
            ),
          const SizedBox(height: 24),
          
          // Part Name
          Text(
            _part!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Brand and Part Number
          if (_part!.brand != null || _part!.partNumber != null)
            Text(
              [
                if (_part!.brand != null) _part!.brand!,
                if (_part!.partNumber != null) 'PN: ${_part!.partNumber!}',
              ].join(' • '),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 16),
          
          // Inventory Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(_part!.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getStatusColor(_part!.status)),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(_part!.status),
                  color: _getStatusColor(_part!.status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _part!.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_part!.status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: ${_part!.quantity}' + 
                        (_part!.minQuantity != null ? ' (Min: ${_part!.minQuantity})' : ''),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Part Details
          _buildDetailItem('Category', _part!.category),
          if (_part!.compatibleModels != null && _part!.compatibleModels!.isNotEmpty)
            _buildDetailItem('Compatible Models', _part!.compatibleModels!.join(', ')),
          if (_part!.purchaseDate != null)
            _buildDetailItem('Purchase Date', '${_part!.purchaseDate!.day}/${_part!.purchaseDate!.month}/${_part!.purchaseDate!.year}'),
          if (_part!.purchasePrice != null)
            _buildDetailItem('Purchase Price', '\$${_part!.purchasePrice!.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          
          // Description
          if (_part!.description != null && _part!.description!.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _part!.description!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
          ],
          
          // Interactive Parts Viewer
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Interactive Parts Viewer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InteractivePartsViewer(partId: widget.partId),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Stack(
                children: [
                  if (_part!.primaryImageUrl != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Opacity(
                          opacity: 0.7,
                          child: Image.network(
                            _part!.primaryImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.view_in_ar, size: 48, color: Colors.blue),
                        SizedBox(height: 8),
                        Text(
                          'Open Interactive Viewer',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Add to Vehicle Button (if not already in vehicle context)
          if (widget.vehicleId == null)
            ElevatedButton.icon(
              onPressed: () {
                // This will be implemented in a future step
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add to vehicle feature coming soon!')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add to Vehicle'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'in_stock':
        return Icons.check_circle;
      case 'low_stock':
        return Icons.warning;
      case 'out_of_stock':
        return Icons.remove_circle;
      case 'on_order':
        return Icons.shopping_cart;
      case 'discontinued':
        return Icons.do_not_disturb;
      default:
        return Icons.help;
    }
  }
}
