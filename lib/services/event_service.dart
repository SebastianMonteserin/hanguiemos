import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hanguiemos_frontend/entities/categoria.dart';
import 'package:hanguiemos_frontend/entities/event.dart';
import 'package:http/http.dart' as http;

class EventService {
  static const String apiUrl = kIsWeb
      ? 'http://127.0.0.1:8080/api/eventos'
      : 'http://10.0.2.2:8080/api/eventos';

  Future<void> createEvent({
    required String name,
    required Categoria category,
    required String city,
    required DateTime day,
    required TimeOfDay time,
    required String description,
    required String token,
    String? imagenUrl,
    String? direccion,
  }) async {
    final url = Uri.parse(apiUrl);
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $token'
      },
      body: json.encode({
        'nombre': name,
        'categoria': category.toString().split('.').last,
        'ciudad': city,
        'dia': day.toIso8601String(),
        'hora': '${time.hour}:${time.minute}',
        'descripcion': description,
        'imagenUrl': imagenUrl?.isNotEmpty == true ? imagenUrl : '',
        'direccion': direccion?.isNotEmpty == true ? direccion : '',
      }),
    );
  }

  Future<void> updateEvent(
      {required String id,
      required String name,
      required Categoria category,
      required String city,
      required DateTime day,
      required TimeOfDay time,
      required String description,
      required String token,
      required String imagenUrl,
      String? direccion}) async {
    final url = Uri.parse('$apiUrl/$id');
    await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $token'
      },
      body: json.encode({
        'nombre': name,
        'categoria': category.toString().split('.').last,
        'ciudad': city,
        'dia': day.toIso8601String(),
        'hora': '${time.hour}:${time.minute}',
        'descripcion': description,
        'imagenUrl': imagenUrl,
        'direccion': direccion?.isNotEmpty == true ? direccion : '',
      }),
    );
  }

  Future<List<Evento>> fetchEvents(
      {bool showByCategories = false,
      required String token,
      Categoria? categoria}) async {
    String url = showByCategories ? apiUrl : '$apiUrl/intereses';
    if (categoria != null) {
      url += '?categoria=${categoria.name}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $token'
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((eventJson) => Evento.fromJson(eventJson)).toList();
    } else {
      throw Exception('Fallo al cargar eventos');
    }
  }

  Future<void> suscribirAEvento(String idEvento, String token) async {
    final response = await http.post(
      Uri.parse('$apiUrl/suscribir/$idEvento'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    if (response.statusCode == 200) {
    } else {
      throw Exception('Fallo al suscribir usuario');
    }
  }

  Future<void> desuscribirAEvento(String idEvento, String token) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/desuscribir/$idEvento'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    if (response.statusCode == 200) {
    } else {
      throw Exception('Fallo al desuscribir usuario');
    }
  }

  Future<Evento> obtenerEvento(String idEvento, String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/uno/$idEvento'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body);
      return Evento.fromJson(data);
    } else {
      throw Exception('Fallo al suscribir usuario');
    }
  }

  Future<List<Evento>> obtenerListaEventosPorId(
      List<String> eventIdList, String token) async {
    List<Evento> eventList = [];
    for (var id in eventIdList) {
      eventList.add(await obtenerEvento(id, token));
    }
    return eventList;
  }

  Future<void> eliminarEvento(String idEvento, String token) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/$idEvento'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    if (response.statusCode == 200) {
    } else {
      throw Exception('Fallo al eliminar evento');
    }
  }
}
