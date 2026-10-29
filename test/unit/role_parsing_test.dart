import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/auth/models/admin_user.dart';
import 'package:warehouse_store_keeper/features/auth/models/login_response.dart';

void main() {
  group('Role and Permissions Parsing Tests (Section 13)', () {
    test('A valid store_keeper role is parsed correctly into AdminUser and UserRole', () {
      final json = {
        'id': 5,
        'uuid': 'uuid-store-keeper',
        'name': 'Warehouse Operator',
        'email': 'keeper@omni-link.net',
        'role': 'store_keeper',
        'role_name': 'امين المخزن',
        'permissions': ['dashboard.view', 'orders.read'],
      };

      final user = AdminUser.fromJson(json);

      expect(user.id, '5');
      expect(user.role, 'store_keeper');
      expect(user.roleName, 'امين المخزن');
      expect(user.userRole, UserRole.storeKeeper);
      expect(user.isStoreKeeper, isTrue);
      expect(user.isSuperAdmin, isFalse);
      expect(user.permissions, ['dashboard.view', 'orders.read']);
      expect(user.roleDisplay, 'امين المخزن');
    });

    test('A valid super_admin role is parsed correctly into AdminUser and UserRole', () {
      final json = {
        'id': 1,
        'uuid': 'uuid-super-admin',
        'name': 'Master Admin',
        'email': 'admin@omni-link.net',
        'role': 'super_admin',
        'role_name': 'مدير عام',
        'permissions': ['dashboard.view', 'reports.view'],
      };

      final user = AdminUser.fromJson(json);

      expect(user.id, '1');
      expect(user.role, 'super_admin');
      expect(user.roleName, 'مدير عام');
      expect(user.userRole, UserRole.superAdmin);
      expect(user.isSuperAdmin, isTrue);
      expect(user.isStoreKeeper, isFalse);
      expect(user.permissions, ['dashboard.view', 'reports.view']);
      expect(user.roleDisplay, 'مدير عام');
    });

    test('role_name does not replace the machine-readable role identifier', () {
      final json = {
        'id': 10,
        'name': 'Store Keeper with Arabic Role Name',
        'email': 'user@example.com',
        'role': 'store_keeper',
        'role_name': 'مدير عام', // Conflicting or localized name
        'permissions': <String>[],
      };

      final user = AdminUser.fromJson(json);

      // Authorization decisions must strictly use machine-readable `role`
      expect(user.role, 'store_keeper');
      expect(user.userRole, UserRole.storeKeeper);
      expect(user.isSuperAdmin, isFalse);
      expect(user.isStoreKeeper, isTrue);
      expect(user.canAccessDashboard, isFalse);
    });

    test('Permissions list is parsed safely without breaking authentication behavior', () {
      // 1. Standard List of strings
      final userWithList = AdminUser.fromJson({
        'id': 20,
        'name': 'User',
        'email': 'test@test.com',
        'role': 'store_keeper',
        'permissions': ['orders.view', 'photos.upload'],
      });
      expect(userWithList.permissions, ['orders.view', 'photos.upload']);
      expect(userWithList.hasPermission('orders.view'), isTrue);
      expect(userWithList.hasPermission('non_existent'), isFalse);

      // 2. Null permissions
      final userWithNull = AdminUser.fromJson({
        'id': 21,
        'name': 'User',
        'email': 'test@test.com',
        'role': 'store_keeper',
        'permissions': null,
      });
      expect(userWithNull.permissions, isEmpty);

      // 3. String permission (legacy or single value fallback)
      final userWithString = AdminUser.fromJson({
        'id': 22,
        'name': 'User',
        'email': 'test@test.com',
        'role': 'store_keeper',
        'permissions': 'dashboard.view',
      });
      expect(userWithString.permissions, ['dashboard.view']);
    });

    test('Missing, null, empty, whitespace, and unsupported roles NEVER become super_admin', () {
      final testCases = <Map<String, dynamic>>[
        {'id': 1, 'name': 'Missing Role', 'email': 'm@t.com'},
        {'id': 2, 'name': 'Null Role', 'email': 'n@t.com', 'role': null},
        {'id': 3, 'name': 'Empty Role', 'email': 'e@t.com', 'role': ''},
        {'id': 4, 'name': 'Whitespace Role', 'email': 'w@t.com', 'role': '   '},
        {
          'id': 5,
          'name': 'Unsupported Role',
          'email': 'u@t.com',
          'role': 'delivery_driver',
        },
        {
          'id': 6,
          'name': 'Malformed Role',
          'email': 'mal@t.com',
          'role': 12345,
        },
        {
          'id': 7,
          'name': 'Almost Super Admin',
          'email': 'a@t.com',
          'role': 'superadmin',
        },
        {'id': 8, 'name': 'Admin role', 'email': 'ad@t.com', 'role': 'admin'},
      ];

      for (final json in testCases) {
        final user = AdminUser.fromJson(json);
        expect(
          user.isSuperAdmin,
          isFalse,
          reason: 'Role "${json['role']}" should not be treated as super_admin',
        );
        expect(
          user.canAccessDashboard,
          isFalse,
          reason:
              'Role "${json['role']}" must fail closed for dashboard access',
        );
      }
    });

    test(
      'toJson and fromJson preserves role, roleName, and permissions intact',
      () {
        const original = AdminUser(
          id: '99',
          uuid: 'uuid-roundtrip',
          name: 'Roundtrip User',
          email: 'roundtrip@test.com',
          phone: '+20123456789',
          status: 'active',
          gender: 'ذكر',
          role: 'super_admin',
          roleName: 'مدير عام',
          permissions: ['dashboard.view', 'audit.view'],
          avatar: 'https://example.com/avatar.png',
          createdAt: '2026-10-22T10:00:00Z',
        );

        final json = original.toJson();
        final restored = AdminUser.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.uuid, original.uuid);
        expect(restored.name, original.name);
        expect(restored.email, original.email);
        expect(restored.phone, original.phone);
        expect(restored.status, original.status);
        expect(restored.gender, original.gender);
        expect(restored.role, original.role);
        expect(restored.roleName, original.roleName);
        expect(restored.permissions, original.permissions);
        expect(restored.avatar, original.avatar);
        expect(restored.createdAt, original.createdAt);
        expect(restored.isSuperAdmin, isTrue);
      },
    );

    test('LoginResponse parses illustrative backend response accurately', () {
      final backendResponse = {
        'status': true,
        'message': 'Login successful',
        'data': {
          'admin': {
            'id': 5,
            'uuid': 'example-uuid',
            'name': 'Example Admin',
            'email': 'example@example.com',
            'phone': '+200000000000',
            'status': 'active',
            'gender': 'ذكر',
            'role': 'store_keeper',
            'role_name': 'امين المخزن',
            'permissions': ['dashboard.view'],
            'avatar': 'https://example.com/avatar.png',
            'created_at': '2026-05-16T15:00:33+00:00',
          },
          'token': 'TEST_TOKEN_XYZ',
        },
        'errors': null,
      };

      final loginResponse = LoginResponse.fromJson(backendResponse);

      expect(loginResponse.status, isTrue);
      expect(loginResponse.message, 'Login successful');
      expect(loginResponse.token, 'TEST_TOKEN_XYZ');
      expect(loginResponse.admin, isNotNull);

      final admin = loginResponse.admin!;
      expect(admin.id, '5');
      expect(admin.role, 'store_keeper');
      expect(admin.roleName, 'امين المخزن');
      expect(admin.userRole, UserRole.storeKeeper);
      expect(admin.permissions, ['dashboard.view']);
      // Even with dashboard.view permission, store_keeper must NOT access dashboard!
      expect(admin.canAccessDashboard, isFalse);
    });
  });
}
