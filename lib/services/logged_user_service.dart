import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hanguiemos_frontend/entities/logged_user.dart';
import 'package:http/http.dart' as http;

class LoggedUserService {
  static const String url = kIsWeb
      ? 'http://127.0.0.1:8080/api/usuarios'
      : 'http://10.0.2.2:8080/api/usuarios';

  Future<LoggedUser> fetchUserByToken(String token) async {
    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      dynamic json = jsonDecode(response.body);
      LoggedUser user = LoggedUser.fromJson(json);
      return user;
    } else {
      throw Exception(
          'Failed to load user with status code: ${response.statusCode}');
    }
  }
}
