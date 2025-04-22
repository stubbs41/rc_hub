import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import 'vehicle_form_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({Key? key, required this.vehicleId}) : super(key: key);

  @override
  _VehicleDetailScreenState createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final VehicleService _vehicleService = VehicleService();
  VehicleModel? _vehicle;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicle = await _vehicleService.getVehicle(widget.vehicleId);
      setState(() {
        _vehicle = vehicle;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load vehicle: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.'),
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
        await _vehicleService.deleteVehicle(widget.vehicleId);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate vehicle was deleted
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to delete vehicle: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vehicle?.name ?? 'Vehicle Details'),
        actions: [
          if (_vehicle != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleFormScreen(vehicle: _vehicle),
                  ),
                );
                
                if (result == true) {
                  _loadVehicle();
                }
              },
            ),
          if (_vehicle != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteVehicle,
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
              onPressed: _loadVehicle,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_vehicle == null) {
      return const Center(
        child: Text('Vehicle not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image
          if (_vehicle!.primaryImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _vehicle!.primaryImageUrl!,
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
              child: const Icon(Icons.directions_car, size: 64),
            ),
          const SizedBox(height: 24),
          
          // Vehicle Name
          Text(
            _vehicle!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Brand and Model
          if (_vehicle!.brand != null || _vehicle!.model != null)
            Text(
              [
                if (_vehicle!.brand != null) _vehicle!.brand!,
                if (_vehicle!.model != null) _vehicle!.model!,
              ].join(' '),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 24),
          
          // Vehicle Details
          _buildDetailItem('Category', _vehicle!.category),
          if (_vehicle!.scale != null)
            _buildDetailItem('Scale', _vehicle!.scale!),
          if (_vehicle!.year != null)
            _buildDetailItem('Year', _vehicle!.year.toString()),
          _buildDetailItem('Status', _vehicle!.status.replaceAll('_', ' ').toUpperCase()),
          if (_vehicle!.purchaseDate != null)
            _buildDetailItem('Purchase Date', '${_vehicle!.purchaseDate!.day}/${_vehicle!.purchaseDate!.month}/${_vehicle!.purchaseDate!.year}'),
          if (_vehicle!.purchasePrice != null)
            _buildDetailItem('Purchase Price', '\$${_vehicle!.purchasePrice!.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          
          // Description
          if (_vehicle!.description != null && _vehicle!.description!.isNotEmpty) ...[
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
              _vehicle!.description!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
          ],
          
          // Parts and Maintenance sections would go here in future implementations
          const Divider(),
          const SizedBox(height: 16),
          
          // Placeholder for Parts section
          const Text(
            'Parts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('No parts added yet.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // This will be implemented in the parts inventory step
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Parts management coming soon!')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Part'),
          ),
          const SizedBox(height: 24),
          
          // Placeholder for Diagnostics section
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Diagnostics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Use AI-assisted diagnostics to identify issues with your vehicle.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // This will be implemented in the AI diagnostics step
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI diagnostics coming soon!')),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('Start Diagnostics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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
            width: 120,
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
}
