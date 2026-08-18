import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bherung/models/branch.dart';
import 'package:bherung/models/user_role.dart';
import 'package:bherung/services/inventory_storage_service.dart';
import 'package:bherung/screens/settings_screen.dart';
import 'package:bherung/screens/pin_login_lock_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Branch Model Tests', () {
    test('Branch serialization and deserialization', () {
      const branch = Branch(
        id: 'br-01',
        name: 'Cabang Kalimalang',
        code: 'CB01',
        address: 'Jl. Kalimalang No. 12',
        phone: '08123456789',
        isMain: true,
        isActive: true,
      );

      final json = branch.toJson();
      expect(json['id'], 'br-01');
      expect(json['name'], 'Cabang Kalimalang');
      expect(json['code'], 'CB01');
      expect(json['isMain'], true);

      final fromJson = Branch.fromJson(json);
      expect(fromJson.id, 'br-01');
      expect(fromJson.name, 'Cabang Kalimalang');
      expect(fromJson.code, 'CB01');
      expect(fromJson.isMain, true);
      expect(fromJson.isActive, true);
    });

    test('defaultMainBranch helper returns proper defaults', () {
      final mainBranch = Branch.defaultMainBranch(storeName: 'Bherung Madura');
      expect(mainBranch.isMain, true);
      expect(mainBranch.isActive, true);
      expect(mainBranch.name, 'Bherung Madura (Pusat)');
      expect(mainBranch.code, 'CB01');
    });
  });

  group('Multi-Branch Storage Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Multi-branch enabled flag defaults to false', () async {
      final storage = InventoryStorageService();
      final enabled = await storage.loadMultiBranchEnabled();
      expect(enabled, false);

      await storage.saveMultiBranchEnabled(true);
      final enabledAfter = await storage.loadMultiBranchEnabled();
      expect(enabledAfter, true);
    });

    test('Branches save and load with default fallback', () async {
      final storage = InventoryStorageService();
      final defaultBranches = await storage.loadBranches(storeName: 'Toko Bherung');
      expect(defaultBranches.isNotEmpty, true);
      expect(defaultBranches.first.isMain, true);

      final customBranches = [
        const Branch(id: 'br-pusat', name: 'Toko Pusat', code: 'CB01', isMain: true),
        const Branch(id: 'br-cabang2', name: 'Cabang 2', code: 'CB02', isMain: false),
      ];

      await storage.saveBranches(customBranches);
      final loaded = await storage.loadBranches();
      expect(loaded.length, 2);
      expect(loaded[0].id, 'br-pusat');
      expect(loaded[1].id, 'br-cabang2');

      await storage.saveActiveBranchId('br-cabang2');
      final active = await storage.getActiveBranch();
      expect(active.id, 'br-cabang2');
      expect(active.name, 'Cabang 2');
    });
  });

  group('Settings Screen Role Visibility Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Multi Cabang tab is VISIBLE for Owner', (WidgetTester tester) async {
      const ownerUser = AppUser(
        id: 'usr-owner',
        name: 'Pemilik Toko',
        phone: '0812',
        role: UserRoleType.owner,
        pin: '1234',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            products: const [],
            currentUser: ownerUser,
            onDataChanged: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 4 tabs exist and 'Multi Cabang' is present
      expect(find.text('Google Sheets'), findsOneWidget);
      expect(find.text('Profil Toko & Jaga'), findsOneWidget);
      expect(find.text('QRIS & Rekening'), findsOneWidget);
      expect(find.text('Multi Cabang'), findsOneWidget);
    });

    testWidgets('Multi Cabang tab is HIDDEN completely for Non-Owner (Staff/Kasir)', (WidgetTester tester) async {
      const staffUser = AppUser(
        id: 'usr-staff',
        name: 'Ahmad Kasir',
        phone: '0857',
        role: UserRoleType.staff,
        pin: '1111',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            products: const [],
            currentUser: staffUser,
            onDataChanged: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify only 3 tabs exist and 'Multi Cabang' is completely hidden/absent
      expect(find.text('Google Sheets'), findsOneWidget);
      expect(find.text('Profil Toko & Jaga'), findsOneWidget);
      expect(find.text('QRIS & Rekening'), findsOneWidget);
      expect(find.text('Multi Cabang'), findsNothing);
    });
  });

  group('1 Cabang 1 Penjaga Security & Access Control Tests', () {
    test('AppUser branch serialization and deserialization', () {
      const user = AppUser(
        id: 'usr-02',
        name: 'Ahmad',
        phone: '08123',
        role: UserRoleType.staff,
        pin: '4321',
        branchId: 'br-02',
        branchName: 'Cabang Kalimalang',
      );

      final json = user.toJson();
      expect(json['branchId'], 'br-02');
      expect(json['branchName'], 'Cabang Kalimalang');

      final fromJson = AppUser.fromJson(json);
      expect(fromJson.branchId, 'br-02');
      expect(fromJson.branchName, 'Cabang Kalimalang');
    });

    testWidgets('Staff assigned to Branch 1 CANNOT login on Branch 2', (WidgetTester tester) async {
      final users = [
        const AppUser(
          id: 'usr-pusat',
          name: 'Hasan Pusat',
          phone: '',
          role: UserRoleType.staff,
          pin: '1111',
          branchId: 'br-pusat',
          branchName: 'Cabang Pusat',
        ),
        const AppUser(
          id: 'usr-kalimalang',
          name: 'Siti Kalimalang',
          phone: '',
          role: UserRoleType.staff,
          pin: '2222',
          branchId: 'br-kalimalang',
          branchName: 'Cabang Kalimalang',
        ),
      ];

      AppUser? authenticatedUser;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinLoginLockScreen(
              users: users,
              isMultiBranchEnabled: true,
              activeBranchId: 'br-kalimalang',
              activeBranchName: 'Cabang Kalimalang',
              onAuthenticated: (u) => authenticatedUser = u,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Hasan's PIN (1111) who belongs to Cabang Pusat, not Kalimalang
      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Authentication MUST be denied
      expect(authenticatedUser, isNull);
      expect(find.textContaining('Akses Ditolak'), findsOneWidget);

      // Now enter Siti's PIN (2222) who is assigned to Cabang Kalimalang
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Authentication MUST succeed for Siti
      expect(authenticatedUser, isNotNull);
      expect(authenticatedUser!.name, 'Siti Kalimalang');
    });

    testWidgets('Owner CAN login on any branch', (WidgetTester tester) async {
      final users = [
        const AppUser(
          id: 'usr-owner',
          name: 'Bos Toko',
          phone: '',
          role: UserRoleType.owner,
          pin: '9999',
        ),
      ];

      AppUser? authenticatedUser;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinLoginLockScreen(
              users: users,
              isMultiBranchEnabled: true,
              activeBranchId: 'br-kalimalang',
              activeBranchName: 'Cabang Kalimalang',
              onAuthenticated: (u) => authenticatedUser = u,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Owner PIN (9999)
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();

      // Authentication MUST succeed for Owner
      expect(authenticatedUser, isNotNull);
      expect(authenticatedUser!.isOwner, true);
    });
  });

  group('Navigation & Back Stack Integrity Tests', () {
    testWidgets('SettingsScreen back button pops back to caller without blank screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          products: const [],
                          currentUser: const AppUser(
                            id: 'usr-1',
                            name: 'Owner',
                            phone: '',
                            role: UserRoleType.owner,
                            pin: '1234',
                          ),
                          onDataChanged: () {},
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap Open Settings
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Google Sheets'), findsOneWidget);

      // Tap Back button on SettingsScreen AppBar
      final backButton = find.byTooltip('Kembali ke Kasir');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Ensure root screen is active and not blank
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('Owner can open Atur Penjaga Cabang dialog and assign staff', (WidgetTester tester) async {
      final storage = InventoryStorageService();
      await storage.saveMultiBranchEnabled(true);
      await storage.saveBranches([
        const Branch(id: 'br-pusat', name: 'Cabang Pusat', code: 'CB01', isMain: true),
        const Branch(id: 'br-timur', name: 'Cabang Timur', code: 'CB02', isMain: false),
      ]);
      await storage.saveUsers([
        const AppUser(id: 'u-owner', name: 'Boss', phone: '', role: UserRoleType.owner, pin: '1234'),
        const AppUser(id: 'u-kasir', name: 'Joko', phone: '', role: UserRoleType.staff, pin: '5678'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            products: const [],
            currentUser: const AppUser(id: 'u-owner', name: 'Boss', phone: '', role: UserRoleType.owner, pin: '1234'),
            onDataChanged: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Go to Multi Cabang tab
      await tester.tap(find.text('Multi Cabang'));
      await tester.pumpAndSettle();

      // Tap 'Tugaskan Penjaga di Cabang Ini' icon button or '👤 Belum ada penjaga' chip
      expect(find.byTooltip('Tugaskan Penjaga di Cabang Ini'), findsWidgets);
      await tester.tap(find.byTooltip('Tugaskan Penjaga di Cabang Ini').first);
      await tester.pumpAndSettle();

      // Verify dialog is open with staff 'Joko'
      expect(find.text('Atur Penjaga Cabang'), findsOneWidget);
      expect(find.text('Joko'), findsOneWidget);

      // Tap Joko to assign to this branch
      await tester.tap(find.text('Joko'));
      await tester.pumpAndSettle();

      // Tap Simpan Penugasan
      await tester.tap(find.text('Simpan Penugasan'));
      await tester.pumpAndSettle();

      // Verify saved in storage
      final loadedUsers = await storage.loadUsers();
      final joko = loadedUsers.firstWhere((u) => u.name == 'Joko');
      expect(joko.branchId, 'br-pusat');
    });
  });
}
