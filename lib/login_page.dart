import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseUIActions listens to auth state changes even with custom UIs
    return FirebaseUIActions(
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final userDoc = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid);

            try {
              final docSnapshot = await userDoc.get();
              final String loginMethod =
                  user.providerData.isNotEmpty
                      ? user.providerData.map((e) => e.providerId).join(', ')
                      : 'unknown';

              if (!docSnapshot.exists) {
                // Create new user document
                await userDoc.set({
                  'uid': user.uid,
                  'email': user.email,
                  'displayName': user.displayName,
                  'points': 0,
                  'role': 'user',
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastLogin': FieldValue.serverTimestamp(),
                  'loginMethod': loginMethod,
                });
              } else {
                // Update existing user document
                await userDoc.update({
                  'email': user.email,
                  'displayName': user.displayName,
                  'lastLogin': FieldValue.serverTimestamp(),
                  'loginMethod': loginMethod,
                });
              }
            } catch (e) {
              debugPrint('Error updating user data: $e');
            }
          }
        }),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Logo.png', 
                  height: 180,
                ),
                const SizedBox(height: 24),

                const Text(
                  'ระบบแจ้ง ค้นหา ของหาย\nมหาวิทยาลัยเกษตรศาสตร์',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(
                      0xFF006666,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OAuthProviderButton(
                    provider: GoogleProvider(
                      clientId:
                          '519948196017-bdn63ejvnhufmmguv9km3p0hnepol5hr.apps.googleusercontent.com',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
