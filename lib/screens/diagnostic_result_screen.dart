import 'package:flutter/material.dart';
import '../models/diagnostic.dart';
import '../services/diagnostic_service.dart';
import '../services/part_service.dart';
import 'part_detail_screen.dart';

class DiagnosticResultScreen extends StatefulWidget {
  final String diagnosticId;

  const DiagnosticResultScreen({Key? key, required this.diagnosticId}) : super(key: key);

  @override
  _DiagnosticResultScreenState createState() => _DiagnosticResultScreenState();
}

class _DiagnosticResultScreenState extends State<DiagnosticResultScreen> {
  final DiagnosticService _diagnosticService = DiagnosticService();
  final PartService _partService = PartService();
  
  DiagnosticModel? _diagnostic;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDiagnostic();
  }

  Future<void> _loadDiagnostic() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final diagnostic = await _diagnosticService.getDiagnostic(widget.diagnosticId);
      setState(() {
        _diagnostic = DiagnosticModel.fromJson(diagnostic);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load diagnostic: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Results'),
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
              onPressed: _loadDiagnostic,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_diagnostic == null) {
      return const Center(
        child: Text('Diagnostic not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          _buildStatusHeader(),
          const SizedBox(height: 24),
          
          // Vehicle info (if available)
          if (_diagnostic!.vehicle != null) ...[
            const Text(
              'Vehicle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, size: 48, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _diagnostic!.vehicle!['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (_diagnostic!.vehicle!['brand'] != null) _diagnostic!.vehicle!['brand'],
                              if (_diagnostic!.vehicle!['model'] != null) _diagnostic!.vehicle!['model'],
                              _diagnostic!.vehicle!['category'],
                            ].join(' • '),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Issue description
          const Text(
            'Issue Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _diagnostic!.issueDescription,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Diagnostic images
          const Text(
            'Diagnostic Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _diagnostic!.media != null && _diagnostic!.media!.isNotEmpty
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _diagnostic!.media!.length,
                    itemBuilder: (context, index) {
                      final media = _diagnostic!.media![index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            // Show full-screen image
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Image.network(
                                  media['url'],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              media['url'],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text('No images available'),
                  ),
          ),
          const SizedBox(height: 24),
          
          // AI Diagnosis
          const Text(
            'AI Diagnosis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Analysis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _diagnostic!.diagnosisResult ?? 'No diagnosis available',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Suggested Parts
          if (_diagnostic!.suggestedParts != null && _diagnostic!.suggestedParts!.isNotEmpty) ...[
            const Text(
              'Suggested Parts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _diagnostic!.suggestedParts!.length,
              itemBuilder: (context, index) {
                final part = _diagnostic!.suggestedParts![index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.build, color: Colors.white),
                    ),
                    title: Text(part),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // In a real app, this would search for the part in the inventory
                        // or navigate to a parts search screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Searching for $part in inventory...'),
                          ),
                        );
                      },
                      child: const Text('Find Part'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // In a real app, this would create a new diagnostic
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Diagnostic'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Mark as resolved
                    _diagnosticService.updateDiagnostic(
                      _diagnostic!.id,
                      {'status': 'resolved'},
                    ).then((_) {
                      Navigator.pop(context, true);
                    });
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_diagnostic!.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending Analysis';
        break;
      case 'diagnosed':
        statusColor = Colors.blue;
        statusIcon = Icons.psychology;
        statusText = 'Diagnosis Complete';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Issue Resolved';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown Status';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created on ${_diagnostic!.createdAt.day}/${_diagnostic!.createdAt.month}/${_diagnostic!.createdAt.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
