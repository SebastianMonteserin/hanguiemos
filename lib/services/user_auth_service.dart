import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hanguiemos_frontend/entities/categoria.dart';
import 'package:hanguiemos_frontend/entities/logged_user.dart';
import 'package:http/http.dart' as http;

class UserAuthService {
  static const String apiUrl = kIsWeb
      ? 'http://127.0.0.1:8080/api/usuarios'
      : 'http://10.0.2.2:8080/api/usuarios';

  Future<void> registerUser(
      String email,
      String password,
      String usuario,
      List<Categoria> categorias,
      int edad,
      String? imageUrl,
      String nombre,
      String apellido,
      String telefono) async {
    final url = Uri.parse("$apiUrl/registrar");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mail': email,
        'username': usuario,
        'password': password,
        'edad': edad,
        'intereses': categorias.map((cat) => cat.toJson()).toList(),
        'imageUrl': imageUrl,
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
      }),
    );

    if (response.statusCode == 200) {
    } else {
      throw Exception('Error al registrar el usuario: ${response.statusCode}');
    }
  }

  Future<LoggedUser?> logInUser(String email, String password) async {
    final url = Uri.parse("$apiUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'mail': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LoggedUser.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error al hacer login: $e');
    }
  }
}
