import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/part.dart';

class PartModel {
  final String id;
  final String userId;
  final String name;
  final String? partNumber;
  final String? brand;
  final String category;
  final String? description;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final int quantity;
  final int? minQuantity;
  final List<String>? compatibleModels;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? primaryImageUrl;

  PartModel({
    required this.id,
    required this.userId,
    required this.name,
    this.partNumber,
    this.brand,
    required this.category,
    this.description,
    this.purchaseDate,
    this.purchasePrice,
    required this.quantity,
    this.minQuantity,
    this.compatibleModels,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.primaryImageUrl,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      partNumber: json['part_number'],
      brand: json['brand'],
      category: json['category'],
      description: json['description'],
      purchaseDate: json['purchase_date'] != null ? DateTime.parse(json['purchase_date']) : null,
      purchasePrice: json['purchase_price'] != null ? double.parse(json['purchase_price'].toString()) : null,
      quantity: json['quantity'] ?? 0,
      minQuantity: json['min_quantity'],
      compatibleModels: json['compatible_models'] != null 
          ? List<String>.from(json['compatible_models']) 
          : null,
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
      'part_number': partNumber,
      'brand': brand,
      'category': category,
      'description': description,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'compatible_models': compatibleModels,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'primary_image_url': primaryImageUrl,
    };
  }
}
