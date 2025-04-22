import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({Key? key}) : super(key: key);

  @override
  _VehicleListScreenState createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final VehicleService _vehicleService = VehicleService();
  List<VehicleModel> _vehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load vehicles: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My RC Garage'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VehicleFormScreen(),
            ),
          );
          
          if (result == true) {
            _loadVehicles();
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
              onPressed: _loadVehicles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your RC Garage is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first RC vehicle',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView.builder(
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: vehicle.primaryImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        vehicle.primaryImageUrl!,
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
                      child: const Icon(Icons.directions_car),
                    ),
              title: Text(vehicle.name),
              subtitle: Text(
                [
                  if (vehicle.brand != null) vehicle.brand!,
                  if (vehicle.model != null) vehicle.model!,
                  vehicle.category,
                ].join(' • '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleDetailScreen(vehicleId: vehicle.id),
                  ),
                );
                
                if (result == true) {
                  _loadVehicles();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
