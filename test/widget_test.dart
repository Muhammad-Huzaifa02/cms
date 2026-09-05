import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cms/main.dart';
import 'package:cms/data/services/auth_service.dart';

void main() {
  testWidgets('CmsApp shows LoginScreen when not logged in', (WidgetTester tester) async {
    // 1. Setup mocks
    final mockAuth = MockFirebaseAuth();
    final mockDb = FakeFirebaseFirestore();
    final authService = AuthService(auth: mockAuth, db: mockDb);

    // 2. Build our app with the mocked service
    await tester.pumpWidget(CmsApp(authService: authService));

    // _AuthGate has a StreamBuilder, so we need to pump to let it emit the initial null user
    await tester.pump();

    // 3. Verify that LoginScreen components are visible.
    // Note: the login field is unified (one "Email or phone number" input,
    // no separate "Email" label — see AuthService.signIn's auto-detection),
    // and "Sign in" appears twice by design (card header + button), so we
    // target the button specifically rather than asserting findsOneWidget
    // on plain text.
    expect(find.text('Customer Management System'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    expect(find.textContaining('Email or phone number'), findsWidgets);
  });
}
