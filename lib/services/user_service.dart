import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hanguiemos_frontend/entities/categoria.dart';
import 'package:http/http.dart' as http;
import 'package:hanguiemos_frontend/entities/user.dart';

class UserService {
  static const String url = kIsWeb
      ? 'http://127.0.0.1:8080/api/usuarios'
      : 'http://10.0.2.2:8080/api/usuarios';

  Future<Usuario> fetchUserByID(String userId, String token) async {
    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };

    final response =
        await http.get(Uri.parse('$url/$userId'), headers: headers);

    if (response.statusCode == 200) {
      dynamic json = jsonDecode(response.body);
      Usuario user = Usuario.fromJson(json);
      return user;
    } else {
      throw Exception(
          'Failed to load user with status code: ${response.statusCode}');
    }
  }

  Future<List<Usuario>> fetchUsersByIDList(
      List<String> userIdList, String token) async {
    List<Usuario> userList = [];
    for (var id in userIdList) {
      userList.add(await fetchUserByID(id, token));
    }
    return userList;
  }

  Future<void> updateUser(String nombreDeUsuario, List<Categoria> categorias,
      String? imageUrl, String token) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $token'
        },
        body: jsonEncode({
          'username': nombreDeUsuario,
          'intereses': categorias.map((cat) => cat.toJson()).toList(),
          'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
      } else {
        throw Exception(
            'Error al actualizar el usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar el usuario: $e');
    }
  }
}
