import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/vehicle.dart';

class VehicleModel {
  final String id;
  final String userId;
  final String name;
  final String? brand;
  final String? model;
  final String category;
  final String? scale;
  final int? year;
  final String? description;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? primaryImageUrl;

  VehicleModel({
    required this.id,
    required this.userId,
    required this.name,
    this.brand,
    this.model,
    required this.category,
    this.scale,
    this.year,
    this.description,
    this.purchaseDate,
    this.purchasePrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.primaryImageUrl,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      brand: json['brand'],
      model: json['model'],
      category: json['category'],
      scale: json['scale'],
      year: json['year'],
      description: json['description'],
      purchaseDate: json['purchase_date'] != null ? DateTime.parse(json['purchase_date']) : null,
      purchasePrice: json['purchase_price'] != null ? double.parse(json['purchase_price'].toString()) : null,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      primaryImageUrl: json['primary_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'brand': brand,
      'model': model,
      'category': category,
      'scale': scale,
      'year': year,
      'description': description,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'primary_image_url': primaryImageUrl,
    };
  }
}
