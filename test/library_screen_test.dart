// Widget tests for the library screen against the in-memory fake storage.
// Covers the empty state, the populated grid, and search narrowing.

import 'package:docscan/features/library/library_screen.dart';
import 'package:docscan/models/document.dart';
import 'package:docscan/services/billing_service.dart';
import 'package:docscan/state/billing_controller.dart';
import 'package:docscan/state/library_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_storage_service.dart';

Document seedDoc(String id, String name) {
  final now = DateTime.now();
  return Document(id: id, name: name, createdAt: now, updatedAt: now);
}

Widget appWith(FakeStorageService storage) {
  return ProviderScope(
    overrides: [
      storageServiceProvider.overrideWith((ref) => storage),
      billingServiceProvider.overrideWith((ref) => FreeBillingService()),
    ],
    child: const MaterialApp(home: LibraryScreen()),
  );
}

void main() {
  testWidgets('shows the empty state when there are no documents',
      (tester) async {
    await tester.pumpWidget(appWith(FakeStorageService()));
    await tester.pumpAndSettle();

    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('shows a tile for each saved document', (tester) async {
    final storage = FakeStorageService(seed: [
      seedDoc('1', 'Tax form'),
      seedDoc('2', 'Lease agreement'),
    ]);
    await tester.pumpWidget(appWith(storage));
    await tester.pumpAndSettle();

    expect(find.text('Tax form'), findsOneWidget);
    expect(find.text('Lease agreement'), findsOneWidget);
    expect(find.text('No documents yet'), findsNothing);
  });

  testWidgets('typing in search narrows the grid', (tester) async {
    final storage = FakeStorageService(seed: [
      seedDoc('1', 'Tax form'),
      seedDoc('2', 'Lease agreement'),
    ]);
    await tester.pumpWidget(appWith(storage));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'lease');
    await tester.pumpAndSettle();

    expect(find.text('Lease agreement'), findsOneWidget);
    expect(find.text('Tax form'), findsNothing);
  });

  testWidgets('the All folder chip is always there', (tester) async {
    await tester.pumpWidget(appWith(FakeStorageService()));
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('New folder'), findsOneWidget);
  });
}
