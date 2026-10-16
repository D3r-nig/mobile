// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itlabcare/main.dart';
import 'package:itlabcare/widgets/auth_widgets.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ItlabcareApp(
      signIn: (email, password) async {},
      passwordReset: (email) async {},
    ),
  );
  await tester.pump(const Duration(milliseconds: 2700));
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
  await tester.enterText(find.byType(TextField).at(1), 'password123');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the ITLABCARE login screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('ITLABCARE'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsNothing);
    expect(find.text('Sign Up'), findsNothing);
  });

  testWidgets('can request a password reset email', (tester) async {
    String? requestedEmail;
    await tester.pumpWidget(
      ItlabcareApp(
        signIn: (email, password) async {},
        emailLookup: (email) async => true,
        passwordReset: (email) async {
          requestedEmail = email;
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'student@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Your Password'), findsOneWidget);

    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(requestedEmail, 'student@example.com');
    expect(find.text('Password Reset Email Sent'), findsOneWidget);
    expect(
      find.text(
        'Password reset instructions have been sent successfully. Please check your email.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not send reset when the API URL is not configured', (
    tester,
  ) async {
    var resetRequested = false;
    await tester.pumpWidget(
      ItlabcareApp(
        signIn: (email, password) async {},
        passwordReset: (email) async {
          resetRequested = true;
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'student@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(resetRequested, isFalse);
    expect(
      find.text(
        'Mobile API URL is not configured. Please rebuild the app with the Laravel API URL.',
      ),
      findsOneWidget,
    );
    expect(find.text('Password Reset Email Sent'), findsNothing);
  });

  testWidgets('reset request rejects an unregistered email', (tester) async {
    var resetRequested = false;
    await tester.pumpWidget(
      ItlabcareApp(
        signIn: (email, password) async {},
        emailLookup: (email) async => false,
        passwordReset: (email) async {
          resetRequested = true;
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'unknown@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This email address is not registered in our database. Please enter a valid email address.',
      ),
      findsOneWidget,
    );
    expect(find.text('Password Reset Email Sent'), findsNothing);
    expect(resetRequested, isFalse);
  });

  testWidgets('does not show success if sending the reset email fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ItlabcareApp(
        signIn: (email, password) async {},
        emailLookup: (email) async => true,
        passwordReset: (email) async {
          throw FirebaseAuthException(code: 'too-many-requests');
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'student@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(
      find.text('Too many requests. Please wait a while and try again.'),
      findsOneWidget,
    );
    expect(find.text('Password Reset Email Sent'), findsNothing);
  });

  testWidgets(
    'reset request uses the edited email after an unregistered lookup',
    (tester) async {
      final resetEmails = <String>[];
      await tester.pumpWidget(
        ItlabcareApp(
          signIn: (email, password) async {},
          emailLookup: (email) async => email == 'another@example.com',
          passwordReset: (email) async => resetEmails.add(email),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(0),
        'unknown@example.com',
      );
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This email address is not registered in our database. Please enter a valid email address.',
        ),
        findsOneWidget,
      );
      expect(resetEmails, isEmpty);

      await tester.enterText(
        find.byType(TextField).at(0),
        'another@example.com',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('not registered'), findsNothing);
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(resetEmails, ['another@example.com']);
      expect(find.text('Password Reset Email Sent'), findsOneWidget);
    },
  );

  testWidgets(
    'reset request retries after lookup failure without reopening the form',
    (tester) async {
      var lookupAttempts = 0;
      await tester.pumpWidget(
        ItlabcareApp(
          signIn: (email, password) async {},
          emailLookup: (email) async {
            if (lookupAttempts++ == 0) {
              throw StateError('Simulated network failure');
            }
            return true;
          },
          passwordReset: (email) async {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(0),
        'student@example.com',
      );
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not verify your email address. Please try again.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextField).at(0),
        'another@example.com',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Could not verify your email address. Please try again.'),
        findsNothing,
      );
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(lookupAttempts, 2);
      expect(find.text('Password Reset Email Sent'), findsOneWidget);
    },
  );

  testWidgets('reset request ignores an outdated lookup after email edit', (
    tester,
  ) async {
    final staleLookup = Completer<bool>();
    var lookupAttempts = 0;
    await tester.pumpWidget(
      ItlabcareApp(
        signIn: (email, password) async {},
        emailLookup: (email) {
          lookupAttempts++;
          return email == 'first@example.com'
              ? staleLookup.future
              : Future.value(true);
        },
        passwordReset: (email) async {},
      ),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    final emailField = find.byType(TextField).at(0);
    await tester.enterText(emailField, 'first@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();

    await tester.enterText(emailField, 'second@example.com');
    staleLookup.complete(false);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This email address is not registered in our database. Please enter a valid email address.',
      ),
      findsNothing,
    );
    expect(find.text('Sending...'), findsNothing);

    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(lookupAttempts, 2);
    expect(find.text('Password Reset Email Sent'), findsOneWidget);
  });

  testWidgets('handles consecutive successful reset email requests', (
    tester,
  ) async {
    const registeredEmails = {'first@example.com', 'second@example.com'};
    final requestedEmails = <String>[];
    await tester.pumpWidget(
      ItlabcareApp(
        signIn: (email, password) async {},
        emailLookup: (email) async => registeredEmails.contains(email),
        passwordReset: (email) async => requestedEmails.add(email),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'first@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.text('Password Reset Email Sent'), findsOneWidget);

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'second@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.text('Password Reset Email Sent'), findsOneWidget);

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(requestedEmails, [
      'first@example.com',
      'second@example.com',
      'second@example.com',
    ]);
    expect(find.text('Password Reset Email Sent'), findsOneWidget);
  });

  testWidgets('reset request rejects an unregistered email after success', (
    tester,
  ) async {
    await tester.pumpWidget(
      ItlabcareApp(
        signIn: (email, password) async {},
        emailLookup: (email) async => email == 'student@example.com',
        passwordReset: (email) async {},
      ),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'student@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'unknown@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This email address is not registered in our database. Please enter a valid email address.',
      ),
      findsOneWidget,
    );
    expect(find.text('Password Reset Email Sent'), findsNothing);
  });

  testWidgets('reset validation allows a valid email after invalid format', (
    tester,
  ) async {
    await tester.pumpWidget(
      ItlabcareApp(
        signIn: (email, password) async {},
        emailLookup: (email) async => true,
        passwordReset: (email) async {},
      ),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'invalid');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a valid email address.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'student@example.com');
    await tester.pumpAndSettle();
    expect(find.text('Please enter a valid email address.'), findsNothing);
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.text('Password Reset Email Sent'), findsOneWidget);
  });

  testWidgets('requires a valid email before requesting a reset', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    expect(find.text('Password Reset Email Sent'), findsNothing);
  });

  testWidgets('requires email and password before sign in', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email and password.'), findsOneWidget);
  });

  testWidgets('opens the student dashboard from sign in', (tester) async {
    await pumpApp(tester);

    await signIn(tester);

    expect(find.text('Hello, Student Xander!'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Scan QR Code'), findsOneWidget);
    expect(find.text('Start with a scan'), findsOneWidget);
    expect(find.text('Activity overview'), findsOneWidget);
  });

  testWidgets('bottom navigation moves between dashboard sections', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester);

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('My Reports'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Alexander John'), findsOneWidget);
    expect(find.text('Student account'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Student Xander!'), findsOneWidget);
  });

  testWidgets('opens the profile detail forms', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();
    expect(find.text('Alexander John Aspiras'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();
    expect(find.text('Password Requirements'), findsOneWidget);
    expect(find.text('Update Password'), findsNWidgets(2));
  });

  testWidgets('opens and closes the notification details screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Notifications').at(1));
    await tester.pumpAndSettle();

    expect(find.text('3 unread'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    await tester.tap(find.text('Report #1021 Updated').first);
    await tester.pumpAndSettle();

    expect(find.text('Notification Details'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Status Timeline'), findsOneWidget);
  });

  testWidgets('opens computer details after a successful scan', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.qr_code_2).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Computer Details'), findsOneWidget);
    expect(find.text('Report a Problem'), findsOneWidget);
  });

  testWidgets('filters reports by category tab', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Reports overview'), findsOneWidget);
    expect(find.text('3 total'), findsOneWidget);
    expect(find.text('#1021'), findsOneWidget);
    expect(find.text('#1067'), findsOneWidget);
    expect(find.text('#1251'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report-tab-Pending')));
    await tester.pumpAndSettle();
    expect(find.text('#1021'), findsOneWidget);
    expect(find.text('#1067'), findsNothing);
    expect(find.text('#1251'), findsNothing);
  });

  testWidgets('opens and submits a computer problem report', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Lab Computers'));
    await tester.pumpAndSettle();
    expect(find.text('Computer List'), findsOneWidget);

    await tester.tap(find.text('PC - 001'));
    await tester.pumpAndSettle();
    expect(find.text('Computer Details'), findsOneWidget);

    await tester.tap(find.text('Report a Problem'));
    await tester.pumpAndSettle();
    expect(find.text('Describe the Problem'), findsOneWidget);

    await tester.tap(find.byType(ActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Report Submitted!'), findsOneWidget);
  });

  testWidgets('opens preference and support screens from Profile', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('App Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('REPORT UPDATES'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(5));
    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help & Support Desk'));
    await tester.pumpAndSettle();
    expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About ITLabCare'));
    await tester.pumpAndSettle();
    expect(find.text('VERSION V1.0.0'), findsOneWidget);
  });
}
