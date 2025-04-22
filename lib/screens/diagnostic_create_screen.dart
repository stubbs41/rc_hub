import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/diagnostic.dart';
import '../services/diagnostic_service.dart';
import '../services/vehicle_service.dart';
import 'diagnostic_result_screen.dart';

class DiagnosticCreateScreen extends StatefulWidget {
  final String? vehicleId; // Optional: If provided, pre-selects the vehicle

  const DiagnosticCreateScreen({Key? key, this.vehicleId}) : super(key: key);

  @override
  _DiagnosticCreateScreenState createState() => _DiagnosticCreateScreenState();
}

class _DiagnosticCreateScreenState extends State<DiagnosticCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final DiagnosticService _diagnosticService = DiagnosticService();
  final VehicleService _vehicleService = VehicleService();
  
  final _issueDescriptionController = TextEditingController();
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _vehicles = [];
  List<File> _imageFiles = [];
  bool _isLoading = false;
  bool _isLoadingVehicles = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
    _loadVehicles();
  }

  @override
  void dispose() {
    _issueDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
    });

    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles.map((v) => {
          'id': v.id,
          'name': v.name,
          'brand': v.brand,
          'model': v.model,
          'category': v.category,
        }).toList();
        _isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load vehicles: ${e.toString()}';
        _isLoadingVehicles = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _imageFiles.add(File(image.path));
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _imageFiles.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _submitDiagnostic() async {
    if (!_formKey.currentState!.validate() || _imageFiles.isEmpty) {
      if (_imageFiles.isEmpty) {
        setState(() {
          _errorMessage = 'Please add at least one image of the issue';
        });
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Create diagnostic record
      final userId = _diagnosticService._client.auth.currentUser!.id;
      final diagnostic = await _diagnosticService.createDiagnostic(
        userId: userId,
        vehicleId: _selectedVehicleId,
        issueDescription: _issueDescriptionController.text,
      );
      
      // Upload all images
      for (final imageFile in _imageFiles) {
        await _diagnosticService.uploadDiagnosticImage(
          diagnostic['id'],
          await imageFile.readAsBytes(),
          imageFile.path.split('/').last,
        );
      }
      
      // Analyze the diagnostic
      final analyzedDiagnostic = await _diagnosticService.analyzeDiagnostic(diagnostic['id']);
      
      if (mounted) {
        // Navigate to results screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DiagnosticResultScreen(
              diagnosticId: analyzedDiagnostic['id'],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit diagnostic: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnostics'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing your RC vehicle...'),
                ],
              ),
            )
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
                    
                    // Header
                    const Text(
                      'AI-Assisted Diagnostics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload photos of your RC vehicle issue and get AI-powered analysis and suggestions.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Vehicle Selection
                    _isLoadingVehicles
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _selectedVehicleId,
                            decoration: const InputDecoration(
                              labelText: 'Select Vehicle (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('No specific vehicle'),
                              ),
                              ..._vehicles.map((vehicle) {
                                return DropdownMenuItem<String>(
                                  value: vehicle['id'],
                                  child: Text(
                                    [
                                      vehicle['name'],
                                      if (vehicle['brand'] != null) vehicle['brand'],
                                      if (vehicle['model'] != null) vehicle['model'],
                                    ].join(' - '),
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicleId = value;
                              });
                            },
                          ),
                    const SizedBox(height: 16),
                    
                    // Issue Description
                    TextFormField(
                      controller: _issueDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Describe the Issue *',
                        hintText: 'E.g., Steering is not responding correctly, motor is making unusual noise...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe the issue';
                        }
                        if (value.length < 10) {
                          return 'Please provide a more detailed description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Image Upload Section
                    const Text(
                      'Upload Images *',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add clear photos of the issue from different angles.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    // Image Picker Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _takePicture,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Selected Images
                    if (_imageFiles.isNotEmpty) ...[
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageFiles.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _imageFiles[index],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitDiagnostic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Analyze Issue',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Our AI will analyze your photos and provide diagnostic suggestions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
