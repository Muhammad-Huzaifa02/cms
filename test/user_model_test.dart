import 'package:flutter_test/flutter_test.dart';
import 'package:cms/data/models/user_model.dart';

void main() {
  group('Permissions Model', () {
    test('defaults to false for all permissions', () {
      const perms = Permissions();
      expect(perms.view, isFalse);
      expect(perms.add, isFalse);
      expect(perms.edit, isFalse);
      expect(perms.delete, isFalse);
    });

    test('serializes toMap and deserializes fromMap correctly', () {
      const perms = Permissions(view: true, add: true, edit: false, delete: false);
      final map = perms.toMap();
      expect(map, equals({'view': true, 'add': true, 'edit': false, 'delete': false}));

      final reconstructed = Permissions.fromMap(map);
      expect(reconstructed.view, isTrue);
      expect(reconstructed.add, isTrue);
      expect(reconstructed.edit, isFalse);
      expect(reconstructed.delete, isFalse);
    });

    test('copyWith modifies targeted permissions only', () {
      const perms = Permissions(view: true, add: false);
      final updated = perms.copyWith(add: true, edit: true);
      expect(updated.view, isTrue);
      expect(updated.add, isTrue);
      expect(updated.edit, isTrue);
      expect(updated.delete, isFalse);
    });
  });

  group('AppUser Model', () {
    test('Admin user has permission to perform all actions implicitly', () {
      const admin = AppUser(
        uid: 'admin_1',
        name: 'Branch Manager',
        isAdmin: true,
        permissions: Permissions(view: false, add: false, edit: false, delete: false),
        active: true,
        createdBy: 'system',
      );

      expect(admin.can('view'), isTrue);
      expect(admin.can('add'), isTrue);
      expect(admin.can('edit'), isTrue);
      expect(admin.can('delete'), isTrue);
    });

    test('Staff user permission check respects explicit permissions map', () {
      const staff = AppUser(
        uid: 'staff_1',
        name: 'Staff Officer',
        isAdmin: false,
        permissions: Permissions(view: true, add: true, edit: false, delete: false),
        active: true,
        createdBy: 'admin_1',
      );

      expect(staff.can('view'), isTrue);
      expect(staff.can('add'), isTrue);
      expect(staff.can('edit'), isFalse);
      expect(staff.can('delete'), isFalse);
      expect(staff.can('unknown_permission'), isFalse);
    });
  });
}
