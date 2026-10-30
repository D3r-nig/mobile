import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itlabcare/screens/profile_detail_screen.dart';

void main() {
  testWidgets('updates password using the submitted current and new values', (
    tester,
  ) async {
    String? currentPassword;
    String? newPassword;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileDetailScreen(
          mode: ProfileDetailMode.password,
          updatePassword: (current, next) async {
            currentPassword = current;
            newPassword = next;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'CurrentPass1!');
    await tester.enterText(find.byType(TextField).at(1), 'NewPassword2!');
    await tester.enterText(find.byType(TextField).at(2), 'NewPassword2!');
    await tester.ensureVisible(find.text('Update Password').last);
    await tester.tap(find.text('Update Password').last);
    await tester.pumpAndSettle();

    expect(currentPassword, 'CurrentPass1!');
    expect(newPassword, 'NewPassword2!');
    expect(find.text('Password Updated'), findsOneWidget);
  });

  testWidgets('explains when Firebase requires a recent sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileDetailScreen(
          mode: ProfileDetailMode.password,
          updatePassword: (_, _) async {
            throw FirebaseAuthException(code: 'requires-recent-login');
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'CurrentPass1!');
    await tester.enterText(find.byType(TextField).at(1), 'NewPassword2!');
    await tester.enterText(find.byType(TextField).at(2), 'NewPassword2!');
    await tester.ensureVisible(find.text('Update Password').last);
    await tester.tap(find.text('Update Password').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'For your security, sign in again before changing your password.',
      ),
      findsOneWidget,
    );
  });
}
