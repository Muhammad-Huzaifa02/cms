import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps 1:1 to a document in the `users` collection.
/// Doc ID == Firebase Auth UID.
class Permissions {
  final bool view;
  final bool add;
  final bool edit;
  final bool delete;

  const Permissions({
    this.view = false,
    this.add = false,
    this.edit = false,
    this.delete = false,
  });

  factory Permissions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const Permissions();
    return Permissions(
      view: map['view'] ?? false,
      add: map['add'] ?? false,
      edit: map['edit'] ?? false,
      delete: map['delete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'view': view,
        'add': add,
        'edit': edit,
        'delete': delete,
      };

  Permissions copyWith({bool? view, bool? add, bool? edit, bool? delete}) {
    return Permissions(
      view: view ?? this.view,
      add: add ?? this.add,
      edit: edit ?? this.edit,
      delete: delete ?? this.delete,
    );
  }
}

class AppUser {
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final bool isAdmin;
  final Permissions permissions;
  final bool active;
  final String createdBy;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    this.email,
    this.phone,
    required this.isAdmin,
    required this.permissions,
    required this.active,
    required this.createdBy,
    this.createdAt,
  });

  /// Admin implicitly has every permission — matches the security rules'
  /// `can(perm)` helper (isAdmin() short-circuits the permission map check).
  bool can(String perm) {
    if (isAdmin) return true;
    switch (perm) {
      case 'view':
        return permissions.view;
      case 'add':
        return permissions.add;
      case 'edit':
        return permissions.edit;
      case 'delete':
        return permissions.delete;
      default:
        return false;
    }
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('User document is empty (ID: ${doc.id})');
    }
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      isAdmin: data['isAdmin'] ?? false,
      permissions: Permissions.fromMap(data['permissions']),
      active: data['active'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'isAdmin': isAdmin,
        'permissions': permissions.toMap(),
        'active': active,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
