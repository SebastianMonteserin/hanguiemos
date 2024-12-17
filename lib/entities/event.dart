import 'package:flutter/material.dart';
import 'package:hanguiemos_frontend/entities/categoria.dart';

class Evento {
  String id;
  String idUsuarioCreador;
  List<String> suscriptoresIds;
  String nombre;
  Categoria categoria;
  String descripcion;
  String ciudad;
  DateTime dia;
  TimeOfDay hora;
  double? duracion;
  String? direccion;
  String imagenUrl;

  Evento(
      {required this.id,
      required this.idUsuarioCreador,
      required this.suscriptoresIds,
      required this.nombre,
      required this.categoria,
      required this.descripcion,
      required this.ciudad,
      required this.dia,
      required this.hora,
      required this.imagenUrl,
      this.duracion,
      this.direccion});

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
        id: json['_id'],
        categoria: Categoria.values
            .firstWhere((e) => e.toString().split('.')[1] == json['categoria']),
        nombre: json['nombre'],
        ciudad: json['ciudad'],
        imagenUrl: json['imagenUrl'] ?? '',
        dia: DateTime.parse(json['dia']),
        hora: _parseTime(json['hora']),
        descripcion: json['descripcion'],
        idUsuarioCreador: json['idUsuarioCreador'],
        direccion: json['direccion'] ?? '',
        suscriptoresIds: List<String>.from(json['suscriptores']));
  }

  Evento copyWith({
    String? id,
    String? idUsuarioCreador,
    List<String>? suscriptoresIds,
    String? nombre,
    Categoria? categoria,
    String? descripcion,
    String? ciudad,
    DateTime? dia,
    TimeOfDay? hora,
    double? duracion,
    String? direccion,
    String? imagenUrl,
  }) {
    return Evento(
      id: id ?? this.id,
      idUsuarioCreador: idUsuarioCreador ?? this.idUsuarioCreador,
      suscriptoresIds: suscriptoresIds ?? this.suscriptoresIds,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      ciudad: ciudad ?? this.ciudad,
      dia: dia ?? this.dia,
      hora: hora ?? this.hora,
      duracion: duracion ?? this.duracion,
      direccion: direccion ?? this.direccion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
