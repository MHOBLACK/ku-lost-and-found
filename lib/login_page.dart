import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        GoogleProvider(clientId: '519948196017-bdn63ejvnhufmmguv9km3p0hnepol5hr.apps.googleusercontent.com'),
      ],
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

            try {
              final docSnapshot = await userDoc.get();
              final String loginMethod = user.providerData.isNotEmpty
                  ? user.providerData.map((e) => e.providerId).join(', ')
                  : 'unknown';

              if (!docSnapshot.exists) {
                // Create new user document
                await userDoc.set({
                  'uid': user.uid,
                  'email': user.email,
                  'displayName': user.displayName,
                  // 'photoURL': user.photoURL,
                  'points': 0,
                  'level': 1,
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
                  // 'photoURL': user.photoURL,
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
    );
  }
}
