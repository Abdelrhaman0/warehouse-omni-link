import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/auth/models/admin_user.dart';

void main() {
  group(
    'AuthorizationService - Dashboard & Permissions Policy (Section 13)',
    () {
      const superAdminUser = AdminUser(
        id: '1',
        name: 'Super Admin',
        email: 'admin@omni-link.net',
        role: 'super_admin',
        permissions: ['dashboard.view', 'warehouse.manage'],
      );

      const storeKeeperWithDashboardPerm = AdminUser(
        id: '2',
        name: 'Store Keeper with Perm',
        email: 'keeper@omni-link.net',
        role: 'store_keeper',
        permissions: ['dashboard.view'],
      );

      const storeKeeperNormal = AdminUser(
        id: '3',
        name: 'Normal Store Keeper',
        email: 'normal@omni-link.net',
        role: 'store_keeper',
        permissions: ['orders.read', 'photos.upload'],
      );

      const unknownRoleUser = AdminUser(
        id: '4',
        name: 'Unknown Role',
        email: 'unknown@omni-link.net',
        role: 'finance_manager',
        permissions: ['dashboard.view'],
      );

      const emptyRoleUser = AdminUser(
        id: '5',
        name: 'Empty Role',
        email: 'empty@omni-link.net',
        role: '',
      );

      const nullRoleUser = AdminUser(
        id: '6',
        name: 'Null Role',
        email: 'null@omni-link.net',
        role: null,
      );

      test('A super admin is allowed to access the dashboard', () {
        expect(AuthorizationService.canAccessDashboard(superAdminUser), isTrue);
        expect(superAdminUser.canAccessDashboard, isTrue);
        expect(AuthorizationService.isSuperAdmin(superAdminUser), isTrue);
        expect(superAdminUser.isSuperAdmin, isTrue);
      });

      test('A store keeper is denied dashboard access', () {
        expect(
          AuthorizationService.canAccessDashboard(storeKeeperNormal),
          isFalse,
        );
        expect(storeKeeperNormal.canAccessDashboard, isFalse);
        expect(AuthorizationService.isStoreKeeper(storeKeeperNormal), isTrue);
        expect(storeKeeperNormal.isStoreKeeper, isTrue);
      });

      test('A store keeper remains denied even if its permissions contain dashboard.view', () {
        // Critical authorization rule: Role controls dashboard access, not permissions array.
        expect(
          storeKeeperWithDashboardPerm.hasPermission('dashboard.view'),
          isTrue,
        );
        expect(
          AuthorizationService.canAccessDashboard(storeKeeperWithDashboardPerm),
          isFalse,
        );
        expect(storeKeeperWithDashboardPerm.canAccessDashboard, isFalse);
      });

      test('A missing, empty, or unknown role is denied dashboard access', () {
        expect(
          AuthorizationService.canAccessDashboard(unknownRoleUser),
          isFalse,
        );
        expect(AuthorizationService.canAccessDashboard(emptyRoleUser), isFalse);
        expect(AuthorizationService.canAccessDashboard(nullRoleUser), isFalse);
        expect(AuthorizationService.canAccessDashboard(null), isFalse);

        expect(unknownRoleUser.canAccessDashboard, isFalse);
        expect(emptyRoleUser.canAccessDashboard, isFalse);
        expect(nullRoleUser.canAccessDashboard, isFalse);
      });

      test('hasPermission checks permissions safely', () {
        expect(
          AuthorizationService.hasPermission(superAdminUser, 'dashboard.view'),
          isTrue,
        );
        expect(
          AuthorizationService.hasPermission(
            superAdminUser,
            'warehouse.manage',
          ),
          isTrue,
        );
        expect(
          AuthorizationService.hasPermission(superAdminUser, 'non_existent'),
          isFalse,
        );
        expect(
          AuthorizationService.hasPermission(null, 'any.permission'),
          isFalse,
        );
      });
    },
  );
}
