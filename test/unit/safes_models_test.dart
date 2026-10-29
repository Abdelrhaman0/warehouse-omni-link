import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe_summary.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe_transaction.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe_responses.dart';

void main() {
  group('Safe Model Parsing Tests', () {
    test('parses complete Safe JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'الخزنة الرئيسية',
        'name_translations': {'ar': 'الخزنة الرئيسية', 'en': 'Main Safe'},
        'type': 'cash',
        'type_label': 'خزنة نقدية',
        'account_number': null,
        'balance': 15000.50,
        'currency': 'EGP',
        'is_active': true,
        'notes': 'خزنة الفرع الرئيسي',
        'creator': {
          'id': 4,
          'name': 'أحمد إبراهيم',
          'email': 'ahmed@omnilink.com',
        },
        'can_be_deleted': false,
        'created_at': '2026-10-01 10:00:00',
        'updated_at': '2026-10-24 12:00:00',
      };

      final safe = Safe.fromJson(json);

      expect(safe.id, 1);
      expect(safe.name, 'الخزنة الرئيسية');
      expect(safe.nameAr, 'الخزنة الرئيسية');
      expect(safe.nameEn, 'Main Safe');
      expect(safe.type, 'cash');
      expect(safe.typeLabel, 'خزنة نقدية');
      expect(safe.balance, 15000.50);
      expect(safe.currency, 'EGP');
      expect(safe.isExpectedCurrency, true);
      expect(safe.isActive, true);
      expect(safe.canBeDeleted, false);
      expect(safe.creator?.name, 'أحمد إبراهيم');
    });

    test('handles string balances and integer booleans defensively', () {
      final json = {
        'id': '2',
        'name': 'حساب بنك مصر',
        'type': 'bank',
        'balance': '45000',
        'currency': 'egp',
        'is_active': 1,
        'can_be_deleted': 0,
      };

      final safe = Safe.fromJson(json);

      expect(safe.id, 2);
      expect(safe.balance, 45000.0);
      expect(safe.isExpectedCurrency, true);
      expect(safe.isActive, true);
      expect(safe.canBeDeleted, false);
    });

    test('detects currency mismatch', () {
      final json = {
        'id': 3,
        'name': 'خزنة دولارية',
        'type': 'cash',
        'balance': 2500.0,
        'currency': 'USD',
        'is_active': true,
        'can_be_deleted': true,
      };

      final safe = Safe.fromJson(json);
      expect(safe.isExpectedCurrency, false);
    });
  });

  group('SafeSummary Parsing Tests', () {
    test('parses SafeSummary JSON accurately', () {
      final json = {
        'total_safes': 5,
        'active_safes': 4,
        'total_balance': 125400.75,
      };

      final summary = SafeSummary.fromJson(json);

      expect(summary.totalSafes, 5);
      expect(summary.activeSafes, 4);
      expect(summary.totalBalance, 125400.75);
    });

    test('handles nulls and string formats in summary gracefully', () {
      final json = {
        'total_safes': '3',
        'active_safes': 2,
        'total_balance': '50000',
      };

      final summary = SafeSummary.fromJson(json);

      expect(summary.totalSafes, 3);
      expect(summary.activeSafes, 2);
      expect(summary.totalBalance, 50000.0);
    });
  });

  group('SafeTransaction Parsing Tests', () {
    test('parses income deposit transaction', () {
      final json = {
        'id': 101,
        'safe_id': 1,
        'type': 'deposit',
        'type_label': 'إيداع نقدي',
        'is_income': true,
        'amount': 5000.0,
        'fee': 0.0,
        'net_amount': 5000.0,
        'balance_before': 10000.0,
        'balance_after': 15000.0,
        'reference_number': 'DEP-9871',
        'notes': 'إيداع مبيعات اليوم',
        'performer': {
          'id': 2,
          'name': 'محمود كمال',
          'email': 'mahmoud@omnilink.com',
        },
        'created_at': '2026-10-24 11:30:00',
      };

      final tx = SafeTransaction.fromJson(json);

      expect(tx.id, 101);
      expect(tx.safeId, 1);
      expect(tx.type, 'deposit');
      expect(tx.isIncome, true);
      expect(tx.amount, 5000.0);
      expect(tx.balanceBefore, 10000.0);
      expect(tx.balanceAfter, 15000.0);
      expect(tx.referenceNumber, 'DEP-9871');
      expect(tx.performer?.name, 'محمود كمال');
    });

    test('parses expense withdrawal transaction with fee', () {
      final json = {
        'id': 102,
        'safe_id': 1,
        'type': 'withdraw',
        'type_label': 'سحب نقدي',
        'is_income': false,
        'amount': 2000.0,
        'fee': 15.0,
        'net_amount': 2015.0,
        'balance_before': 15000.0,
        'balance_after': 12985.0,
        'reference_number': 'WTH-4412',
        'notes': 'مصاريف تشغيلية',
      };

      final tx = SafeTransaction.fromJson(json);

      expect(tx.id, 102);
      expect(tx.isIncome, false);
      expect(tx.amount, 2000.0);
      expect(tx.fee, 15.0);
      expect(tx.netAmount, 2015.0);
      expect(tx.balanceAfter, 12985.0);
    });
  });

  group('Safe Responses Parsing Tests', () {
    test('parses SafeListResponse with wrapper data and summary', () {
      final json = {
        'status': true,
        'message': 'تم جلب الخزن بنجاح',
        'data': {
          'safes': [
            {
              'id': 1,
              'name': 'الخزنة 1',
              'type': 'cash',
              'balance': 5000.0,
              'currency': 'EGP',
              'is_active': true,
              'can_be_deleted': false,
            },
          ],
          'summary': {
            'total_safes': 1,
            'active_safes': 1,
            'total_balance': 5000.0,
          },
        },
      };

      final res = SafeListResponse.fromJson(json);

      expect(res.status, true);
      expect(res.safes.length, 1);
      expect(res.safes.first.name, 'الخزنة 1');
      expect(res.summary?.totalBalance, 5000.0);
    });

    test('parses SafeDetailsResponse with paginated transactions', () {
      final json = {
        'status': true,
        'message': 'تم جلب التفاصيل',
        'data': {
          'id': 1,
          'name': 'الخزنة الرئيسية',
          'type': 'cash',
          'balance': 15000.0,
          'currency': 'EGP',
          'is_active': true,
          'can_be_deleted': false,
          'transactions': {
            'data': [
              {
                'id': 201,
                'safe_id': 1,
                'type': 'deposit',
                'is_income': true,
                'amount': 3000.0,
                'fee': 0.0,
                'net_amount': 3000.0,
                'balance_before': 12000.0,
                'balance_after': 15000.0,
              },
            ],
            'meta': {
              'current_page': 1,
              'last_page': 2,
              'per_page': 15,
              'total': 25,
            },
            'links': {
              'next': 'https://api.omnilink.com/safes/1?page=2',
            },
          },
        },
      };

      final res = SafeDetailsResponse.fromJson(json);

      expect(res.status, true);
      expect(res.safe?.name, 'الخزنة الرئيسية');
      expect(res.transactions.length, 1);
      expect(res.pagination?.currentPage, 1);
      expect(res.pagination?.lastPage, 2);
      expect(res.pagination?.hasMorePages, true);
    });

    test('parses TransferResponse correctly', () {
      final json = {
        'status': true,
        'message': 'تم التحويل بنجاح',
        'data': {
          'id': 50,
          'transfer_number': 'TRF-00050',
          'amount': 3500.0,
          'fee': 0.0,
          'status': 'completed',
          'from_safe': {
            'id': 1,
            'name': 'الخزنة الرئيسية',
            'type': 'cash',
            'balance': 11500.0,
            'currency': 'EGP',
            'is_active': true,
            'can_be_deleted': false,
          },
          'to_safe': {
            'id': 2,
            'name': 'حساب بنك مصر',
            'type': 'bank',
            'balance': 48500.0,
            'currency': 'EGP',
            'is_active': true,
            'can_be_deleted': false,
          },
        },
      };

      final res = TransferResponse.fromJson(json);

      expect(res.status, true);
      expect(res.transferNumber, 'TRF-00050');
      expect(res.amount, 3500.0);
      expect(res.fromSafe?.id, 1);
      expect(res.toSafe?.id, 2);
    });
  });
}
