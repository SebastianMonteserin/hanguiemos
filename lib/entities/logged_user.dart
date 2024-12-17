class LoggedUser {
  String id;
  String mail;
  String nombreDeUsuario;
  List<String> intereses;
  String imagenUrl;
  List<String> eventosCreados;
  List<String> eventosSuscriptos;
  String token;
  String telefono;

  LoggedUser(
      {required this.id,
      required this.nombreDeUsuario,
      required this.token,
      required this.mail,
      required this.imagenUrl,
      required this.intereses,
      required this.eventosCreados,
      required this.eventosSuscriptos,
      required this.telefono});

  factory LoggedUser.fromJson(Map<String, dynamic> json) {
    return LoggedUser(
      id: json['usuario']['_id'],
      nombreDeUsuario: json['usuario']['username'],
      token: json['token'],
      mail: json['usuario']['mail'],
      telefono: json['usuario']['telefono'] ?? '',
      imagenUrl: json['usuario']['imageUrl'] ?? '',
      intereses: List<String>.from(json['usuario']['intereses']),
      eventosCreados: (json['usuario']['eventosCreados'] != null)
          ? List<String>.from(json['usuario']['eventosCreados'])
          : [],
      eventosSuscriptos: (json['usuario']['eventosSuscriptos'] != null)
          ? List<String>.from(json['usuario']['eventosSuscriptos'])
          : [],
    );
  }
}
