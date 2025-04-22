import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class VehicleFormScreen extends StatefulWidget {
  final VehicleModel? vehicle;

  const VehicleFormScreen({Key? key, this.vehicle}) : super(key: key);

  @override
  _VehicleFormScreenState createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();
  
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _scaleController = TextEditingController();
  final _yearController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  
  String _category = 'Car';
  String _status = 'active';
  DateTime? _purchaseDate;
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<String> _categories = [];
  List<String> _statusOptions = [];

  @override
  void initState() {
    super.initState();
    _categories = _vehicleService.getVehicleCategories();
    _statusOptions = _vehicleService.getVehicleStatusOptions();
    
    // Set default category and status
    _category = _categories.first;
    _status = _statusOptions.first;
    
    // If editing an existing vehicle, populate the form
    if (widget.vehicle != null) {
      _nameController.text = widget.vehicle!.name;
      _brandController.text = widget.vehicle!.brand ?? '';
      _modelController.text = widget.vehicle!.model ?? '';
      _category = widget.vehicle!.category;
      _scaleController.text = widget.vehicle!.scale ?? '';
      _yearController.text = widget.vehicle!.year?.toString() ?? '';
      _descriptionController.text = widget.vehicle!.description ?? '';
      _purchaseDate = widget.vehicle!.purchaseDate;
      _purchasePriceController.text = widget.vehicle!.purchasePrice?.toString() ?? '';
      _status = widget.vehicle!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _scaleController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Prepare vehicle data
      final vehicleData = {
        'name': _nameController.text,
        'brand': _brandController.text.isEmpty ? null : _brandController.text,
        'model': _modelController.text.isEmpty ? null : _modelController.text,
        'category': _category,
        'scale': _scaleController.text.isEmpty ? null : _scaleController.text,
        'year': _yearController.text.isEmpty ? null : int.parse(_yearController.text),
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'purchase_date': _purchaseDate?.toIso8601String(),
        'purchase_price': _purchasePriceController.text.isEmpty ? null : double.parse(_purchasePriceController.text),
        'status': _status,
      };
      
      VehicleModel vehicle;
      
      if (widget.vehicle == null) {
        // Create new vehicle
        vehicle = await _vehicleService.createVehicle(vehicleData);
      } else {
        // Update existing vehicle
        vehicle = await _vehicleService.updateVehicle(widget.vehicle!.id, vehicleData);
      }
      
      // Upload image if selected
      if (_imageFile != null) {
        await _vehicleService.uploadVehicleImage(
          vehicle.id,
          await _imageFile!.readAsBytes(),
          _imageFile!.path.split('/').last,
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save vehicle: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    
                    // Vehicle Image
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.vehicle?.primaryImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.vehicle!.primaryImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text('Tap to add photo'),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name (required)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        hintText: 'My Traxxas Slash',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Brand
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        hintText: 'Traxxas, Axial, HPI, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Model
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'Slash 4x4, SCX10, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category (required)
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Scale
                    TextFormField(
                      controller: _scaleController,
                      decoration: const InputDecoration(
                        labelText: 'Scale',
                        hintText: '1:10, 1:8, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Year
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        hintText: '2023',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid year';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Details about your RC vehicle',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Purchase Date
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: _purchaseDate == null
                                ? ''
                                : '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Purchase Price
                    TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                        hintText: '299.99',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid price';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Status (required)
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a status';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _saveVehicle,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.vehicle == null ? 'Add Vehicle' : 'Save Changes',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
