import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/part_diagram_service.dart';

class DiagramUploadScreen extends StatefulWidget {
  final String partId;

  const DiagramUploadScreen({Key? key, required this.partId}) : super(key: key);

  @override
  _DiagramUploadScreenState createState() => _DiagramUploadScreenState();
}

class _DiagramUploadScreenState extends State<DiagramUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final PartDiagramService _diagramService = PartDiagramService();
  
  final _titleController = TextEditingController();
  String _diagramType = 'exploded_view';
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<String> _diagramTypes = [];

  @override
  void initState() {
    super.initState();
    _diagramTypes = _diagramService.getDiagramTypes();
    _diagramType = _diagramTypes.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
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

  Future<void> _uploadDiagram() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      if (_imageFile == null) {
        setState(() {
          _errorMessage = 'Please select a diagram image';
        });
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Upload diagram image
      final imageUrl = await _diagramService.uploadDiagramImage(
        widget.partId,
        await _imageFile!.readAsBytes(),
        _imageFile!.path.split('/').last,
      );
      
      // Create diagram record
      await _diagramService.createDiagram({
        'part_id': widget.partId,
        'diagram_type': _diagramType,
        'url': imageUrl,
        'hotspots': [], // Initialize with empty hotspots
      });
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload diagram: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Diagram'),
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
                    
                    // Diagram Image
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tap to select diagram image',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Exploded View Diagram',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Diagram Type
                    DropdownButtonFormField<String>(
                      value: _diagramType,
                      decoration: const InputDecoration(
                        labelText: 'Diagram Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _diagramTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _diagramType = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a diagram type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Upload Button
                    ElevatedButton(
                      onPressed: _uploadDiagram,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Upload Diagram',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
