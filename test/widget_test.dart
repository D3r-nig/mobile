// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itlabcare/main.dart';
import 'package:itlabcare/widgets/auth_widgets.dart';

void main() {
  testWidgets('shows the ITLABCARE login screen', (tester) async {
    await tester.pumpWidget(const ItlabcareApp());

    expect(find.text('ITLABCARE'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('can move from login to sign up and verification', (tester) async {
    await tester.pumpWidget(const ItlabcareApp());

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Verify Your Account'), findsOneWidget);
    expect(find.text('Go to Login'), findsOneWidget);
  });

  testWidgets('opens the teacher dashboard from sign in', (tester) async {
    await tester.pumpWidget(const ItlabcareApp());

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Teacher Juan!'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Scan QR Code'), findsOneWidget);
  });

  testWidgets('bottom navigation moves between dashboard sections', (tester) async {
    await tester.pumpWidget(const ItlabcareApp());
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('My Reports'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Sir Alexander'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Teacher Juan!'), findsOneWidget);
  });

  testWidgets('opens the profile detail forms', (tester) async {
    await tester.pumpWidget(const ItlabcareApp());
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
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

  testWidgets('opens and closes the notification details screen', (tester) async {
    await tester.pumpWidget(const ItlabcareApp());
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications').at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report #1021 Updated').first);
    await tester.pumpAndSettle();

    expect(find.text('Notification Details'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Status Timeline'), findsOneWidget);
  });

  testWidgets('opens computer details after a successful scan', (tester) async {
    await tester.pumpWidget(const ItlabcareApp());
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(const ItlabcareApp());
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(const ItlabcareApp());
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
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

  testWidgets('opens preference and support screens from Profile', (tester) async {
    await tester.pumpWidget(const ItlabcareApp());
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
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
