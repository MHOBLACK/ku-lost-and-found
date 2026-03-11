import 'package:flutter/material.dart';

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
    );
  }
}
