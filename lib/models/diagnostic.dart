import 'package:flutter/material.dart';
import '../models/diagnostic.dart';

class DiagnosticModel {
  final String id;
  final String userId;
  final String? vehicleId;
  final String issueDescription;
  final String? diagnosisResult;
  final List<String>? suggestedParts;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? vehicle;
  final List<Map<String, dynamic>>? media;

  DiagnosticModel({
    required this.id,
    required this.userId,
    this.vehicleId,
    required this.issueDescription,
    this.diagnosisResult,
    this.suggestedParts,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.vehicle,
    this.media,
  });

  factory DiagnosticModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticModel(
      id: json['id'],
      userId: json['user_id'],
      vehicleId: json['vehicle_id'],
      issueDescription: json['issue_description'],
      diagnosisResult: json['diagnosis_result'],
      suggestedParts: json['suggested_parts'] != null 
          ? List<String>.from(json['suggested_parts']) 
          : null,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      vehicle: json['vehicles'],
      media: json['diagnostic_media'] != null 
          ? List<Map<String, dynamic>>.from(json['diagnostic_media']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'issue_description': issueDescription,
      'diagnosis_result': diagnosisResult,
      'suggested_parts': suggestedParts,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
