import 'package:flutter/material.dart';

// for coding accounts

class UserAccount extends ChangeNotifier {
  final String _username;
  final String _email;
  final String _profilePicUrl;

  UserAccount({required String username, required String email, required String profilePicUrl})
      : _username = username,
        _email = email,
        _profilePicUrl = profilePicUrl;

  String get username => _username;
  String get email => _email;
  String get profilePicUrl => _profilePicUrl;

}
