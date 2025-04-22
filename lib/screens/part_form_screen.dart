import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/part.dart';
import '../services/part_service.dart';

class PartFormScreen extends StatefulWidget {
  final PartModel? part;
  final String? vehicleId; // Optional: If provided, will add part to vehicle after creation

  const PartFormScreen({Key? key, this.part, this.vehicleId}) : super(key: key);

  @override
  _PartFormScreenState createState() => _PartFormScreenState();
}

class _PartFormScreenState extends State<PartFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PartService _partService = PartService();
  
  final _nameController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _compatibleModelsController = TextEditingController();
  
  String _category = 'Engine';
  String _status = 'in_stock';
  DateTime? _purchaseDate;
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<String> _categories = [];
  List<String> _statusOptions = [];

  @override
  void initState() {
    super.initState();
    _categories = _partService.getPartCategories();
    _statusOptions = _partService.getPartStatusOptions();
    
    // Set default category and status
    _category = _categories.first;
    _status = _statusOptions.first;
    
    // Default quantity to 1
    _quantityController.text = '1';
    
    // If editing an existing part, populate the form
    if (widget.part != null) {
      _nameController.text = widget.part!.name;
      _partNumberController.text = widget.part!.partNumber ?? '';
      _brandController.text = widget.part!.brand ?? '';
      _category = widget.part!.category;
      _descriptionController.text = widget.part!.description ?? '';
      _purchaseDate = widget.part!.purchaseDate;
      _purchasePriceController.text = widget.part!.purchasePrice?.toString() ?? '';
      _quantityController.text = widget.part!.quantity.toString();
      _minQuantityController.text = widget.part!.minQuantity?.toString() ?? '';
      _compatibleModelsController.text = widget.part!.compatibleModels?.join(', ') ?? '';
      _status = widget.part!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partNumberController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _compatibleModelsController.dispose();
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

  Future<void> _savePart() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Parse compatible models
      List<String>? compatibleModels;
      if (_compatibleModelsController.text.isNotEmpty) {
        compatibleModels = _compatibleModelsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      
      // Prepare part data
      final partData = {
        'name': _nameController.text,
        'part_number': _partNumberController.text.isEmpty ? null : _partNumberController.text,
        'brand': _brandController.text.isEmpty ? null : _brandController.text,
        'category': _category,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'purchase_date': _purchaseDate?.toIso8601String(),
        'purchase_price': _purchasePriceController.text.isEmpty ? null : double.parse(_purchasePriceController.text),
        'quantity': int.parse(_quantityController.text),
        'min_quantity': _minQuantityController.text.isEmpty ? null : int.parse(_minQuantityController.text),
        'compatible_models': compatibleModels,
        'status': _status,
      };
      
      PartModel part;
      
      if (widget.part == null) {
        // Create new part
        part = await _partService.createPart(partData);
      } else {
        // Update existing part
        part = await _partService.updatePart(widget.part!.id, partData);
      }
      
      // Upload image if selected
      if (_imageFile != null) {
        await _partService.uploadPartImage(
          part.id,
          await _imageFile!.readAsBytes(),
          _imageFile!.path.split('/').last,
        );
      }
      
      // If vehicleId is provided, add part to vehicle
      if (widget.vehicleId != null && widget.part == null) {
        await _partService.addPartToVehicle(
          widget.vehicleId!,
          part.id,
          installationDate: DateTime.now(),
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save part: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.part == null ? 'Add Part' : 'Edit Part'),
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
                    
                    // Part Image
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
                            : widget.part?.primaryImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.part!.primaryImageUrl!,
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
                        hintText: 'Aluminum Shock Tower',
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
                    
                    // Part Number
                    TextFormField(
                      controller: _partNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Part Number',
                        hintText: 'TRX1234',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Brand
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        hintText: 'Traxxas, RPM, etc.',
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
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Details about the part',
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
                        hintText: '29.99',
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
                    
                    // Quantity (required)
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        hintText: '1',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) < 0) {
                          return 'Quantity cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Min Quantity
                    TextFormField(
                      controller: _minQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Quantity',
                        hintText: 'For inventory alerts',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Minimum quantity cannot be negative';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Compatible Models
                    TextFormField(
                      controller: _compatibleModelsController,
                      decoration: const InputDecoration(
                        labelText: 'Compatible Models',
                        hintText: 'Slash 4x4, SCX10, etc. (comma separated)',
                        border: OutlineInputBorder(),
                      ),
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
                      onPressed: _savePart,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.part == null ? 'Add Part' : 'Save Changes',
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
