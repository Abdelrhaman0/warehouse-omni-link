import 'package:equatable/equatable.dart';

/// Represents a financial safe from the backend.
class Safe extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String type;
  final String? typeLabel;
  final String? accountNumber;
  final double balance;
  final String currency;
  final bool isActive;
  final String? notes;
  final SafeCreator? creator;
  final bool canBeDeleted;
  final String? createdAt;
  final String? updatedAt;

  const Safe({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.type,
    this.typeLabel,
    this.accountNumber,
    required this.balance,
    required this.currency,
    required this.isActive,
    this.notes,
    this.creator,
    required this.canBeDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory Safe.fromJson(Map<String, dynamic> json) {
    final nameTranslations = json['name_translations'] as Map<String, dynamic>?;

    return Safe(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      nameAr: nameTranslations?['ar']?.toString() ?? json['name_ar']?.toString(),
      nameEn: nameTranslations?['en']?.toString() ?? json['name_en']?.toString(),
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString(),
      accountNumber: json['account_number']?.toString(),
      balance: _parseDouble(json['balance']),
      currency: json['currency']?.toString() ?? 'EGP',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      notes: json['notes']?.toString(),
      creator: json['creator'] is Map<String, dynamic>
          ? SafeCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      canBeDeleted: json['can_be_deleted'] == true || json['can_be_deleted'] == 1,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  /// Whether the currency matches the expected EGP for this feature.
  bool get isExpectedCurrency => currency.toUpperCase() == 'EGP';

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [id, name, type, balance, currency, isActive, updatedAt];
}

/// Creator or performer information attached to safes and transactions.
class SafeCreator extends Equatable {
  final int? id;
  final String? name;
  final String? email;

  const SafeCreator({this.id, this.name, this.email});

  factory SafeCreator.fromJson(Map<String, dynamic> json) {
    return SafeCreator(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, email];
}
