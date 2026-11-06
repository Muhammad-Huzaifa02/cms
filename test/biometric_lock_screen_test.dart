import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cms/core/widgets/biometric_lock_screen.dart';
import 'package:cms/data/services/biometric_service.dart';

class FakeBiometricService extends BiometricService {
  final BiometricResult resultToReturn;
  FakeBiometricService({this.resultToReturn = BiometricResult.cancelled});

  @override
  Future<BiometricResult> authenticate({
    String reason = 'Authenticate with fingerprint or Face ID',
    bool biometricOnly = false,
  }) async {
    return resultToReturn;
  }
}

void main() {
  testWidgets('BiometricLockScreen renders locked session state and controls', (tester) async {
    bool signOutCalled = false;
    final fakeService = FakeBiometricService(resultToReturn: BiometricResult.cancelled);

    await tester.pumpWidget(
      MaterialApp(
        home: BiometricLockScreen(
          uid: 'test_user_123',
          isTimedOut: false,
          biometricService: fakeService,
          onSignOut: () async {
            signOutCalled = true;
          },
          child: const Scaffold(body: Text('Unlocked Dashboard Content')),
        ),
      ),
    );

    // Pump to process post-frame callback
    await tester.pumpAndSettle();

    // Verify lock screen elements
    expect(find.text('CUSTOMER MANAGEMENT SYSTEM'), findsOneWidget);
    expect(find.text('Session Locked'), findsOneWidget);
    expect(find.text('Unlock with Biometrics'), findsOneWidget);
    expect(find.text('Sign in with password instead'), findsOneWidget);
    expect(find.text('Unlocked Dashboard Content'), findsNothing);

    // Tap sign out button
    await tester.tap(find.text('Sign in with password instead'));
    await tester.pump();
    expect(signOutCalled, isTrue);
  });

  testWidgets('BiometricLockScreen displays timeout message when isTimedOut is true', (tester) async {
    final fakeService = FakeBiometricService(resultToReturn: BiometricResult.cancelled);

    await tester.pumpWidget(
      MaterialApp(
        home: BiometricLockScreen(
          uid: 'test_user_123',
          isTimedOut: true,
          biometricService: fakeService,
          onSignOut: () async {},
          child: const Scaffold(body: Text('Unlocked Dashboard Content')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Session Timed Out'), findsOneWidget);
    expect(find.textContaining('inactivity'), findsOneWidget);
  });

  testWidgets('BiometricLockScreen unlocks and calls onUnlocked when authentication succeeds', (tester) async {
    bool unlockedCalled = false;
    final fakeService = FakeBiometricService(resultToReturn: BiometricResult.success);

    await tester.pumpWidget(
      MaterialApp(
        home: BiometricLockScreen(
          uid: 'test_user_123',
          isTimedOut: false,
          biometricService: fakeService,
          onUnlocked: () {
            unlockedCalled = true;
          },
          onSignOut: () async {},
          child: const Scaffold(body: Text('Unlocked Dashboard Content')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(unlockedCalled, isTrue);
    expect(find.text('Unlocked Dashboard Content'), findsOneWidget);
    expect(find.text('Session Locked'), findsNothing);
  });
}
